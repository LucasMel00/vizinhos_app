// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart';
import 'package:vizinhos_app/screens/login_screen.dart';
import 'package:vizinhos_app/services/secure_storage.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    await Future.delayed(Duration(seconds: 2)); // Simula um tempo de carregamento
    final token = await _secureStorage.getToken(); // Leitura assíncrona do token
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Icon(
          Icons.directions_walk,
          size: 100,
          color: Colors.black,
        ),
      ),
    );
  }
}
