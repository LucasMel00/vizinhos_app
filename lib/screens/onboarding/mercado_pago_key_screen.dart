import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vizinhos_app/services/secure_storage.dart';
import 'package:http/http.dart' as http;

class MercadoPagoKeyScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  final bool showAlertOnEntry;
  const MercadoPagoKeyScreen(
      {Key? key, this.onFinish, this.showAlertOnEntry = true})
      : super(key: key);

  @override
  State<MercadoPagoKeyScreen> createState() => _MercadoPagoKeyScreenState();
}

class _MercadoPagoKeyScreenState extends State<MercadoPagoKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mercadoPagoKeyController =
      TextEditingController();
  final SecureStorage _secureStorage = SecureStorage();
  bool _isLoading = false;
  bool _showTokenAlert = false;

  @override
  void initState() {
    super.initState();
    if (widget.showAlertOnEntry) {
      _checkExistingToken();
    }
  }

  Future<void> _checkExistingToken() async {
    final existingToken = await _secureStorage.getMercadoPagoToken();
    if (existingToken != null &&
        existingToken.isNotEmpty &&
        widget.showAlertOnEntry) {
      setState(() {
        _showTokenAlert = true;
      });
    }
  }

  Future<void> _saveMercadoPagoKey(String key) async {
    await _secureStorage.setMercadoPagoToken(key);
    // Quando um token é salvo, automaticamente marcamos como não pulado
    // Isso já é feito internamente no método setMercadoPagoToken
  }

  Future<void> _setSkippedPreference(bool skipped) async {
    await _secureStorage.setMercadoPagoSkipped(skipped);
  }

  void _submitKey() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _saveMercadoPagoKey(_mercadoPagoKeyController.text);
        print(
            'Chave (Access Token) Mercado Pago salva: ${_mercadoPagoKeyController.text}');

        // Enviar token para a API
        final result = await _sendTokenToApi(_mercadoPagoKeyController.text);

        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Token do Mercado Pago salvo com sucesso!')),
          );

          if (widget.onFinish != null) {
            widget.onFinish!();
          } else {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        } else {
          // Se falhou, mostra mensagem mas não impede de continuar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Erro ao enviar token para o servidor. Você pode tentar novamente mais tarde.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );

          if (widget.onFinish != null) {
            widget.onFinish!();
          } else {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<bool> _sendTokenToApi(String token) async {
    try {
      final idEndereco = await _secureStorage.getEnderecoId();
      if (idEndereco == null) {
        print('Erro: id_Loja não encontrado');
        return false;
      }

      // Construir o corpo da requisição conforme a API
      final requestBody = {'id_Loja': idEndereco, 'access_token': token};

      // Fazer a chamada POST para a API
      final response = await http.patch(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/InsertStoreAccessToken'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Requisição: ${json.encode(requestBody)}');
      print('Resposta: ${response.body}');
      // Verificar a resposta
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Token enviado com sucesso: ${responseData['message']}');
        return true;
      } else {
        print(
            'Erro ao enviar token: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro ao enviar token para API: $e');
      return false;
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
    const mercadoPagoTutorialUrl =
        'https://www.mercadopago.com.br/developers/pt/docs/your-integrations/credentials';

    if (_showTokenAlert) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Token Mercado Pago'),
          backgroundColor: primaryColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: primaryColor, size: 60),
                const SizedBox(height: 24),
                const Text(
                  'Você já possui um Access Token cadastrado.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Se desejar alterar ou visualizar, clique no botão abaixo para acessar a página de gerenciamento do token.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Gerenciar Access Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _showTokenAlert = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Access Token Mercado Pago'),
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
                    prefixIcon: Icon(Icons.vpn_key_outlined,
                        size: 20, color: primaryColor),
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
                    onPressed: _isLoading ? null : _submitKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Salvando...',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ],
                          )
                        : const Text(
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
                  onPressed: _isLoading ? null : _skipAndFinish,
                  child: Text(
                    'Cadastrar depois',
                    style: TextStyle(
                        color: _isLoading ? Colors.grey : primaryColor,
                        fontSize: 14),
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
