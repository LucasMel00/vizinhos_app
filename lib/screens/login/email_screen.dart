import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/login/registration_screen.dart';
import 'login_email_screen.dart';

class EmailScreen extends StatefulWidget {
  @override
  _EmailScreenState createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _checkEmail(BuildContext context, String email) async {
    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/email/$email');

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] == 'Usuário encontrado') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginEmailScreen(email: email),
            ),
          );
        } else {
          _navigateToRegistration(email);
        }
      } else if (response.statusCode == 404) {
        _navigateToRegistration(email);
      } else {
        setState(() {
          _errorText = "Erro inesperado. Tente novamente mais tarde.";
        });
      }
    } on http.ClientException {
      setState(() {
        _errorText = "Erro de conexão. Verifique sua internet.";
      });
    } on TimeoutException {
      setState(() {
        _errorText = "Tempo de conexão esgotado. Tente novamente.";
      });
    } catch (e) {
      setState(() {
        _errorText = "Erro desconhecido. Tente novamente.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToRegistration(String email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationScreen(email: email),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Verifique seu Email 📬",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enviamos um link de confirmação para seu email.",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("Por favor, verifique sua caixa de entrada.",
                style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK",
                style:
                    TextStyle(color: const Color.fromARGB(255, 68, 255, 96))),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 48),
                _buildEmailField(),
                if (_errorText != null) _buildErrorText(),
                SizedBox(height: 32),
                _buildContinueButton(),
                SizedBox(height: 24),
                _buildFooterText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.people_alt_rounded,
            size: 48, color: const Color(0xFFFbbc2c)),
        SizedBox(height: 24),
        Text("Bem-vindo ao Vizinhos App!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            )),
        SizedBox(height: 12),
        Text("Insira seu email para continuar",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            )),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: [AutofillHints.email],
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: "Email",
        prefixIcon: Icon(Icons.email_rounded, color: Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Por favor, insira seu email";
        }
        if (!RegExp(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")
            .hasMatch(value)) {
          return "Email inválido";
        }
        return null;
      },
    );
  }

  Widget _buildErrorText() {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        _errorText!,
        style: TextStyle(color: Colors.red[700], fontSize: 14),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  FocusScope.of(context).unfocus();
                  _checkEmail(context, _emailController.text.trim());
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFbbc2c),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                "Continuar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildFooterText() {
    return Center(
      child: Text.rich(
        TextSpan(
          text: "Ao continuar, você concorda com nossos ",
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
          children: [
            TextSpan(
              text: "Termos de Serviço",
              style: TextStyle(
                color: const Color(0xFFFbbc2c),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: " e "),
            TextSpan(
              text: "Política de Privacidade",
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
