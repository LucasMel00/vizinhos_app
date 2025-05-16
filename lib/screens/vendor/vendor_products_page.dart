import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vizinhos_app/services/app_theme.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/vendor/vendor_create_product_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_edit_product_page.dart';

class VendorProductsPage extends StatefulWidget {
  @override
  _VendorProductsPageState createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage> {
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;
  bool _skipDeleteConfirmation = false;
  bool _showExpiringOnly = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Métodos de carregamento de dados (mantidos da versão original)
  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
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
                'Erro ao carregar produtos: Crie um produto para poder listar';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Nenhum produto existente: Clique em criar um produto';
        });
      }
    }
  }

  // Métodos auxiliares (mantidos da versão original)
  void _toggleExpiringFilter() {
    setState(() {
      _showExpiringOnly = !_showExpiringOnly;
    });
  }

  List<Product> _getFilteredProducts() {
    if (!_showExpiringOnly) return products;

    return products.where((p) {
      final status = _getExpirationStatus(p);
      return status['status'] == 'expiring' || status['status'] == 'expired';
    }).toList();
  }

  Map<String, dynamic> _getExpirationStatus(Product product) {
    if (product.dataFabricacao == null || product.diasValidade <= 0) {
      return {'status': 'none'};
    }

    final expirationDate =
        product.dataFabricacao!.add(Duration(days: product.diasValidade));
    final daysUntilExpiration =
        expirationDate.difference(DateTime.now()).inDays;

    if (daysUntilExpiration < 0) {
      return {'status': 'expired', 'days': daysUntilExpiration};
    } else if (daysUntilExpiration <= 3) {
      return {'status': 'expiring', 'days': daysUntilExpiration};
    }
    return {'status': 'valid'};
  }

  // Métodos de ação (mantidos da versão original)
  Future<void> _toggleDisponibilidade(Product p, bool novoValor) async {
    final auth = context.read<AuthProvider>();
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
      'caracteristicas_IDs': caracteristicasIDs,
      'id_imagem': p.imageId,
    };

    final String url =
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateProduct';

    try {
      final resp = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.accessToken}',
        },
        body: jsonEncode(body),
      );

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
                'Erro ao atualizar produto: ${resp.statusCode} - ${resp.body}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar produto: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _swapToDiscountPrice(Product product) async {
    final auth = context.read<AuthProvider>();
    final url =
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateProductPrice';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.accessToken}',
        },
        body: jsonEncode({
          'id_Produto': product.id,
          'valor_venda': product.valorVendaDesc,
        }),
      );

      if (response.statusCode == 200) {
        await _loadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preço atualizado para o valor de desconto!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar preço: ${response.body}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar preço: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _confirmDeleteProduct(Product p) async {
    if (_skipDeleteConfirmation) {
      await _deleteProduct(p);
      return;
    }

    bool localDontAskAgain = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Confirmar exclusão'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tem certeza que deseja apagar o produto "${p.nome}"?'),
                  Row(
                    children: [
                      Checkbox(
                        value: localDontAskAgain,
                        onChanged: (val) {
                          setState(() {
                            localDontAskAgain = val ?? false;
                          });
                        },
                      ),
                      Text('Não perguntar novamente'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('Apagar',
                      style: TextStyle(color: AppTheme.errorColor)),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      if (localDontAskAgain) {
        setState(() {
          _skipDeleteConfirmation = true;
        });
      }
      await _deleteProduct(p);
    }
  }

  Future<void> _deleteProduct(Product p) async {
    final auth = context.read<AuthProvider>();
    final url =
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/DeleteProduct?id_Produto=${p.id}';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          products.removeWhere((prod) => prod.id == p.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Produto deletado com sucesso!'),
              backgroundColor: AppTheme.successColor),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao deletar produto: ${response.body}'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao deletar produto: $e'),
            backgroundColor: AppTheme.errorColor),
      );
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
    }
  }

  Future<void> _handleCreateProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateProductScreen()),
    );
    if (result == true) {
      await _loadProducts();
    }
  }

  // UI Refatorada
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Meus Produtos'),
          actions: [
            IconButton(
              icon: Icon(_showExpiringOnly 
                ? Icons.filter_alt 
                : Icons.filter_alt_outlined),
              onPressed: _toggleExpiringFilter,
              tooltip: _showExpiringOnly 
                ? 'Mostrar todos os produtos' 
                : 'Filtrar por validade',
            
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.add, color: Colors.white),
          onPressed: _handleCreateProduct,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
        ),
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

    final filteredProducts = _getFilteredProducts();

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.primaryColor,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          if (_showExpiringOnly) _buildExpiringHeader(),
          ...filteredProducts.map((product) => 
            _buildProductCard(product)).toList(),
        ],
      ),
    );
  }

  Widget _buildExpiringHeader() {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
          SizedBox(width: 8),
          Text('Produtos próximos da validade',
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            SizedBox(height: 16),
            Text('Erro ao carregar produtos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorColor,
                )),
            SizedBox(height: 8),
            Text(errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Tentar novamente'),
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showExpiringOnly 
                ? Icons.event_available 
                : Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _showExpiringOnly
                  ? 'Nenhum produto próximo da validade'
                  : 'Nenhum produto cadastrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _showExpiringOnly
                  ? 'Todos os seus produtos estão com a validade em dia'
                  : 'Clique no botão + para adicionar seu primeiro produto',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            SizedBox(height: 24),
            if (_showExpiringOnly)
              TextButton(
                onPressed: _toggleExpiringFilter,
                child: Text('Mostrar todos os produtos'),
              )
            else
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Adicionar produto'),
                onPressed: _handleCreateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final status = _getExpirationStatus(product);
    final isExpired = status['status'] == 'expired';
    final isExpiring = status['status'] == 'expiring';
    final hasDiscount = product.valorVendaDesc > 0 && 
                       product.valorVendaDesc < product.valorVenda;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExpired 
          ? BorderSide(color: Colors.red[300]!, width: 1.5)
          : BorderSide.none,
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleEditProduct(product),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com imagem e título
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(product),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.nome,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                               IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                tooltip: 'Apagar produto',
                onPressed: () => _confirmDeleteProduct(product),
              ),
                            if (isExpiring || isExpired)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isExpired 
                                    ? Colors.red[100] 
                                    : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isExpired 
                                    ? 'EXPIRADO' 
                                    : 'VENCE EM ${status['days']} DIA${status['days'] == 1 ? '' : 'S'}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isExpired 
                                      ? Colors.red[800] 
                                      : Colors.orange[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          product.descricao,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Detalhes do produto
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildDetailChip(
                    icon: Icons.inventory_2_outlined,
                    label: 'Estoque: ${product.quantidade ?? 0}',
                  ),
                  if (product.dataFabricacao != null)
                    _buildDetailChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Fab: ${_formatDate(product.dataFabricacao)}',
                    ),
                  _buildDetailChip(
                    icon: Icons.category_outlined,
                    label: product.categoria,
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Preço e desconto
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDiscount)
                    Text(
                      'De: R\$ ${product.valorVenda.toStringAsFixed(2)}',
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        'Por: R\$ ${hasDiscount 
                          ? product.valorVendaDesc.toStringAsFixed(2) 
                          : product.valorVenda.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (hasDiscount)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green[100]!),
                          ),
                          child: Text(
                            '${((product.valorVenda - product.valorVendaDesc) / product.valorVenda * 100).toStringAsFixed(0)}% OFF',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (hasDiscount)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: Icon(Icons.discount_outlined, size: 18),
                        label: Text('Aplicar desconto'),
                        onPressed: () => _swapToDiscountPrice(product),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green[800],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),

              // Disponibilidade e ações
              Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Disponível para venda',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch.adaptive(
                    value: product.disponivel,
                    onChanged: (value) => _toggleDisponibilidade(product, value),
                    activeColor: AppTheme.successColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: product.imagemUrl != null && product.imagemUrl!.isNotEmpty
            ? Image.network(
                product.imagemUrl!,
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
                  return Icon(
                    Icons.broken_image_outlined,
                    color: Colors.grey[400],
                    size: 30,
                  );
                },
              )
            : Icon(
                Icons.image_outlined,
                color: Colors.grey[400],
                size: 30,
              ),
      ),
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label}) {
    return Chip(
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(horizontal: 6),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
      backgroundColor: Colors.grey[100],
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}