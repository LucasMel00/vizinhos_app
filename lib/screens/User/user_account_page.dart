import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vizinhos_app/screens/user/home_page_user.dart'; // Ensure this file exists and contains the HomePageUser class
import 'package:vizinhos_app/screens/user/user_profile_page.dart';
import 'package:vizinhos_app/screens/login/email_screen.dart';
import 'package:vizinhos_app/screens/onboarding/onboarding_vendor_screen.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart' hide secondaryColor;
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_account_page.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/user/help_page.dart';

// Define consistent colors
const Color secondaryColor = Color(0xFF3B4351);

class UserAccountPage extends StatefulWidget {
  final Map<String, dynamic>? userInfo;
  const UserAccountPage({Key? key, this.userInfo}) : super(key: key);

  @override
  _UserAccountPageState createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  int _selectedIndex = 3;
  final storage = const FlutterSecureStorage();
  bool _isLoading = true; // Agora só usamos esta flag
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Sempre chamamos ao iniciar

    // Se os dados foram fornecidos via construtor, usamos como valor inicial
    if (widget.userInfo != null) {
      _userInfo = widget.userInfo;
      _isLoading = false;
    }
  }

  Future<void> _fetchUserData() async {
    if (widget.userInfo != null && !_isLoading) {
      if (!mounted) return;
      setState(() => _isLoading = true);
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }
    try {
      String? email = authProvider.email ?? await storage.read(key: 'email');
      if (email == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email não encontrado')),
        );
        setState(() => _isLoading = false);
        return;
      }
      final response = await http.get(
        Uri.parse('https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetUserByEmail?email=$email'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final idEndereco = data['endereco']?['id_Endereco'];
        if (idEndereco != null) {
          await authProvider.setIdEndereco(idEndereco.toString());
        }
        if (!mounted) return;
        setState(() {
          _userInfo = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
<<<<<<< Updated upstream
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
        // Mantemos os dados antigos se a atualização falhar
        setState(() => _isLoading = false);
      }
=======
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => EmailScreen()),
        (route) => false,
      );
      setState(() => _isLoading = false);
>>>>>>> Stashed changes
    }
  }

  // Função para deslogar o usuário
  Future<void> _logout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => EmailScreen()),
      (route) => false,
    );
  }

  // Função para atualizar os dados do usuário (refresh)
  Future<void> _handleRefresh() async {
    await _fetchUserData();
  }

  // Widget auxiliar para construir um ListTile (opção)
  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    void Function()? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black54),
      title: Text(title, style: TextStyle(fontSize: 16, color: textColor)),
      trailing: trailing,
      onTap: onTap,
    );
  }  void _navigateToSellerPage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _fetchUserData();
      if (!mounted) return;
      if (_userInfo != null && _userInfo!['endereco'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final dontShow = prefs.getBool('dontShowVendorOnboarding') ?? false;
        if (dontShow) {
          if (!mounted) return;
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => VendorAccountPage(
                  userInfo: _userInfo!,
                ),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ));
        } else {
          if (!mounted) return;
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VendorOnboardingScreen(
                onContinue: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) =>
                          VendorAccountPage(userInfo: _userInfo!),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
          );
          if (result == true) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VendorAccountPage(
                  userInfo: _userInfo!,
                ),
              ),
            );
          }
        }
      } else {
        throw Exception('Dados da loja não disponíveis');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao acessar loja: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // Método para lidar com a seleção de itens na barra de navegação inferior
  void _onNavItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });

    // Navegar para a página correspondente
    switch (index) {
      case 0:
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => HomePage(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        }
        break;
      case 1:
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => SearchPage(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        }
        break;
      case 2: // Orders
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final cpf = authProvider.cpf ?? '';
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => OrdersPage(cpf: cpf),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        }
        break;
      case 3:
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => UserAccountPage(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        }
        break;
    }
  }

  // Widget para construir cada botão da barra de navegação inferior
  Widget _buildNavIcon(
      IconData icon, String label, int index, BuildContext context) {
    bool isSelected = index == _selectedIndex;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      borderRadius: BorderRadius.circular(20), // Rounded tap area
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color.fromARGB(255, 237, 236, 233)
                  : secondaryColor.withOpacity(0.7),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? const Color.fromARGB(255, 21, 21, 21)
                    : secondaryColor.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isSeller = authProvider.isSeller ||
        (_userInfo?['usuario']?['Usuario_Tipo'] == 'seller');

    // Se ainda está carregando, mostre um indicador de progresso
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Conta',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFbbc2c)),
        ),
      );
    }

    // Se os dados foram carregados, mostre a página completa
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Conta',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Cabeçalho: foto, nome, email e endereço
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [                  GestureDetector(
                    onTap: () {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(
                              userInfo: _userInfo ?? {},
                            ),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xFFFbbc2c),
                      child: const Icon(Icons.person,
                          size: 35, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userInfo?['usuario']?['nome'] ??
                              'Nome não disponível',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userInfo?['usuario']?['email'] ??
                              'Email não disponível',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userInfo?['endereco'] != null
                              ? '${_userInfo!['endereco']['logradouro']}, ${_userInfo!['endereco']['numero']}'
                              : 'Endereço não disponível',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),

                        // Badge de vendedor, se aplicável
                        if (isSeller) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFbbc2c).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Vendedor',
                              style: TextStyle(
                                color: Color(0xFFFbbc2c),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
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
                title: 'Sua Loja',
                iconColor: const Color(0xFFFbbc2c),
                textColor: const Color(0xFF333333),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
                onTap: _navigateToSellerPage,
              ),

            // Outras opções do menu
            _buildListTile(
              icon: Icons.favorite_border,
              title: 'Seus Favoritos',
              onTap: () {},
            ),            _buildListTile(
              icon: Icons.help_outline,
              title: 'Ajuda',
              onTap: () {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpPage()),
                  );
                }
              },
            ),
            _buildListTile(
              icon: Icons.notifications_none,
              title: 'Notificação',
              onTap: () {
                if (mounted) {
                  Navigator.pushNamed(context, '/notifications');
                }
              },
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
      // Barra de navegação inferior flutuante
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFFbbc2c), // Mesma cor do app bar
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavIcon(Icons.home, 'Início', 0, context),
              _buildNavIcon(Icons.search, 'Buscar', 1, context),
              _buildNavIcon(Icons.list, 'Pedidos', 2, context),
              _buildNavIcon(Icons.person, 'Conta', 3, context),
            ],
          ),
        ),
      ),
    );
  }
}
