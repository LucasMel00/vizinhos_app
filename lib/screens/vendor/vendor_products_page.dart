import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/services/app_theme.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:vizinhos_app/screens/model/product.dart'; // Contains Product and Characteristic classes now
import 'package:vizinhos_app/screens/vendor/vendor_create_product_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_edit_product_page.dart';

// Removed CharacteristicsHelper class as it's no longer needed here
// The Product model now fetches characteristics with descriptions directly

class VendorProductsPage extends StatefulWidget {
  @override
  _VendorProductsPageState createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage> {
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;

  // Removed _getCategoryId as it seems unused
  // int _getCategoryId(String categoria) {
  //   return int.tryParse(categoria) ?? 0;
  // }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Removed _categoryId as it seems unused
  // int _categoryId(String c) { ... }

  Future<void> _toggleDisponibilidade(Product p, bool novoValor) async {
    final auth = context.read<AuthProvider>();

    // Extract only IDs for the request body, as handled by Product.toJson()
    List<String> caracteristicasIDs =
        p.caracteristicas!.map((c) => c.id_Caracteristica).toList();

    final body = {
      'id_Produto': p.id,
      'nome': p.nome,
      'descricao': p.descricao,
      'fk_id_Categoria': int.parse(p.fkIdCategoria.toString()),
      'dias_vcto': p.diasValidade,
      'valor_venda': p.valorVenda,
      'valor_custo': p.valorCusto,
      'tamanho': p.tamanho,
      'disponivel': novoValor,
      'caracteristicas_IDs': caracteristicasIDs, // Send only IDs
      'id_imagem': p.imageId,
    };

    final String url =
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateProduct';
    debugPrint('Fazendo PUT para: $url');
    debugPrint(
        'Headers: {"Content-Type": "application/json", "Authorization": "Bearer ${auth.accessToken}"}');
    debugPrint('Body: ${jsonEncode(body)}');

    try {
      final resp = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.accessToken}',
        },
        body: jsonEncode(body),
      );

      debugPrint('Response Status Code: ${resp.statusCode}');
      debugPrint('Response Body: ${resp.body}');

      if (resp.statusCode == 200) {
        setState(() => p.disponivel = novoValor);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produto atualizado com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erro ao atualizar produto: ${resp.statusCode} - ${resp.body}'), // Added response body for better error info
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao atualizar disponibilidade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar produto: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      // Removed call to CharacteristicsHelper.loadCharacteristics(auth);

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

        if (body.containsKey('produtos') && body['produtos'] != null) {
          final lista = body['produtos'] as List<dynamic>;
          // Product.fromJson now handles parsing the List<Characteristic>
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
          if (mounted) {
            setState(() {
              products = [];
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage =
                'Erro ao carregar produtos: Crie um produto para poder listar'; // More specific error
          });
        }
        debugPrint('Erro ao carregar produtos: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        // Handle specific error cases
        setState(() {
          isLoading = false;
          errorMessage = 'Nenhum produto existente: Clique em criar um produto';
          
           // More specific error
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
      await _loadProducts(); // Reload products after edit
      // Removed redundant SnackBar, EditProductScreen likely shows one
    }
  }

  Future<void> _handleCreateProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateProductScreen()),
    );
    if (result == true) {
      await _loadProducts(); // Reload products after creation
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Meus Produtos'), // Changed title
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                style: AppTheme.subheadingStyle
                    .copyWith(color: AppTheme.errorColor),
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
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhum produto cadastrado',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 22,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Você ainda não possui produtos cadastrados. Adicione seu primeiro produto para começar a vender!',
                style: AppTheme.secondaryTextStyle.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _handleCreateProduct,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar primeiro produto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
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
    // debugPrint('Exibindo produto: ${p.nome}, ID: ${p.id}, Características: ${p.caracteristicas.map((c) => c.descricao).join(', ')}');
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
              crossAxisAlignment: CrossAxisAlignment.start, // Align items top
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
            _buildPriceAndAvailabilityRow(p), // Combined price and availability
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCategoryChip(p),
                const SizedBox(width: 8),
                // Updated to display characteristics directly from the product model
                if (p.caracteristicas!.isNotEmpty)
                  Expanded(child: _buildCharacteristicsDisplay(p)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product p) {
    return Container(
      width: 70, // Slightly larger image
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.backgroundColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: p.imagemUrl != null && p.imagemUrl!.isNotEmpty
            ? Image.network(
                p.imagemUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Erro ao carregar imagem: $error');
                  return Icon(Icons.broken_image_outlined,
                      color: AppTheme.textSecondaryColor, size: 35);
                },
              )
            : Icon(Icons.image_outlined,
                color: AppTheme.textSecondaryColor, size: 35),
      ),
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
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.inventory_2_outlined,
                size: 14, color: AppTheme.textSecondaryColor),
            SizedBox(width: 4),
            Text(
              'Estoque: ${p.quantidade ?? 'N/A'}',
              style: AppTheme.captionStyle,
            ),
          ]),
          if (p.dataFabricacao != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppTheme.textSecondaryColor),
                SizedBox(width: 4),
                Text(
                  'Fab: ${p.dataFabricacao!.day.toString().padLeft(2, '0')}/'
                  '${p.dataFabricacao!.month.toString().padLeft(2, '0')}/'
                  '${p.dataFabricacao!.year}',
                  style: AppTheme.captionStyle,
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildEditButton(Product p) {
    return IconButton(
      icon: Icon(Icons.edit_outlined,
          color: AppTheme.primaryColor), // Changed icon
      onPressed: () => _handleEditProduct(p),
      tooltip: 'Editar Produto',
    );
  }

  // Combined Price and Availability Row
  Widget _buildPriceAndAvailabilityRow(Product p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'R\$ ${p.valorVenda.toStringAsFixed(2)}',
              style:
                  AppTheme.cardTitleStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            if (p.valorVendaDesc != p.valorVenda && p.valorVendaDesc > 0)
              Text(
                'Oferta: R\$ ${p.valorVendaDesc.toStringAsFixed(2)}',
                style: AppTheme.cardTitleStyle
                    .copyWith(fontWeight: FontWeight.normal, fontSize: 15),
              ),
          ],
        ),
        Row(
          children: [
            Text(
              p.disponivel ? 'Disponível' : 'Indisponível',
              style: TextStyle(
                color:
                    p.disponivel ? AppTheme.successColor : AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
            Switch(
              value: p.disponivel,
              onChanged: (value) => _toggleDisponibilidade(p, value),
              activeColor: AppTheme.successColor,
              inactiveThumbColor: AppTheme.textSecondaryColor,
              inactiveTrackColor: AppTheme.textSecondaryColor.withOpacity(0.3),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(Product p) {
    return Chip(
      label: Text(p.categoria),
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  // Updated widget to display characteristics directly
  Widget _buildCharacteristicsDisplay(Product p) {
    // Use Wrap for better layout if many characteristics exist
    return Wrap(
      spacing: 6.0, // Horizontal space between chips
      runSpacing: 4.0, // Vertical space between lines
      children: p.caracteristicas!.map((characteristic) {
        return Chip(
          label: Text(characteristic.descricao), // Display description
          backgroundColor:
              const Color.fromARGB(255, 233, 186, 69).withOpacity(0.1),
          labelStyle: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0), fontSize: 12),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
