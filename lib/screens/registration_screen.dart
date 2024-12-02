import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:vizinhos_app/screens/login_email_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String email;

  RegistrationScreen({required this.email});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Controladores para os campos de entrada
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cepController = TextEditingController();

  bool isLoading = false;

  Future<void> registerUser() async {
  final url = Uri.parse('https://7nxpb54n5l.execute-api.us-east-2.amazonaws.com/register');

  setState(() {
    isLoading = true;
  });

  // Remover formatação de CPF, CEP e telefone
  String cpf = cpfController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
  String cep = cepController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
  String phoneNumber = phoneNumberController.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');

  final body = {
    'email': widget.email,
    'password': passwordController.text.trim(),
    'full_name': fullNameController.text.trim(),
    'cpf': cpf,
    'phone_number': phoneNumber,
    'address': addressController.text.trim(),
    'cep': cep,
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
      // Registro bem-sucedido
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuário registrado com sucesso.")),
      );
      // Navegar para a tela de login ou próxima etapa
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginEmailScreen(email: widget.email)),
      );
    } else {
      // Registro falhou
      final data = jsonDecode(response.body);
      String errorMessage = data['error'] ?? 'Erro ao registrar usuário.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  } on ClientException catch (e) {
    setState(() {
      isLoading = false;
    });
    print('ClientException: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erro de conexão: $e")),
    );
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    print('Erro inesperado: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erro inesperado: $e")),
    );
  } finally {
    client.close();
  }
}

  @override
  void dispose() {
    // Dispose dos controladores quando o widget for removido
    passwordController.dispose();
    fullNameController.dispose();
    cpfController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    cepController.dispose();
    super.dispose();
  }

  // Adicione uma chave global para o formulário
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Usuário',
            style: TextStyle(color: Colors.black)),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme:
            IconThemeData(color: Colors.black), // Define a cor do ícone de voltar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Associe a chave ao Form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Preencha seus dados",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 24),
              Text("Email: ${widget.email}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Senha",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma senha.';
                  } else if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: "Nome Completo",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome completo.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: cpfController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "CPF",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu CPF.';
                  }
                  // Adicione validação de formato de CPF se necessário
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Telefone",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu telefone.';
                  }
                  // Adicione validação de número de telefone se necessário
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: "Endereço",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu endereço.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: cepController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "CEP",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu CEP.';
                  }
                  // Adicione validação de CEP se necessário
                  return null;
                },
              ),
              SizedBox(height: 24),
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () {
                        // Validar os campos antes de enviar
                        if (_formKey.currentState!.validate()) {
                          registerUser();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child:
                          Text("Registrar", style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
