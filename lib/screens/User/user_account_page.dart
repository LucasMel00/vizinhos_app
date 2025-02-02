import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/login/home_screen.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_account_page.dart';
import 'package:vizinhos_app/screens/vendor/create_store_screen.dart';
import '../../services/auth_provider.dart';

class UserAccountPage extends StatelessWidget {
  final Map<String, dynamic>? userInfo;

  const UserAccountPage({Key? key, this.userInfo}) : super(key: key);

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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtemos o AuthProvider para acessar dados do usuário e o token.
    final authProvider = Provider.of<AuthProvider>(context);

    // Caso o widget receba um userInfo, damos preferência a ele;
    // caso contrário, usamos o userInfo do provider.
    final Map<String, dynamic>? providerUserInfo = authProvider.userInfo;
    final Map<String, dynamic>? effectiveUserInfo =
        userInfo ?? providerUserInfo;

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

    // Define isSeller utilizando somente o valor atualizado do AuthProvider.
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
        leading: BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          // Seção de perfil – exibe foto, nome, email e endereço
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

          // Aba de painel do vendedor, exibida apenas se o usuário for vendedor
          if (isSeller)
            _buildListTile(
              icon: Icons.store,
              title: 'Painel do Vendedor',
              onTap: () {
                if (effectiveUserInfo == null || effectiveUserInfo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao carregar dados do vendedor'),
                    ),
                  );
                  return;
                }
                // Verifica se existe o perfil do vendedor
                final sellerProfile = effectiveUserInfo['sellerProfile'];
                if (sellerProfile == null ||
                    (sellerProfile is Map && sellerProfile.isEmpty)) {
                  // Se não houver sellerProfile, navega para a tela de criação da loja.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateStoreScreen(
                        userId: effectiveUserInfo['userId'] ?? '',
                      ),
                    ),
                  );
                } else {
                  // Se o perfil já existir, navega para o painel do vendedor
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorAccountPage(
                        userInfo: effectiveUserInfo,
                      ),
                    ),
                  );
                }
              },
            ),

          // Outros itens do menu
          _buildListTile(
            icon: Icons.favorite_border,
            title: 'Seus Favoritos',
            onTap: () {
              // TODO: Implementar funcionalidade dos favoritos
            },
          ),
          _buildListTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Carteira',
            onTap: () {
              // TODO: Implementar funcionalidade da carteira
            },
          ),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Ajuda',
            onTap: () {
              // TODO: Implementar funcionalidade de ajuda
            },
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
            onTap: () {
              // TODO: Implementar funcionalidade dos cupons
            },
          ),
          _buildListTile(
            icon: Icons.notifications_none,
            title: 'Notificação',
            onTap: () {
              // TODO: Implementar funcionalidade das notificações
            },
          ),
          _buildListTile(
            icon: Icons.star_border,
            title: 'Avalie seu Vizinho',
            onTap: () {
              // TODO: Implementar funcionalidade de avaliação
            },
          ),

          // Botão para realizar logout
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
        currentIndex: 0,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Procurar'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Conta'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrdersPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UserAccountPage(userInfo: userInfo)),
              );
              break;
          }
        },
      ),
    );
  }

  /// Método auxiliar para criar um ListTile com ícone, título, trailing (opcional) e ação
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
