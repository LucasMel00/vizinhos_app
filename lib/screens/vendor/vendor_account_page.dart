import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/vendor/vendor_edit_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_orders_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_products_page.dart';
import 'package:vizinhos_app/services/app_theme.dart';

class VendorAccountPage extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const VendorAccountPage({super.key, required this.userInfo});

  @override
  _VendorAccountPageState createState() => _VendorAccountPageState();
}

class _VendorAccountPageState extends State<VendorAccountPage> {
  late Map<String, dynamic> _currentUserInfo = widget.userInfo;
  late final String _userId;

  Map<String, dynamic>? storeData;
  bool _isLoading = true;

  List<Product> _products = [];
  bool _isProductsLoading = true;

  bool _infoExpanded = true;

  @override
  void initState() {
    super.initState();
    _userId = widget.userInfo['usuario']?['id_Usuario'] ?? '';
    _currentUserInfo = widget.userInfo;
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    try {
      final idEndereco = _currentUserInfo['endereco']?['id_Endereco'];
      if (idEndereco == null) throw Exception('ID do endereço não encontrado');

      final response = await http.get(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetAddressById?id_Endereco=$idEndereco'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          storeData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar loja: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }



  void _navigateToEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorEditPage(
          userInfo: _currentUserInfo,
          storeData: storeData ?? {},
          onSave: (updatedData) {
            setState(() {
              storeData = updatedData;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeName = storeData?['endereco']?['nome_Loja'] ?? 'Sua Loja';
    final storeDescription =
        storeData?['endereco']?['descricao_Loja'] ?? 'Sem descrição';
    final userName =
        widget.userInfo['usuario']?['nome'] ?? 'Nome não disponível';
    final userPhone =
        widget.userInfo['usuario']?['telefone'] ?? 'Telefone não disponível';

    final storeAddress =
        '${storeData?['endereco']?['logradouro'] ?? ''}, ${storeData?['endereco']?['numero'] ?? ''}';
    final storeComplement = storeData?['endereco']?['complemento'] ?? '';
    final deliveryType =
        storeData?['endereco']?['tipo_Entrega'] ?? 'Não especificado';
    final storeCep = storeData?['endereco']?['cep'] ?? '';

    Widget storeImageWidget =
        Icon(Icons.store, size: 40, color: AppTheme.primaryColor);

    String? imageUrl = storeData?['endereco']?['imagem_url'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      storeImageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 110,
        height: 110,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.store, size: 40, color: AppTheme.primaryColor),
      );
    }

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(storeName),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEditPage,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Cabeçalho com informações da loja
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 30, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).round()),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar da loja
                            CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: storeData?['endereco'] != null &&
                                storeData!['endereco']['id_Imagem'] != null &&
                                storeData!['endereco']['id_Imagem']
                                  .toString()
                                  .isNotEmpty
                              ? ClipOval(
                                child: Image.network(
                                  'https://loja-profile-pictures.s3.amazonaws.com/${storeData?['endereco']['id_Imagem']}',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[200],
                                  child: Icon(Icons.store,
                                    size: 40, color: Colors.grey),
                                  ),
                                ),
                                )
                              : ClipOval(
                                child: SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: storeImageWidget,
                                ),
                                ),
                            ),
                          const SizedBox(height: 15),
                          // Nome da loja
                          Text(
                            storeName,
                            style: AppTheme.onPrimaryTextStyle.copyWith(
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Descrição da loja
                          Text(
                            storeDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Conteúdo principal
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Seção de informações da loja
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            child: ExpansionTile(
                              initiallyExpanded: _infoExpanded,
                              onExpansionChanged: (val) {
                                setState(() => _infoExpanded = val);
                              },
                              leading:
                                  Icon(Icons.info, color: AppTheme.accentColor),
                              title: Text(
                                'Informações da Loja',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 16, bottom: 16),
                                  child: Column(
                                    children: [
                                      AppTheme.buildInfoCard(
                                        icon: Icons.person,
                                        title: 'Proprietário',
                                        value: userName,
                                      ),
                                      AppTheme.buildInfoCard(
                                        icon: Icons.phone,
                                        title: 'Telefone',
                                        value: userPhone,
                                      ),
                                      AppTheme.buildInfoCard(
                                        icon: Icons.location_on,
                                        title: 'Endereço',
                                        value:
                                            '$storeAddress${storeComplement.isNotEmpty ? ' - $storeComplement' : ''}',
                                      ),
                                      AppTheme.buildInfoCard(
                                        icon: Icons.local_shipping,
                                        title: 'Tipo de Entrega',
                                        value: deliveryType,
                                      ),
                                      AppTheme.buildInfoCard(
                                        icon: Icons.location_city,
                                        title: 'CEP',
                                        value: storeCep,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Seção de ações rápidas
                          AppTheme.buildSectionHeader(
                              'Ações Rápidas', Icons.flash_on),
                          const SizedBox(height: 15),
                          // Botões de ação
                          Row(
                            children: [
                              Expanded(
                                child: AppTheme.buildActionButton(
                                  label: 'Produtos',
                                  icon: Icons.shopping_bag,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VendorProductsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppTheme.buildActionButton(
                                  label: 'Pedidos',
                                  icon: Icons.receipt_long,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OrdersVendorPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          // Estatísticas da loja (nova seção)
                          const SizedBox(height: 25),
                          AppTheme.buildSectionHeader(
                              'Estatísticas', Icons.bar_chart),
                          const SizedBox(height: 15),
                          // Cards de estatísticas
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Vendas',
                                  value: '0',
                                  icon: Icons.shopping_cart,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Produtos',
                                  value: _isProductsLoading
                                      ? '...'
                                      : _products.length.toString(),
                                  icon: Icons.inventory,
                                  color: AppTheme.infoColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Avaliação',
                                  value: '5.0',
                                  icon: Icons.star,
                                  color: Colors.amber,
                                ),
                              ),
                              
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Widget para card de estatísticas
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
