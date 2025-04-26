import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/model/characteristic.dart';
import 'package:vizinhos_app/services/app_theme.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/vendor/vendor_create_product_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_edit_product_page.dart';

class CharacteristicsHelper {
  static final Map<String, String> _characteristicsMap = {};
  static bool _isLoaded = false;

  static Future<void> loadCharacteristics(AuthProvider auth) async {
    if (_isLoaded) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetCharacteristics'),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['caracteristicas'] != null) {
          final chars = (data['caracteristicas'] as List)
              .map((json) => Characteristic.fromJson(json))
              .toList();

          _characteristicsMap.clear();
          for (var char in chars) {
            // Garante que a chave é String e remove espaços/aspas extras
            final key = char.id.toString().trim().replaceAll('"', '');
            _characteristicsMap[key] = char.descricao;
          }
          _isLoaded = true;
          debugPrint('Mapa de características carregado: $_characteristicsMap');
        } else {
          debugPrint('Nenhuma característica encontrada na resposta');
        }
      } else {
        debugPrint('Erro ao carregar características: ${response.statusCode}');
        debugPrint('Resposta: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao carregar características: $e');
    }
  }

  static String getCharacteristicName(String id) {
    // Normaliza o ID para busca
    final normalizedId = id.toString().trim().replaceAll('"', '');
    debugPrint(
        'Buscando característica com ID: "$normalizedId" no mapa: $_characteristicsMap');
    return _characteristicsMap[normalizedId] ?? 'Característica $normalizedId';
  }

  static String mapCharacteristics(List<String> ids) {
    if (ids.isEmpty) return 'Sem características';
    debugPrint('Mapeando IDs: $ids');
    final result = ids.map((id) => getCharacteristicName(id)).join(', ');
    debugPrint('Resultado do mapeamento: $result');
    return result;
  }
}

class VendorProductsPage extends StatefulWidget {
  @override
  _VendorProductsPageState createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage> {
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await CharacteristicsHelper.loadCharacteristics(auth);

      final enderecoId = auth.idEndereco;
      final token = auth.accessToken;

      if (enderecoId == null) {
        throw Exception('Endereço não configurado');
      }

      final uri = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/'
        'GetProductsByStore?fk_id_Endereco=$enderecoId',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final lista = body['produtos'] as List<dynamic>;
        final loaded = lista
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            products = loaded;
            isLoading = false;
          });
        }
      } else {
        debugPrint('Erro ao carregar produtos: ${response.statusCode}');
        throw Exception('Erro ao carregar produtos: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
      debugPrint('Erro ao carregar produtos: $e');
    }
  }

  Future<void> _handleEditProduct(Product product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(product: product),
      ),
    );

    if (result == true) {
      await _loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produto atualizado com sucesso!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _handleCreateProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateProductScreen()),
    );
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Produtos'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.add, color: Colors.white),
          onPressed: _handleCreateProduct,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar produtos',
              style:
                  AppTheme.subheadingStyle.copyWith(color: AppTheme.errorColor),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: AppTheme.secondaryTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory,
              size: 48,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleCreateProduct,
              icon: const Icon(Icons.add),
              label: const Text('Criar primeiro produto'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return _buildProductCard(p);
        },
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    debugPrint('Exibindo produto: ${p.nome}, ID: ${p.id}');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildProductImage(p),
                const SizedBox(width: 16),
                _buildProductInfo(p),
                _buildEditButton(p),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1),
            const SizedBox(height: 12),
            _buildPriceRow(p),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCategoryChip(p),
                const SizedBox(width: 8),
                if (p.caracteristicasIDs.isNotEmpty)
                  Expanded(child: _buildCharacteristicsChip(p)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product p) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.backgroundColor,
      ),
      child: p.imagemBase64 != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                base64Decode(p.imagemBase64!),
                fit: BoxFit.cover,
              ),
            )
          : p.imagemUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    p.imagemUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(Icons.image, color: AppTheme.textSecondaryColor, size: 30),
    );
  }

  Widget _buildProductInfo(Product p) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.nome,
            style: AppTheme.cardTitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            p.descricao,
            style: AppTheme.secondaryTextStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(Product p) {
    return IconButton(
      icon: Icon(Icons.edit, color: AppTheme.primaryColor),
      onPressed: () => _handleEditProduct(p),
    );
  }

  Widget _buildPriceRow(Product p) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'R\$${p.valorVenda.toStringAsFixed(2)}',
              style: AppTheme.emphasizedTextStyle.copyWith(
                color: AppTheme.primaryColor,
                fontSize: 18,
              ),
            ),
            if (p.valorCusto > 0)
              Text(
                'Custo: R\$${p.valorCusto.toStringAsFixed(2)}',
                style: AppTheme.captionStyle,
              ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              p.disponivel ? 'Disponível' : 'Indisponível',
              style: TextStyle(
                color:
                    p.disponivel ? AppTheme.successColor : AppTheme.errorColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Switch(
              value: p.disponivel,
              onChanged: (value) {
                // TODO: Implementar toggle de disponibilidade
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Funcionalidade em desenvolvimento'),
                    backgroundColor: AppTheme.infoColor,
                  ),
                );
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(Product p) {
    return AppTheme.buildBadge(
      text: p.categoria,
      backgroundColor: AppTheme.primaryColor,
      textColor: Colors.white,
    );
  }

  Widget _buildCharacteristicsChip(Product p) {
    final characteristicsText =
        CharacteristicsHelper.mapCharacteristics(p.caracteristicasIDs);

    debugPrint('Texto das características do produto: $characteristicsText');

    if (characteristicsText.isEmpty ||
        characteristicsText == 'Sem características') {
      debugPrint('Nenhuma característica encontrada para o produto ${p.nome}');
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        characteristicsText,
        style: TextStyle(
          color: AppTheme.accentColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
