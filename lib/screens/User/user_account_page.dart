import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart';
import 'package:vizinhos_app/screens/login/email_screen.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_account_page.dart';
import 'package:vizinhos_app/screens/vendor/create_store_screen.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

class UserAccountPage extends StatefulWidget {
  final Map? userInfo;
  const UserAccountPage({Key? key, this.userInfo}) : super(key: key);

  @override
  _UserAccountPageState createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  int _selectedIndex =
      4; // Na tela de conta, o ícone "Conta" (índice 4) fica selecionado.

// Função para deslogar o usuário
  Future<void> _logout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => EmailScreen()),
      (route) => false,
    );
  }

// Função para atualizar os dados do usuário (refresh)
  Future<void> _handleRefresh(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).refreshUserData();
  }

// Widget auxiliar para construir um ListTile (opção)
  Widget _buildListTile({
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

// Widget para construir cada botão da barra de navegação inferior
  Widget _buildNavIcon(IconData icon, int index, BuildContext context) {
    bool isSelected = index == _selectedIndex;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        switch (index) {
          case 0: // Chat/Home – navega para HomePage
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
            break;
          case 1: // Procurar
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SearchPage()),
            );
            break;
          case 2: // Ícone central (ex: Agenda/horário); implementar ação desejada
            // Por exemplo, ação personalizada pode ser adicionada aqui.
            break;
          case 3: // Notificações/Pedidos
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrdersPage()),
            );
            break;
          case 4: // Conta – já estamos nesta página
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? Color.fromARGB(255, 209, 146, 0) : Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final Map? providerUserInfo = authProvider.userInfo;
    final Map? effectiveUserInfo = widget.userInfo ?? providerUserInfo;
    final bool isSeller = authProvider.isSeller;
    return Scaffold(
      extendBody:
          true, // Permite que o conteúdo se estenda por trás da barra inferior flutuante
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
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Cabeçalho: foto, nome, email e endereço
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Color.fromARGB(255, 226, 181, 75),
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
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          effectiveUserInfo?['Address'] != null
                              ? effectiveUserInfo!['Address']['Street']
                              : 'Endereço não disponível',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Painel do vendedor (exibido se o usuário for vendedor)
            if (isSeller)
              _buildListTile(
                icon: Icons.store_mall_directory,
                title: 'Loja',
                onTap: () async {
                  await authProvider.refreshUserData();
                  final updatedUserInfo = authProvider.userInfo;
                  final sellerProfileRaw = updatedUserInfo?['sellerProfile'];
                  final sellerProfile = sellerProfileRaw is Map
                      ? (sellerProfileRaw as Map).cast<String, dynamic>()
                      : <String, dynamic>{};
                  if (sellerProfile.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VendorAccountPage(userInfo: updatedUserInfo),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateStoreScreen(
                          userId: updatedUserInfo?['sub'] ?? '',
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
            // Outras opções do menu
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
                  color: Color.fromARGB(68, 223, 194, 126),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Novo',
                  style: TextStyle(fontSize: 12, color: Color(0xFFFbbc2c)),
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
              title:
                  const Text('Deslogar', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _logout(context);
              },
            ),
          ],
        ),
      ),
      // Barra de navegação inferior flutuante (mesmo estilo da HomePage)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xFF3B4351),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavIcon(Icons.chat_bubble_outline, 0, context),
              _buildNavIcon(Icons.search, 1, context),
              _buildNavIcon(Icons.access_time, 2, context),
              _buildNavIcon(Icons.notifications_none, 3, context),
              _buildNavIcon(Icons.person_outline, 4, context),
            ],
          ),
        ),
      ),
    );
  }
} 
