import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;

class UserProfileEditorPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(Map<String, dynamic>) onSave;

  const UserProfileEditorPage({
    Key? key,
    required this.userData,
    required this.onSave,
  }) : super(key: key);

  @override
  State<UserProfileEditorPage> createState() => _UserProfileEditorPageState();
}

class _UserProfileEditorPageState extends State<UserProfileEditorPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  final _phoneMask = MaskTextInputFormatter(mask: '(##) #####-####');

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.userData?['usuario']?['nome'] ?? '');
    _phoneController = TextEditingController(
        text: widget.userData?['usuario']?['telefone'] ?? '');
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // Prepare the payload
      final updatedData = {
        "nome": _nameController.text,
        "telefone": _phoneController.text,
        "cpf": widget.userData?['usuario']?['cpf'], // Keep the CPF as it is
        "Usuario_Tipo": widget.userData?['usuario']?['Usuario_Tipo'],
        "fk_id_Endereco": int.parse(widget.userData?['endereco']?['id_Endereco']?.toString() ?? '0'),
      };

      final response = await http.put(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateUser'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "nome": updatedData['nome'],
          "cpf": updatedData['cpf'],
          "Usuario_Tipo": updatedData['Usuario_Tipo'],
          "fk_id_Endereco": updatedData['fk_id_Endereco'],
          "telefone": updatedData['telefone'],
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        widget.onSave(updatedData); // Notify the parent widget
        Navigator.pop(context); // Go back to the previous page
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${responseBody['message']}')),
        );
      }
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
        title: const Text('Editar Perfil'),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              inputFormatters: [_phoneMask],
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
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
