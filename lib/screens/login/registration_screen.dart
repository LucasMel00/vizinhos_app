import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:vizinhos_app/screens/login/login_email_screen.dart';

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
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();

  // Máscaras de entrada
  final cpfMaskFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final cepMaskFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+55 (##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    initialText: '+55 ',
  );

  int _currentStep = 0;
  bool isLoading = false;

  // Função para registrar o usuário
  Future<void> registerUser() async {
    // Validação do CPF
    String cpf = cpfController.text.trim();
    if (!isValidCPF(cpf)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("CPF inválido. Por favor, verifique.")),
      );
      return;
    }

    //url para ir ao registrar o usuário
    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/register');

    setState(() {
      isLoading = true;
    });

    // Remover formatação de CPF, CEP e telefone
    String cpfNumeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    String cep = cepController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    String phoneNumber =
        phoneNumberController.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');

    // Dados a serem enviados para a API
    final body = {
      'email': widget.email,
      'password': passwordController.text.trim(),
      'name': fullNameController.text.trim(),
      'cpf': cpfNumeros,
      'phone_number': phoneNumber,
      'address': addressController.text.trim(),
      'cep': cep,
      'city': cityController.text.trim(),
      'state': stateController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        // Registro bem-sucedido
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Usuário registrado com sucesso.")),
        );
        // Navega para a tela de login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => LoginEmailScreen(email: widget.email)),
        );
      } else {
        // Registro falhou
        final data = jsonDecode(response.body);
        String errorMessage = data['error'] ?? 'Erro ao registrar usuário.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro de conexão: $e")),
      );
    }
  }

  // Função para buscar o endereço pelo CEP
  Future<void> fetchAddressByCep() async {
    String cep = cepController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.isEmpty || cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira um CEP válido.')),
      );
      return;
    }

    try {
      final response =
          await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('erro')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('CEP não encontrado.')),
          );
          return;
        }
        setState(() {
          addressController.text = data['logradouro'] ?? '';
          cityController.text = data['localidade'] ?? '';
          stateController.text = data['uf'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar o endereço.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão ao buscar o CEP.')),
      );
    }
  }

  // Função chamada ao avançar para a próxima etapa do Stepper
  void onStepContinue() {
    if (_currentStep == 0) {
      if (fullNameController.text.isEmpty || cpfController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Por favor, preencha todas as informações pessoais.')),
        );
        return;
      }
      // Validação adicional do CPF pode ser adicionada aqui se preferir validar nesta etapa
    } else if (_currentStep == 1) {
      if (cepController.text.isEmpty || addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, preencha os campos de endereço.')),
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (passwordController.text.isEmpty ||
          phoneNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Por favor, preencha todos os campos de contato.')),
        );
        return;
      }
      registerUser(); // Submete o formulário
      return; // Evita avançar o step após submissão
    }

    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
      }
    });
  }

  // Função chamada ao cancelar a etapa do Stepper
  void onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  // Função para validar CPF
  bool isValidCPF(String cpf) {
    // Remove caracteres não numéricos
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Verifica se o CPF tem 11 dígitos
    if (cpf.length != 11) return false;

    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    // Valida o primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstCheck = 11 - (sum % 11);
    if (firstCheck >= 10) firstCheck = 0;
    if (firstCheck != int.parse(cpf[9])) return false;

    // Valida o segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondCheck = 11 - (sum % 11);
    if (secondCheck >= 10) secondCheck = 0;
    if (secondCheck != int.parse(cpf[10])) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Registro de Usuário',
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Stepper(
            currentStep: _currentStep,
            onStepContinue: onStepContinue,
            onStepCancel: onStepCancel,
            steps: [
              Step(
                title: Text('Informações Pessoais'),
                content: Column(
                  children: [
                    TextFormField(
                      controller: fullNameController,
                      decoration: InputDecoration(labelText: "Nome Completo"),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: cpfController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "CPF"),
                      inputFormatters: [cpfMaskFormatter],
                    ),
                  ],
                ),
              ),
              Step(
                title: Text('Endereço'),
                content: Column(
                  children: [
                    TextFormField(
                      controller: cepController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "CEP",
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: fetchAddressByCep,
                        ),
                      ),
                      inputFormatters: [cepMaskFormatter],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(labelText: "Endereço"),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: cityController,
                      decoration: InputDecoration(labelText: "Cidade"),
                      readOnly: true,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: stateController,
                      decoration: InputDecoration(labelText: "Estado"),
                      readOnly: true,
                    ),
                  ],
                ),
              ),
              Step(
                title: Text('Informações de Contato'),
                content: Column(
                  children: [
                    TextFormField(
                      controller: phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: "Telefone"),
                      inputFormatters: [phoneMaskFormatter],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "Senha"),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
