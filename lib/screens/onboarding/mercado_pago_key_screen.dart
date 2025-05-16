import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class MercadoPagoKeyScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  const MercadoPagoKeyScreen({Key? key, this.onFinish}) : super(key: key);

  @override
  State<MercadoPagoKeyScreen> createState() => _MercadoPagoKeyScreenState();
}

class _MercadoPagoKeyScreenState extends State<MercadoPagoKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mercadoPagoKeyController = TextEditingController();
  static const String mercadoPagoKeyPref = 'mercadoPagoKey'; // Changed to access_token for clarity
  static const String mercadoPagoKeySkippedPref = 'mercadoPagoKeySkipped';

  Future<void> _saveMercadoPagoKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(mercadoPagoKeyPref, key);
    await prefs.setBool(mercadoPagoKeySkippedPref, false);
  }

  Future<void> _setSkippedPreference(bool skipped) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(mercadoPagoKeySkippedPref, skipped);
  }

  void _submitKey() async {
    if (_formKey.currentState!.validate()) {
      await _saveMercadoPagoKey(_mercadoPagoKeyController.text);
      print('Chave (Access Token) Mercado Pago salva: ${_mercadoPagoKeyController.text}');
      
      if (widget.onFinish != null) {
        widget.onFinish!();
      } else {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _skipAndFinish() async {
    await _setSkippedPreference(true);
    print('Cadastro da chave Mercado Pago adiado.');
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Log or show an error if the URL can't be launched
      print('Could not launch $url');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o link: $url')),
      );
    }
  }

  @override
  void dispose() {
    _mercadoPagoKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFbbc2c);
    const mercadoPagoTutorialUrl = 'https://www.mercadopago.com.br/developers/pt/docs/your-integrations/credentials';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Access Token Mercado Pago'), // Updated title
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key_outlined, size: 80, color: primaryColor),
                const SizedBox(height: 24),
                Text(
                  'Cadastre seu Access Token',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Informe seu Access Token de Produção do Mercado Pago para processar os pagamentos das suas vendas. Este token é essencial para a integração.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _mercadoPagoKeyController,
                  decoration: InputDecoration(
                    labelText: 'Access Token de Produção',
                    hintText: 'APP_USR-xxxxxxx-xxxxxx-xxxxxx',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    prefixIcon:                 Icon(Icons.vpn_key_outlined, size: 20, color: primaryColor),

                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu Access Token.';
                    }
                    if (!value.startsWith('APP_USR-')) {
                      return 'Formato de Access Token inválido.';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.text,
                  obscureText: true, // Good practice for tokens
                ),
                const SizedBox(height: -0),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => _launchURL(mercadoPagoTutorialUrl),
                    child: Text(
                      'Onde encontrar meu Access Token?',
                      style: TextStyle(color: primaryColor, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Salvar Access Token',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _skipAndFinish,
                  child: Text(
                    'Cadastrar depois',
                    style: TextStyle(color: primaryColor, fontSize: 14),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

