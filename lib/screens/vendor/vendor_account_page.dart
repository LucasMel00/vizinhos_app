import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/vendor/vendor_edit_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_orders_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_products_page.dart';
import 'package:vizinhos_app/services/app_theme.dart';
import 'package:vizinhos_app/screens/onboarding/mercado_pago_key_screen.dart';
import 'package:vizinhos_app/services/secure_storage.dart';

class VendorAccountPage extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const VendorAccountPage({super.key, required this.userInfo});

  @override
  _VendorAccountPageState createState() => _VendorAccountPageState();
}

class _VendorAccountPageState extends State<VendorAccountPage> with WidgetsBindingObserver {
  late Map<String, dynamic> _currentUserInfo = widget.userInfo;
  late final String _userId;

  Map<String, dynamic>? storeData;
  bool _isLoading = true;

  List<Product> _products = [];
  bool _isProductsLoading = true;

  bool _infoExpanded = true;
  bool _mercadoPagoKeyMissing = false;
  
  final SecureStorage _secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userId = widget.userInfo['usuario']?['id_Usuario'] ?? '';
    _currentUserInfo = widget.userInfo;
    _loadStoreData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStoreData();
    }
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    try {
      final idEndereco = _currentUserInfo['endereco']?['id_Endereco'];
      if (idEndereco == null) throw Exception('ID do endereço não encontrado');

      // Salvar o ID do endereço no SecureStorage para uso posterior
      await _secureStorage.setEnderecoId(idEndereco.toString());

      final response = await http.get(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetAddressById?id_Endereco=$idEndereco'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        final responseData = jsonDecode(response.body);
        
        // Verificar se o access_token está presente na resposta da API
        final hasAccessToken = responseData['endereco'] != null && 
                              responseData['endereco']['access_token'] != null && 
                              responseData['endereco']['access_token'].toString().isNotEmpty;
        
        setState(() {
          storeData = responseData;
          _mercadoPagoKeyMissing = !hasAccessToken;
          _isLoading = false;
        });
        
        // Se o token estiver presente na API, podemos salvá-lo no SecureStorage para uso futuro
        if (hasAccessToken) {
          await _secureStorage.setMercadoPagoToken(responseData['endereco']['access_token']);
          await _secureStorage.setMercadoPagoSkipped(false);
        }
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

  void _navigateToMercadoPagoKeyScreen() async {
    // Navigate to MercadoPagoKeyScreen and wait for a potential result or state change
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MercadoPagoKeyScreen()),
    );
    // Re-check the status after returning from the screen by reloading store data
    _loadStoreData();
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
            : ListView(
                padding: EdgeInsets.zero,
                physics: BouncingScrollPhysics(),
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
                          Text(
                            storeName,
                            style: AppTheme.onPrimaryTextStyle.copyWith(
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 5),
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
                    // Widget de Alerta para Chave Mercado Pago - exibido apenas se o access_token estiver ausente na API
                    if (_mercadoPagoKeyMissing)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: InkWell(
                          onTap: _navigateToMercadoPagoKeyScreen,
                          child: Card(
                            color: Colors.red[50],
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Clique aqui para cadastrar seu token do Mercado Pago e receber pagamentos.',
                                      style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, color: Colors.red[700], size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Conteúdo principal
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          AppTheme.buildSectionHeader(
                              'Ações Rápidas', Icons.flash_on),
                          const SizedBox(height: 15),
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
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: AppTheme.buildActionButton(
                                  label: 'Configurações',
                                  icon: Icons.settings,
                                  onPressed: () {
                                    // Navegar para configurações
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppTheme.buildActionButton(
                                  label: 'Mercado Pago',
                                  icon: Icons.payment,
                                  onPressed: _navigateToMercadoPagoKeyScreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      
    );
  }
}
