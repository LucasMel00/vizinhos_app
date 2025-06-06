import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/user/user_account_page.dart';
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
  final TextEditingController accessTokenController = TextEditingController();
  String selectedDeliveryType = 'Delivery';
  String? newImageBase64;
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    print('Debug: Entrando no initState');
    // Clona o map para não mexer no original direto
    storeData = Map<String, dynamic>.from(widget.storeData);

    // Garante que 'loja' existe e preenche campos faltantes a partir de 'endereco'
    if (storeData['loja'] == null) {
      storeData['loja'] = <String, dynamic>{};
    }

    if (storeData['endereco'] != null) {
      storeData['loja']['id_Endereco'] ??= storeData['endereco']['id_Endereco'];
      storeData['loja']['nome_Loja'] ??= storeData['endereco']['nome_Loja'];
      storeData['loja']['descricao_Loja'] ??= storeData['endereco']['descricao_Loja'];
      storeData['loja']['tipo_Entrega'] ??= storeData['endereco']['tipo_Entrega'];
      storeData['loja']['id_Imagem'] ??= storeData['endereco']['id_Imagem'];
      storeData['loja']['access_token'] ??= storeData['endereco']['access_token'];
    }

    // Logs para depuração
    print('Estrutura completa do storeData após initState: $storeData');

    // Atualiza os controllers com valores vindos de storeData
    nameController.text = storeData['loja']['nome_Loja'] ?? '';
    descriptionController.text = storeData['loja']['descricao_Loja'] ?? '';
    selectedDeliveryType =
        storeData['loja']['tipo_Entrega'] as String? ?? 'Delivery';

    // Inicializa o token
    if (storeData['loja']?['access_token'] != null) {
      accessTokenController.text = storeData['loja']['access_token'];
    } else {
      print('Debug: Token não encontrado na estrutura esperada');
    }
  }

  // Função para buscar o token diretamente da API
  Future<void> _fetchAccessToken(String idEndereco) async {
    try {
      final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetAddressById?id_Endereco=$idEndereco',
      );
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        print('Resposta da API: $data');
        if (data['endereco'] != null &&
            data['endereco']['access_token'] != null) {
          setState(() {
            accessTokenController.text = data['endereco']['access_token'];
            // Atualiza também no storeData para uso posterior
            storeData['endereco']['access_token'] =
                data['endereco']['access_token'];
          });
          print('Token buscado da API: ${data['endereco']['access_token']}');
        }
      }
    } catch (e) {
      print('Erro ao buscar token: $e');
    }
  }

  Future<void> _fetchEnderecoData(String idEndereco) async {
    try {
      final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetAddressById?id_Endereco=$idEndereco',
      );
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        print('Resposta da API para endereço: $data');
        if (data['endereco'] != null) {
          setState(() {
            storeData['endereco'] = data['endereco'];
          });
          print('Debug: Dados do endereço atualizados: ${storeData['endereco']}');
        } else {
          print('Debug: Dados do endereço não encontrados na resposta da API.');
        }
      } else {
        print('Debug: Falha ao buscar dados do endereço. Status: ${resp.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar dados do endereço: $e');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    accessTokenController.dispose();
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
      if (storeData['endereco'] == null || storeData['endereco'].isEmpty) {
        print('Debug: storeData["endereco"] está nulo ou vazio. Não é possível salvar.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Endereço não encontrado ou incompleto.')),
        );
        setState(() => isLoading = false);
        return;
      }

      final requiredFields = ['id_Endereco', 'cep', 'logradouro', 'numero'];
      for (var field in requiredFields) {
        if (storeData['endereco'][field] == null || storeData['endereco'][field].toString().isEmpty) {
          print('Debug: Campo obrigatório "$field" está ausente ou vazio em storeData["endereco"].');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: Campo "$field" está ausente ou vazio.')),
          );
          setState(() => isLoading = false);
          return;
        }
      }

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
        'access_token': accessTokenController.text,
        'Usuario_Tipo': 'seller',
      };

      print('Debug: Dados preparados para envio: $updatedBody');

      final resp = await http.put(
        Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateAddress',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedBody),
      );

      print('Debug: Resposta da API: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        widget.onSave(updatedBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
        content: Text(
          'Dados da loja atualizados com sucesso!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
          ),
        );
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
      print('Debug: Erro ao salvar: $e');
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
    final idImg = storeData['loja']?['id_Imagem'];
    if (idImg != null && idImg.toString().isNotEmpty) {
      final url = 'https://loja-profile-pictures.s3.amazonaws.com/$idImg';
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
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 240, 240, 240)),
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
                const SizedBox(height: 16),

                // Campo para exibir o access token (somente leitura)
                Text('Access Token', style: textTheme.bodyLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: accessTokenController,
                  readOnly: true, // Impede edição
                  enabled: false, // Desabilita o campo visualmente
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.grey[200],
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.copy, color: AppTheme.primaryColor),
                      onPressed: () {
                        // Copia o token para a área de transferência
                        final token = accessTokenController.text;
                        if (token.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: token));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Token copiado para a área de transferência')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Token não disponível para cópia')),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este token é somente para visualização e não pode ser editado.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
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
