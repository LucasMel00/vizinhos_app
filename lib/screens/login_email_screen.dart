import 'package:flutter/material.dart';

class LoginEmailScreen extends StatelessWidget {
  final String email;

  LoginEmailScreen({required this.email});

  final TextEditingController passwordController = TextEditingController();

  // Função para realizar o login (a ser implementada)
  void login(BuildContext context) {
    // Implemente a lógica de autenticação aqui
    final password = passwordController.text.trim();

    if (password.isNotEmpty) {
      // Exemplo de lógica de autenticação
      // Você pode fazer uma requisição para a API para validar a senha

      // Se a autenticação for bem-sucedida, navegue para a próxima tela
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login bem-sucedido!")),
      );
      // Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor, insira sua senha.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Bem-vindo de volta!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            TextField(
              enabled: false,
              controller: TextEditingController(text: email),
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
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
            ElevatedButton(
              onPressed: () => login(context),
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
