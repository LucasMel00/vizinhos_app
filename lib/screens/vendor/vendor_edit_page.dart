import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/User/user_account_page.dart';
import 'package:vizinhos_app/services/app_theme.dart';

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
  late final Map<String, dynamic> storeData;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedDeliveryType = 'Delivery';
  String? newImageBase64;
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Clona o map para não mexer no original direto
    storeData = Map<String, dynamic>.from(widget.storeData);

    // Atualiza os controllers com valores vindos de storeData
    nameController.text = storeData['endereco']['nome_Loja'] ?? '';
    descriptionController.text = storeData['endereco']['descricao_Loja'] ?? '';
    selectedDeliveryType =
        storeData['endereco']['tipo_Entrega'] as String? ?? 'Delivery';
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    final extension = file.path.split('.').last;

    final uploadedName = await uploadImage(base64Image, extension);
    if (uploadedName != null) {
      setState(() {
        newImageBase64 = base64Image;
        storeData['endereco']['id_Imagem'] = uploadedName;
      });
    }
  }

  Future<String?> uploadImage(String base64Image, String ext) async {
    final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/SaveStoreImage',
    );
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image': base64Image,
        'file_extension': ext,
      }),
    );
    if (resp.statusCode == 200) {
      final map = jsonDecode(resp.body);
      return map['file_name'] as String?;
    } else {
      debugPrint('Erro upload imagem: ${resp.body}');
      return null;
    }
  }

  Future<void> saveData() async {
    setState(() => isLoading = true);

   try {
      final updatedBody = {
      'id_Endereco': int.parse(storeData['endereco']['id_Endereco'].toString()),
      'cep': storeData['endereco']['cep'] ?? '',
      'logradouro': storeData['endereco']['logradouro'] ?? '',
      'numero': storeData['endereco']['numero'] ?? '',
      'complemento': storeData['endereco']['complemento'] ?? '',
      'nome_Loja': nameController.text,
      'descricao_Loja': descriptionController.text,
      'tipo_Entrega': selectedDeliveryType,
      'id_Imagem': storeData['endereco']['id_Imagem'] ?? '',
      'Usuario_Tipo': 'seller',
      };


      final resp = await http.put(
        Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateAddress',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedBody),
      );

      if (resp.statusCode == 200) {
        widget.onSave(updatedBody);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: UserAccountPage(userInfo: widget.userInfo),
            ),
          ),
        );
      } else {
        throw Exception('Status ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => isLoading = false);
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
    }
    final idImg = storeData['endereco']['id_Imagem'];
    if (idImg != null && idImg.toString().isNotEmpty) {
      final url =
          'https://loja-profile-pictures.s3.amazonaws.com/$idImg';
      return ClipOval(
        child: Image.network(
          url,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            child: Icon(Icons.store, size: 40, color: Colors.grey),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[200],
      child: Icon(Icons.store, size: 40, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFbbc2c);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Loja'),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 240, 240, 240)),
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
                          duration: const Duration(milliseconds: 300),
                          child: _buildImageWidget(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Alterar imagem',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Nome da Loja', style: textTheme.bodyLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Digite o nome da loja',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Descrição', style: textTheme.bodyLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Descreva sua loja',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Tipo de Entrega', style: textTheme.bodyLarge),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedDeliveryType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Delivery',
                      child: Text('Delivery'),
                    ),
                    DropdownMenuItem(
                      value: 'Retirada no local',
                      child: Text('Retirada no local'),
                    ),
                  ],
                  onChanged: isLoading
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() => selectedDeliveryType = v);
                          }
                        },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'SALVAR ALTERAÇÕES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
