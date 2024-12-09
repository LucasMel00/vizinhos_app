import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vizinhos_app/screens/User/logout_user.dart';
import 'package:vizinhos_app/screens/login_screen.dart';

class UserAccountPage extends StatelessWidget {
  const UserAccountPage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Estilização de texto padrão
    final titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    final subtitleStyle = TextStyle(fontSize: 14, color: Colors.grey[600]);

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
                        'Lucas Melo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Ação ao clicar em "Veja sua Conta" (poderia ser para tela de edição)
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditAccountPage()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Veja sua Conta',
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          ),
                        ),
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
            onTap: () {
              // Ação ao clicar
            },
          ),
          _buildListTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Carteira',
            onTap: () {
              // Ação ao clicar
            },
          ),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Ajuda',
            onTap: () {
              // Ação ao clicar
            },
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
            onTap: () {
              // Ação ao clicar
            },
          ),
          _buildListTile(
            icon: Icons.notifications_none,
            title: 'Notificação',
            onTap: () {
              // Ação ao clicar
            },
          ),
          _buildListTile(
            icon: Icons.star_border,
            title: 'Avalie seu Vizinho',
            onTap: () {
              // Ação ao clicar
            },
          ),

          // Ao clicar neste item, o usuário vai para a página de logout
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Deslogar', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LogoutPage(onLogout: () => _logout(context)),
                ),
              );
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

class EditAccountPage extends StatelessWidget {
  const EditAccountPage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressTitleStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    final addressSubtitleStyle = TextStyle(color: Colors.grey[600]);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: Text('Editar sua Conta', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          // Perfil e opção de editar
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
                        'Lucas Melo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Ação para editar dados do usuário
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Edite sua Conta',
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(),

          // Endereços Salvos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Text(
              'Endereços Salvos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildAddressTile(
            icon: Icons.home,
            title: 'Home',
            subtitle: 'Rua Paulino Vital de Morais, 680',
          ),
          _buildAddressTile(
            icon: Icons.school,
            title: 'Faculdade',
            subtitle: 'Instituto Federal de São Paulo',
          ),
          ListTile(
            leading: Icon(Icons.add, color: Colors.green),
            title: Text('Adicionar Novo', style: TextStyle(color: Colors.green)),
            onTap: () {
              // Ação para adicionar novo endereço
            },
          ),

          Divider(),

          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Deslogar', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  ListTile _buildAddressTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      onTap: () {
        // Ação ao clicar no endereço
      },
    );
  }
}

