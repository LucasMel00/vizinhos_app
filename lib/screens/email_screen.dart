import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/registration_screen.dart';
import 'login_email_screen.dart';

class EmailScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  Future<void> checkEmail(BuildContext context, String email) async {
    final url = Uri.parse('https://7nxpb54n5l.execute-api.us-east-2.amazonaws.com/email/$email');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] == 'Usuário encontrado') {
          bool isConfirmed = data['is_confirmed'];
          List<dynamic> userAttributes = data['user_attributes'];
          print('Atributos do usuário: $userAttributes');

          if (isConfirmed) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginEmailScreen(email: email)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegistrationScreen(email: email)),
            );
          }
        } else {
          // Se a mensagem for "User does not exist" ou qualquer outro caso de erro,
          // redireciona para a tela de registro
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegistrationScreen(email: email)),
          );
        }
      } else if (response.statusCode == 400) {
        // Se o status for 400, redireciona para a tela de registro
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegistrationScreen(email: email)),
        );
      } else {
        // Se o status não for 200 nem 400, exibe mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao verificar o email: ${response.statusCode} - ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro de conexão: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Verificar Email', style: TextStyle(color: Colors.black)),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Insira seu Email", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                if (email.isNotEmpty && email.contains("@")) {
                  checkEmail(context, email);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Por favor, insira um email válido.")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Continuar", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
