import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart';
import 'package:vizinhos_app/screens/login/home_screen.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_account_page.dart';
import 'package:vizinhos_app/screens/vendor/create_store_screen.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

class UserAccountPage extends StatelessWidget {
  final Map<String, dynamic>? userInfo;

  const UserAccountPage({Key? key, this.userInfo}) : super(key: key);

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
        userInfo ?? providerUserInfo;
    final sellerProfile = authProvider.storeInfo;

    final bool isSeller = authProvider.isSeller;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Conta',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
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
                  child:
                      const Icon(Icons.person, size: 35, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveUserInfo?['Name'] ?? 'Nome não disponível',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        effectiveUserInfo?['Email'] ?? 'Email não disponível',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Aba de painel do vendedor, exibida apenas se o usuário for vendedor
          if (isSeller)
            _buildListTile(
              icon: Icons.store_mall_directory,
              title: 'Loja',
              onTap: () {
                if (sellerProfile != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VendorAccountPage(userInfo: effectiveUserInfo ?? {}),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateStoreScreen(
                        userId: effectiveUserInfo?['sub'] ?? '',
                      ),
                    ),
                  ).then((shouldRefresh) {
                    if (shouldRefresh == true) {
                      authProvider.refreshUserData();
                    }
                  });
                }
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Procurar'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Conta'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => HomePage()));
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SearchPage()));
              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => OrdersPage()));
              break;
            case 3:
              break;
          }
        },
      ),
    );
  }

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
