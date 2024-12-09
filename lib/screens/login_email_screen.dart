// lib/screens/login_email_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/User/home_page_user.dart';
import 'package:vizinhos_app/services/secure_storage.dart';

class LoginEmailScreen extends StatefulWidget {
  final String email;

  LoginEmailScreen({required this.email});

  @override
  _LoginEmailScreenState createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  final SecureStorage _secureStorage = SecureStorage();

  Future<void> loginUser(BuildContext context) async {
    final url = Uri.parse('https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/login');

    setState(() {
      isLoading = true;
    });

    final body = {
      'email': widget.email,
      'password': passwordController.text.trim(),
    };

    final client = http.Client();

    try {
      print('Enviando dados: ${jsonEncode(body)}');

      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Salva o token usando SecureStorage
        final String token = responseData['accessToken'];
        await _secureStorage.setToken(token);

        // Exibe mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login realizado com sucesso!")),
        );

        // Navegar para a HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // Exibir mensagem de erro retornada pela API
        final data = jsonDecode(response.body);
        String errorMessage = data['error'] ?? 'Erro ao fazer login.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } on http.ClientException catch (e) {
      print('ClientException: $e');
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro de conexão: $e")),
      );
    } catch (e) {
      print('Erro inesperado: $e');
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro inesperado: $e")),
      );
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Bem-vindo de volta!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Text("Email: ${widget.email}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Senha",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 24),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: () {
                if (passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Por favor, insira sua senha.")),
                  );
                  return;
                }
                loginUser(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Entrar", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
