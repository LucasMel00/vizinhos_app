import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/login/reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String userEmail;
  const ForgotPasswordPage({super.key, required this.userEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.userEmail;
  }

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _message = 'Por favor, preencha o e-mail.');
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/RequestPasswordChange',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetCodePage(email: email),
          ),
        );
      } else {
        final responseBody = jsonDecode(response.body);
        setState(() => _message = 'Erro: ${responseBody['message']}');
      }
    } catch (e) {
      setState(() => _message = 'Erro de conexão: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redefinir Senha'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: theme.primaryColor.withOpacity(0.3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Icon(Icons.lock_reset_rounded,
                size: 120, color: theme.primaryColor),
            const SizedBox(height: 32),
            Text(
              'Esqueceu sua senha?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Digite seu e-mail cadastrado e enviaremos um código para redefinir sua senha',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon:
                      Icon(Icons.email_rounded, color: theme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _requestPasswordReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: theme.primaryColor,
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 24),
                label: Text(
                  _loading ? 'Enviando...' : 'Enviar Código',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_message != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message!.toLowerCase().contains('erro')
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _message!.toLowerCase().contains('erro')
                        ? Colors.red[100]!
                        : Colors.green[100]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _message!.toLowerCase().contains('erro')
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_rounded,
                      color: _message!.toLowerCase().contains('erro')
                          ? Colors.red[800]
                          : Colors.green[800],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _message!.toLowerCase().contains('erro')
                              ? Colors.red[800]
                              : Colors.green[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
