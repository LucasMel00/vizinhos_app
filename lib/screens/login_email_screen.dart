// lib/screens/login_email_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

class LoginEmailScreen extends StatefulWidget {
  final String email;

  LoginEmailScreen({required this.email});

  @override
  _LoginEmailScreenState createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> loginUser(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final url = Uri.parse('https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/login');

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final body = {
      'email': widget.email,
      'password': passwordController.text.trim(),
    };

    try {
      print('Enviando dados para o servidor: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Verifica se todos os tokens estão presentes
        if (responseData.containsKey('accessToken') &&
            responseData.containsKey('idToken') &&
            responseData.containsKey('refreshToken') &&
            responseData.containsKey('expiresIn')) {

          // Salva os tokens usando AuthProvider
          await authProvider.login(
            accessToken: responseData['accessToken'],
            idToken: responseData['idToken'],
            refreshToken: responseData['refreshToken'],
            expiresIn: responseData['expiresIn'],
          );

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
          setState(() {
            errorMessage = 'Resposta do servidor incompleta.';
          });
          print('Erro no login: Resposta incompleta.');
        }
      } else {
        // Exibir mensagem de erro retornada pela API
        final data = jsonDecode(response.body);
        String apiErrorMessage = data['error'] ?? 'Erro ao fazer login.';
        setState(() {
          errorMessage = apiErrorMessage;
        });
        print('Erro no login: $apiErrorMessage');
      }
    } catch (e) {
      print('Erro inesperado: $e');
      setState(() {
        isLoading = false;
        errorMessage = "Erro inesperado: $e";
      });
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
            if (widget.email.isNotEmpty)
              Text("Email: ${widget.email}", style: TextStyle(fontSize: 16)),
            if (widget.email.isNotEmpty) SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Senha",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 24),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Entrar", style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}
