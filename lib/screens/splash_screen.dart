import 'package:flutter/material.dart';
import 'package:vizinhos_app/screens/home_page.dart';
import 'package:vizinhos_app/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    // Aguarda 2 segundos antes de redirecionar
    await Future.delayed(Duration(seconds: 2));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
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
