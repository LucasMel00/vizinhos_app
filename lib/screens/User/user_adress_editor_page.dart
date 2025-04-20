import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:convert';

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
  bool _isLoading = false;

  final _cepMask = MaskTextInputFormatter(mask: '#####-###');

  @override
  void initState() {
    super.initState();
    _cepController =
        TextEditingController(text: widget.userData?['endereco']?['cep'] ?? '');
    _logradouroController = TextEditingController(
        text: widget.userData?['endereco']?['logradouro'] ?? '');
    _numeroController = TextEditingController(
        text: widget.userData?['endereco']?['numero'] ?? '');
    _complementoController = TextEditingController(
        text: widget.userData?['endereco']?['complemento'] ?? '');

    _cepController.addListener(_onCepChanged);
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
      final updatedEndereco = {
        "endereco": {
          "id_Endereco": widget.userData?['endereco']?['id_Endereco'],
          "logradouro": _logradouroController.text,
          "numero": _numeroController.text,
          "complemento": _complementoController.text,
          "cep": _cepController.text,
        },
        "usuario": widget.userData?['usuario'],
      };

      widget.onSave(updatedEndereco);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFbbc2c);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Endereço'),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
