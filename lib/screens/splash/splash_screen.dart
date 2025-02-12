// lib/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:vizinhos_app/screens/login/home_screen.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Aguarda o carregamento inicial dos dados de autenticação (tokens, etc.)
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Se o usuário estiver logado, busca os dados completos do usuário na API
    if (authProvider.isLoggedIn) {
      await authProvider.fetchUserDataFromAPI();
      // Nesse momento, o AuthProvider deve ter salvo as informações (ex.: sellerProfile)
      // no Secure Storage e na variável local (_storeInfo)
    }

    // Após a inicialização, navega para a tela apropriada
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) =>
            authProvider.isLoggedIn ? HomePage() : LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo do aplicativo
              Image.asset(
                "assets/images/default_restaurant_image.jpg",
                width: 450,
                height: 450,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
