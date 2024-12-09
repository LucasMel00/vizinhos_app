import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../login_screen.dart';

class UserAccountPage extends StatelessWidget {
  const UserAccountPage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  // Função para decodificar o ID Token
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Decodificar o ID Token
    Map<String, dynamic> userInfo = {};
    try {
      userInfo = decodeIdToken(authProvider.idToken ?? '');
    } catch (e) {
      print('Erro ao decodificar o ID Token: $e');
    }

    // Informações do usuário extraídas do ID Token
    final String name = userInfo['name'] ?? 'Nome não disponível';
    final String email = userInfo['email'] ?? 'Email não disponível';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Conta',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          // Seção Superior do Perfil
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, size: 35, color: Colors.white),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(),

          // Opções da Conta
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
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
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

          // Botão para Logout
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Deslogar', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _logout(context);
            },
          ),
        ],
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
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
