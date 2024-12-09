// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/login_screen.dart';
import '../services/auth_provider.dart';
import 'login_email_screen.dart';
import 'User/home_page_user.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkAuthentication();
  }

  Future<void> checkAuthentication() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadTokens();

    if (authProvider.isAuthenticated) {
      // Navega para a HomePage se estiver autenticado
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // Navega para a tela de login se não estiver autenticado
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Você pode personalizar esta tela como desejar
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
