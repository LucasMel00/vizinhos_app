import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/login/email_screen.dart';

class ResetCodePage extends StatefulWidget {
  final String email;

  const ResetCodePage({Key? key, required this.email}) : super(key: key);

  @override
  _ResetCodePageState createState() => _ResetCodePageState();
}

class _ResetCodePageState extends State<ResetCodePage> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _message;
  Color _messageColor = Colors.red;
  bool _obscurePassword = true;

  Future<void> _changePassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();

    if (code.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Preencha todos os campos.';
        _messageColor = Colors.red;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/ChangeUserPassword');

    final bodyData = {
      "email": widget.email,
      "confirmation_code": code,
      "new_password": password,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _message = 'Senha redefinida com sucesso!';
          _messageColor = Colors.green;
        });

        // Mostra o SnackBar de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(child: Text('Senha redefinida com sucesso!')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        // Aguarda o SnackBar aparecer antes de navegar
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailScreen(),
            ),
          );
        }
      } else {
        String errorMsg = responseBody['message'] ?? 'Erro desconhecido';
        // Sanitiza erro para código inválido/expirado
        if (errorMsg.contains('ExpiredCodeException') ||
            errorMsg.contains('Invalid code provided')) {
          errorMsg = 'Código inválido ou incorreto';
        }
        setState(() {
          _message = errorMsg;
          _messageColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Erro ao conectar: $e';
        _messageColor = Colors.red;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Redefinir Senha'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_reset, size: 48, color: theme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Digite o código enviado para seu e-mail e escolha uma nova senha.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Código de Verificação',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Nova Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[700],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        tooltip: _obscurePassword
                            ? 'Mostrar senha'
                            : 'Esconder senha',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Confirmar Nova Senha',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 22),
                    AnimatedOpacity(
                      opacity: _message != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _messageColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
