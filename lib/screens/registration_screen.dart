import 'package:flutter/material.dart';

class RegistrationScreen extends StatelessWidget {
  final String email;

  RegistrationScreen({required this.email});

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController sobrenomeController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  // Função para registrar o usuário (a ser implementada)
  void register(BuildContext context) {
    final nome = nomeController.text.trim();
    final sobrenome = sobrenomeController.text.trim();
    final cpf = cpfController.text.trim();
    final senha = senhaController.text.trim();

    if (nome.isNotEmpty && sobrenome.isNotEmpty && cpf.isNotEmpty && senha.isNotEmpty) {
      // Implemente a lógica de registro aqui
      // Por exemplo, enviar os dados para a API para salvar no banco de dados

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registro bem-sucedido!")),
      );
      // Após registrar, você pode navegar para a tela de login ou diretamente para a home
      // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen(email: email)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor, preencha todos os campos.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pré-preencher o campo de email com o email inserido
    final emailController = TextEditingController(text: email);

    return Scaffold(
      appBar: AppBar(
        title: Text("Registro"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Crie sua conta",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            TextField(
              enabled: false,
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: "Nome",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: sobrenomeController,
              decoration: InputDecoration(
                labelText: "Sobrenome",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: cpfController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "CPF",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Senha",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => register(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Registrar", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
