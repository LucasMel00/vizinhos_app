import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/registration_screen.dart';
import 'login_email_screen.dart';

class EmailScreen extends StatefulWidget {
  @override
  _EmailScreenState createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false; // Variável para controlar o estado de carregamento

  Future<void> checkEmail(BuildContext context, String email) async {
    final url = Uri.parse('https://7nxpb54n5l.execute-api.us-east-2.amazonaws.com/email/$email');

    setState(() {
      isLoading = true; // Ativa o estado de carregamento
    });

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

          if (isConfirmed) {
            // Redirecionar para a tela de login se o email estiver confirmado
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginEmailScreen(email: email)),
            );
          } else {
            // Mostrar diálogo pedindo para confirmar o email
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Confirmação de Email'),
                content: Text('Por favor, confirme seu email antes de continuar.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Fecha o diálogo
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          // Se o usuário não existir, redirecionar para a tela de registro
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegistrationScreen(email: email)),
          );
        }
      } else if (response.statusCode == 400) {
        // Se o status for 400, redirecionar para a tela de registro
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegistrationScreen(email: email)),
        );
      } else {
        // Exibir mensagem de erro para outros códigos de status
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao verificar o email: ${response.statusCode} - ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro de conexão: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isLoading = false; // Desativa o estado de carregamento
      });
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null // Desativa o botão quando isLoading é true
                    : () {
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("Verificando...", style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : Text("Continuar", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
