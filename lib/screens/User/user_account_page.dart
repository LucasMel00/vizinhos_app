import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/login/home_screen.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_account_page.dart';
import 'package:vizinhos_app/screens/vendor/create_store_screen.dart';
import '../../services/auth_provider.dart';
import '../../services/secure_storage.dart';

class UserAccountPage extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const UserAccountPage({Key? key, this.userInfo}) : super(key: key);

  @override
  _UserAccountPageState createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  bool _isSeller = false;

  @override
  void initState() {
    super.initState();
    _loadSellerStatus();
  }

  /// Carrega o status de vendedor do SecureStorage
  Future<void> _loadSellerStatus() async {
    final storeInfo = await SecureStorage().getStoreInfo();
    setState(() {
      _isSeller = storeInfo != null; // Se houver dados da loja, é vendedor
    });
  }

  /// Função para decodificar o ID Token (JWT)
  Map<String, dynamic> decodeIdToken(String idToken) {
    final parts = idToken.split('.');
    if (parts.length != 3) {
      throw Exception('Token inválido');
    }
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded) as Map<String, dynamic>;
  }

  /// Função para realizar o logout e redirecionar para a tela de login
  Future<void> _logout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    await SecureStorage()
        .deleteStoreInfo(); // Remove os dados da loja ao deslogar
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final Map<String, dynamic>? providerUserInfo = authProvider.userInfo;
    final Map<String, dynamic>? effectiveUserInfo =
        widget.userInfo ?? providerUserInfo;

    // Decodifica o token para extrair informações extras, se disponível.
    Map<String, dynamic> tokenData = {};
    if (authProvider.idToken != null) {
      try {
        tokenData = decodeIdToken(authProvider.idToken!);
      } catch (e) {
        debugPrint('Erro ao decodificar o ID Token: $e');
      }
    }

    // Extraímos as informações para exibição:
    final String displayName = effectiveUserInfo?['Name'] ??
        tokenData['name'] ??
        'Nome não disponível';
    final String displayEmail = effectiveUserInfo?['Email'] ??
        tokenData['email'] ??
        'Email não disponível';
    String displayAddress = 'Endereço não cadastrado';
    if (effectiveUserInfo?['Address'] != null &&
        effectiveUserInfo!['Address'] is Map<String, dynamic>) {
      final address = effectiveUserInfo['Address'];
      displayAddress = '${address['Street'] ?? ''}, ${address['CEP'] ?? ''}';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Conta',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, size: 35, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayEmail,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayAddress,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Exibe o painel do vendedor se for vendedor
          // Exibe o painel do vendedor se for vendedor
          // Exibe o painel do vendedor se for vendedor
          if (_isSeller)
            _buildListTile(
              icon: Icons.store,
              title: 'Painel do Vendedor',
              onTap: () {
                if (effectiveUserInfo != null) {
                  // Convertendo o Map<dynamic, dynamic> para Map<String, dynamic>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorAccountPage(
                        userInfo: Map<String, dynamic>.from(effectiveUserInfo!),
                      ),
                    ),
                  );
                } else {
                  // Se effectiveUserInfo for nulo, vai para a tela de criação de loja
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateStoreScreen(
                        userId:
                            '', // Passa um id vazio ou de acordo com a lógica
                      ),
                    ),
                  );
                }
              },
            )
          else
            _buildListTile(
              icon: Icons.store_mall_directory,
              title: 'Criar Loja',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateStoreScreen(
                      userId: effectiveUserInfo?['sub'] ??
                          '', // Passa o userId, se disponível
                    ),
                  ),
                );
              },
            ),

          _buildListTile(
            icon: Icons.favorite_border,
            title: 'Seus Favoritos',
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Carteira',
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Ajuda',
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.card_giftcard,
            title: 'Cupons',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Novo',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ),
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.notifications_none,
            title: 'Notificação',
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.star_border,
            title: 'Avalie seu Vizinho',
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Deslogar', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _logout(context);
            },
          ),
        ],
      ),
    );
  }

  /// Método auxiliar para criar um ListTile
  ListTile _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    void Function()? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
