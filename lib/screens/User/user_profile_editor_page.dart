import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

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
      final updatedData = {
        "usuario": {
          "nome": _nameController.text,
          "telefone": _phoneController.text,
          "email": widget.userData?['usuario']?['email'],
        },
        "endereco": widget.userData?['endereco'],
      };

      widget.onSave(updatedData);
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
