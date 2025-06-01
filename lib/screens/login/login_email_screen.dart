import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/user/home_page_user.dart';
import 'package:vizinhos_app/screens/login/email_screen.dart';
import 'package:vizinhos_app/screens/login/code_password_page.dart'
    hide ForgotPasswordPage;
import 'package:vizinhos_app/screens/login/reset_code_page.dart';
import 'package:vizinhos_app/screens/login/reset_password_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_subscription_screen.dart';
import 'package:vizinhos_app/screens/vendor/vendor_subscription_screen_new.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

class LoginEmailScreen extends StatefulWidget {
  final String email;

  const LoginEmailScreen({required this.email});

  @override
  _LoginEmailScreenState createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _needsSubscriptionPayment = false;
  final storage = FlutterSecureStorage();  Future<Map<String, dynamic>> _checkVendorSubscriptionStatus() async {
    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/RefreshVendorSubscriptionStatus?email=${Uri.encodeComponent(widget.email)}');

    try {
      print("Verificando status da assinatura do vendedor para: ${widget.email}");
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
      ).timeout(const Duration(seconds: 15));

      print("Status da verificação de assinatura: ${response.statusCode}");
      print("Resposta da verificação: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final status = responseData['status_plano'];
        
        print("Status do plano do vendedor: $status");
        
        // Verifica se o status é "Pago"
        return {
          'canLogin': status == 'Pago',
          'isVendor': true,
          'needsPayment': status != 'Pago'
        };
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? '';
        
        print("Erro 400 na verificação de assinatura: $message");
        
        // Se o usuário não é um vendedor, permite continuar (é um cliente comum)
        if (message.contains('não é um vendedor') || 
            message.contains('Vendedor não encontrado')) {
          print("Usuário é cliente comum, permitindo login");
          return {
            'canLogin': true,
            'isVendor': false,
            'needsPayment': false
          };
        }
        
        // Para outros erros 400, bloqueia o login
        return {
          'canLogin': false,
          'isVendor': true,
          'needsPayment': true
        };
      } else {
        print("Erro HTTP ao verificar status da assinatura: ${response.statusCode}");
        return {
          'canLogin': false,
          'isVendor': true,
          'needsPayment': true
        };
      }
    } catch (e) {
      print("Erro na verificação do status da assinatura: $e");
      // Em caso de erro de rede, permite o login como fallback
      // mas apenas para evitar bloquear usuários em caso de problemas temporários
      return {
        'canLogin': true,
        'isVendor': false,
        'needsPayment': false
      };
    }
  }

  Future<void> _loginUser(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });    print("Iniciando login para o usuário: ${widget.email}");

    // Primeiro, verifica o status da assinatura do vendedor
    final subscriptionResult = await _checkVendorSubscriptionStatus();
    
    if (!subscriptionResult['canLogin']) {
      setState(() {
        _isLoading = false;
        _needsSubscriptionPayment = subscriptionResult['needsPayment'];
        _errorMessage = 'Sua assinatura de vendedor não está ativa ou há pendências de pagamento. Complete o pagamento para continuar.';
      });
      print("Login bloqueado: assinatura do vendedor não está ativa");
      return;
    }

    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/LoginUser');

    print("Status da assinatura verificado com sucesso, prosseguindo com login");

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            body: jsonEncode({
              'email': widget.email,
              'senha': _passwordController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      print("Resposta recebida: ${response.statusCode}");

      final responseData = jsonDecode(response.body);
      print("Resposta decodificada: $responseData");

      if (response.statusCode == 200) {
        // Armazena os tokens com as chaves corretas (use EXATAMENTE a mesma capitalização da API)
        await storage.write(
            key: 'accessToken', value: responseData['AccessToken']);
        await storage.write(key: 'idToken', value: responseData['idToken']);
        await storage.write(
            key: 'refreshToken', value: responseData['refreshToken']);
        await storage.write(
            key: 'expiresIn', value: responseData['expiresIn'].toString());
        await storage.write(key: 'email', value: widget.email);

        // Atualiza também o estado no AuthProvider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.login(
          accessToken: responseData['AccessToken'],
          idToken: responseData['idToken'],
          refreshToken: responseData['refreshToken'],
          expiresIn: int.parse(responseData['expiresIn'].toString()),
          email: widget.email,
        );

        print("Tokens armazenados com sucesso");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        setState(() {
          _errorMessage = responseData['error'] ??
              'Erro ao fazer login, verifique se confirmou a conta em seu email.';
        });
        print("Erro de login: ${responseData['error']}");
      }
    } on http.ClientException {
      setState(() => _errorMessage = 'Erro de conexão');
      print("Erro de conexão");
    } on TimeoutException {
      setState(() => _errorMessage = 'Tempo esgotado');
      print("Tempo de requisição esgotado");
    } catch (e) {
      setState(() => _errorMessage = 'Erro inesperado');
      print("Erro inesperado: $e");
    } finally {
      setState(() => _isLoading = false);
      print("Processo de login finalizado");
    }  }  void _navigateToSubscriptionPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorSubscriptionScreen(email: widget.email),
      ),
    );
  }

  // Método para recuperar tokens armazenados (para debug)
  Future<Map<String, String>> getStoredTokens() async {
    final accessToken = await storage.read(key: 'accessToken');
    final idToken = await storage.read(key: 'idToken');
    final refreshToken = await storage.read(key: 'refreshToken');
    final expiresIn = await storage.read(key: 'expiresIn');

    print(
        "Tokens recuperados: $accessToken, $idToken, $refreshToken, $expiresIn");

    return {
      'accessToken': accessToken ?? '',
      'idToken': idToken ?? '',
      'refreshToken': refreshToken ?? '',
      'expiresIn': expiresIn ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Color(0xFFFbbc2c)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EmailScreen()),
            ),
          ),
        ),
        body: Container(
          color: Colors.white,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 40),
                    _buildPasswordField(),
                    if (_errorMessage != null) ...[
                      SizedBox(height: 16),
                      _buildError(),
                    ],
                    SizedBox(height: 24),
                    _buildLoginButton(),
                    _buildForgotPassword(),
                  ],
                ),
              ),
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
        Icon(Icons.person, size: 60, color: Color(0xFFFbbc2c)),
        SizedBox(height: 24),
        Text(
          'Bem-vindo Vizinhos!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(206, 58, 58, 58),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Faça login para continuar',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 238, 231, 213),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.email,
            style: TextStyle(
              color: Color.fromARGB(255, 221, 156, 3),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Senha',
        prefixIcon: Icon(Icons.lock_outline_rounded, color: Color(0xFFFbbc2c)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Color(0xFFFbbc2c),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color.fromARGB(255, 250, 235, 202),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Digite sua senha';
        return null;
      },
    );
  }  Widget _buildError() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red[800]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[800]),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () {
          if (_needsSubscriptionPayment) {
            _navigateToSubscriptionPayment();
          } else {
            _loginUser(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFbbc2c),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 18),
          elevation: 2,
          shadowColor: Color(0xFFFbbc2c),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_needsSubscriptionPayment) 
                    Icon(Icons.payment, color: Colors.white, size: 20),
                  if (_needsSubscriptionPayment) SizedBox(width: 8),
                  Text(
                    _needsSubscriptionPayment ? 'Ir ao Pagamento' : 'Entrar',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ForgotPasswordPage(userEmail: widget.email),
                ),
              );
            },
      child: Text(
        'Esqueceu a senha?',
        style: TextStyle(
          color: Color.fromARGB(255, 204, 145, 7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
