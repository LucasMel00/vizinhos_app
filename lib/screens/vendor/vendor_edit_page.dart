import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:vizinhos_app/screens/User/user_account_page.dart';

class VendorEditPage extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  final Map<String, dynamic> storeData;
  final Function(Map<String, dynamic>) onSave;

  const VendorEditPage({
    Key? key,
    required this.userInfo,
    required this.storeData,
    required this.onSave,
  }) : super(key: key);

  @override
  _VendorEditPageState createState() => _VendorEditPageState();
}

class _VendorEditPageState extends State<VendorEditPage> {
  late Map<String, dynamic> storeData;
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  String? newImageBase64;
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    storeData = widget.storeData;
    nameController = TextEditingController(
      text: storeData['endereco']['nome_Loja'] ?? '',
    );
    descriptionController = TextEditingController(
      text: storeData['endereco']['descricao_Loja'] ?? '',
    );
  }

  Future<void> saveData() async {
    setState(() => isLoading = true);

    try {
      Map<String, dynamic> updatedBody = {
        "id_Endereco":
            int.parse(storeData['endereco']['id_Endereco'].toString()),
        "cep": storeData['endereco']['cep'] ?? '',
        "logradouro": storeData['endereco']['logradouro'] ?? '',
        "numero": storeData['endereco']['numero'] ?? '',
        "complemento": storeData['endereco']['complemento'] ?? '',
        "nome_Loja": nameController.text,
        "descricao_Loja": descriptionController.text,
        "id_Imagem": newImageBase64 ?? storeData['endereco']['id_Imagem'] ?? '',
        "tipo_Entrega": storeData['endereco']['tipo_Entrega'] ?? '',
        "Usuario_Tipo": "seller",
      };

      final response = await http.put(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateAddress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedBody),
      );

      if (response.statusCode == 200) {
        widget.onSave(updatedBody);
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) =>
                UserAccountPage(
              userInfo: widget.userInfo,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      } else {
        throw Exception('Erro ao salvar alterações: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        newImageBase64 = base64Encode(bytes);
      });
    }
  }

  Widget _buildImageWidget() {
    if (newImageBase64 != null) {
      return ClipOval(
        child: Image.memory(
          base64Decode(newImageBase64!),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (storeData['endereco']['id_Imagem'] != null &&
        storeData['endereco']['id_Imagem'].isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          base64Decode(storeData['endereco']['id_Imagem']),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.store, size: 40, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFbbc2c);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Loja"),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: _buildImageWidget(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Alterar imagem',
                          style: TextStyle(
                            color: primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Nome da Loja', style: textTheme.bodyMedium),
                const SizedBox(height: 4),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Digite o nome da loja',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Descrição', style: textTheme.bodyMedium),
                const SizedBox(height: 4),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Descreva sua loja',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'SALVAR ALTERAÇÕES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
