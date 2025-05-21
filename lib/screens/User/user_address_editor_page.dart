import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class UserAddressEditorPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(Map<String, dynamic>) onSave;

  const UserAddressEditorPage({
    Key? key,
    required this.userData,
    required this.onSave,
  }) : super(key: key);

  @override
  State<UserAddressEditorPage> createState() => _UserAddressEditorPageState();
}

class _UserAddressEditorPageState extends State<UserAddressEditorPage> {
  late TextEditingController _cepController;
  late TextEditingController _logradouroController;
  late TextEditingController _numeroController;
  late TextEditingController _complementoController;
  late TextEditingController _accessTokenController;

  bool _isLoading = false;
  final _cepMask = MaskTextInputFormatter(mask: '#####-###');

  @override
  void initState() {
    super.initState();

    final endereco = widget.userData?['endereco'] ?? {};

    _cepController = TextEditingController(text: endereco['cep'] ?? '');
    _logradouroController =
        TextEditingController(text: endereco['logradouro'] ?? '');
    _numeroController = TextEditingController(text: endereco['numero'] ?? '');
    _complementoController =
        TextEditingController(text: endereco['complemento'] ?? '');
    _accessTokenController = TextEditingController();

    _cepController.addListener(_onCepChanged);

    // Se for vendedor, buscar o access_token
    if (((widget.userData?['usuario'] ?? {})['Usuario_Tipo'] ?? 'customer') !=
        'customer') {
      _initAccessToken(widget.userData ?? {});
    }
  }

  void _initAccessToken(Map<String, dynamic> storeData) async {
    if (storeData.containsKey('access_token')) {
      _accessTokenController.text = storeData['access_token'];
    } else if (storeData['endereco'] != null &&
        storeData['endereco'].containsKey('access_token')) {
      _accessTokenController.text = storeData['endereco']['access_token'];
    } else if (storeData['endereco'] != null &&
        storeData['endereco']['id_Endereco'] != null) {
      await _fetchAccessToken(storeData['endereco']['id_Endereco'].toString());
    }
  }

  Future<void> _fetchAccessToken(String idEndereco) async {
    try {
      final url = Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetAddressById?id_Endereco=$idEndereco');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['endereco'] != null &&
            data['endereco']['access_token'] != null) {
          setState(() {
            _accessTokenController.text = data['endereco']['access_token'];
            widget.userData?['endereco']['access_token'] =
                data['endereco']['access_token'];
          });
        }
      }
    } catch (e) {
      print('Erro ao buscar token: $e');
    }
  }

  Future<void> _onCepChanged() async {
    final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');

    if (cep.length == 8) {
      final response =
          await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!data.containsKey('erro')) {
          setState(() {
            _logradouroController.text = data['logradouro'] ?? '';
          });
        }
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final usuario = widget.userData?['usuario'] ?? {};
      final endereco = widget.userData?['endereco'] ?? {};

      final idEnderecoRaw = endereco['id_Endereco'];
      final int? parsedId = idEnderecoRaw is int
          ? idEnderecoRaw
          : int.tryParse(idEnderecoRaw.toString());
      if (parsedId == null) {
        throw Exception("ID do endereço inválido");
      }
      final int idEndereco = parsedId;

      final Map<String, dynamic> requestBody = {
        "Usuario_Tipo": usuario['Usuario_Tipo'] ?? 'customer',
        "id_Endereco": idEndereco,
        "cep": _cepController.text.trim(),
        "logradouro": _logradouroController.text.trim(),
        "numero": _numeroController.text.trim(),
        "complemento": _complementoController.text.trim(),
      };

      if (requestBody['Usuario_Tipo'] != 'customer') {
        final String nomeLoja = endereco['nome_Loja']?.toString() ?? '';
        final String descricaoLoja =
            endereco['descricao_Loja']?.toString() ?? '';
        final String tipoEntrega = endereco['tipo_Entrega']?.toString() ?? '';
        final String idImagem = endereco['id_Imagem']?.toString() ?? '';
        final String accessToken = _accessTokenController.text;

        if (nomeLoja.isEmpty || descricaoLoja.isEmpty || tipoEntrega.isEmpty) {
          throw Exception("Dados incompletos da loja. Contate o suporte.");
        }

        requestBody.addAll({
          "nome_Loja": nomeLoja,
          "descricao_Loja": descricaoLoja,
          "id_Imagem": idImagem,
          "tipo_Entrega": tipoEntrega,
          "access_token": accessToken,
        });
      }

      final response = await http.put(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateAddress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> updatedData = {
          'usuario': usuario,
          'endereco': {
            'id_Endereco': idEndereco,
            'cep': _cepController.text,
            'logradouro': _logradouroController.text,
            'numero': _numeroController.text,
            'complemento': _complementoController.text,
          },
        };

        widget.onSave(updatedData);
        Navigator.pop(context);
      } else {
        final resBody = jsonDecode(response.body);
        throw Exception(resBody['message'] ?? 'Erro ao salvar alterações');
      }
    } catch (e, stacktrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
      print("❌ Erro ao salvar:");
      print(e);
      print(stacktrace);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _accessTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFbbc2c);
    final usuario = widget.userData?['usuario'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Endereço'),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextFormField(
              controller: _cepController,
              inputFormatters: [_cepMask],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CEP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _logradouroController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Logradouro',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _numeroController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _complementoController,
                    decoration: const InputDecoration(
                      labelText: 'Complemento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SALVAR ALTERAÇÕES',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
