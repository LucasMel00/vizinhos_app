import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/vendor/vendor_edit_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_orders_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_products_page.dart';

class VendorAccountPage extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const VendorAccountPage({Key? key, required this.userInfo}) : super(key: key);

  @override
  _VendorAccountPageState createState() => _VendorAccountPageState();
}

class _VendorAccountPageState extends State<VendorAccountPage> {
  late Map<String, dynamic> _currentUserInfo = widget.userInfo;
  late String _userId = widget.userInfo['usuario']?['id_Usuario'] ?? '';

  Map<String, dynamic>? storeData;
  bool _isLoading = true;
  bool _infoExpanded = true;

  @override
  void initState() {
    super.initState();
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
        setState(() {
          storeData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar loja: $e')),
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
    final primaryColor = const Color(0xFFFbbc2c);
    final accentColor = const Color(0xFF5F4A14);

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

    Widget storeImageWidget = Icon(Icons.store, size: 40, color: primaryColor);
    String? imageBase64 = storeData?['endereco']?['id_Imagem'];
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        final imageBytes = base64Decode(imageBase64);
        storeImageWidget = Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.store, size: 40, color: primaryColor),
        );
      } catch (e) {
        storeImageWidget = Icon(Icons.store, size: 40, color: primaryColor);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          storeName,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPage,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                          child: ClipOval(
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
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpansionTile(
                          initiallyExpanded: _infoExpanded,
                          onExpansionChanged: (val) {
                            setState(() => _infoExpanded = val);
                          },
                          leading: Icon(Icons.info, color: accentColor),
                          title: Text(
                            'Informações da Loja',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          children: [
                            _infoCard(
                              icon: Icons.person,
                              title: 'Proprietário',
                              value: userName,
                              accentColor: accentColor,
                            ),
                            _infoCard(
                              icon: Icons.phone,
                              title: 'Telefone',
                              value: userPhone,
                              accentColor: accentColor,
                            ),
                            _infoCard(
                              icon: Icons.location_on,
                              title: 'Endereço',
                              value:
                                  '$storeAddress${storeComplement.isNotEmpty ? ' - $storeComplement' : ''}',
                              accentColor: accentColor,
                            ),
                            _infoCard(
                              icon: Icons.local_shipping,
                              title: 'Tipo de Entrega',
                              value: deliveryType,
                              accentColor: accentColor,
                            ),
                            _infoCard(
                              icon: Icons.location_city,
                              title: 'CEP',
                              value: storeCep,
                              accentColor: accentColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        _sectionHeader(
                            'Ações Rápidas', Icons.flash_on, accentColor),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                label: 'Produtos',
                                icon: Icons.shopping_bag,
                                color: primaryColor,
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              VendorProductsPage()));
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _actionButton(
                                label: 'Pedidos',
                                icon: Icons.receipt_long,
                                color: primaryColor,
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              OrdersVendorPage()));
                                },
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

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
  }) {
    return Card(
      color: const Color(0xFFF9F5ED),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
