import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/login/email_screen.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _startSplash();
  }

  Future<void> _startSplash() async {
    // Aguarde 4 segundos antes de verificar o status de autenticação
    await Future.delayed(const Duration(seconds: 4));
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (authProvider.isLoggedIn) {
      await authProvider.fetchUserDataFromAPI();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) =>
            authProvider.isLoggedIn ? HomePage() : EmailScreen(),
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
      backgroundColor: const Color(0xFFFbbc2c),
      body: Center(
        child: Lottie.asset(
          'assets/lottie/mainScene.json',
          controller: _controller,
          onLoaded: (composition) {
            // Define a duração da animação para corresponder aos 4 segundos
            _controller
              ..duration = composition.duration
              ..forward();
          },
        ),
      ),
    );
  }
}
