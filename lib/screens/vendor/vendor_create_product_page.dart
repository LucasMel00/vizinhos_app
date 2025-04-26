import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:vizinhos_app/screens/vendor/vendor_products_page.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

final primaryColor = const Color(0xFFFbbc2c);

class Caracteristica {
  final String id;
  final String descricao;

  Caracteristica({required this.id, required this.descricao});

  factory Caracteristica.fromJson(Map<String, dynamic> json) {
    return Caracteristica(
      id: json['id_Caracteristica'],
      descricao: json['descricao'],
    );
  }
}

class CreateProductScreen extends StatefulWidget {
  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers com máscara monetária
  final priceController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
  );
  final discountController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
  );
  final costController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
  );

  // Demais controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final validityController = TextEditingController();

  String category = 'Doce';
  File? selectedImage;
  String? base64Image;

  // Lista dinâmica de características carregada da API
  List<Caracteristica> caracteristicas = [];
  List<String> selectedCharacteristics = [];
  bool _isLoading = false;
  bool _loadingChars = true;

  @override
  void initState() {
    super.initState();
    _fetchCaracteristicas();
  }

  Future<void> _fetchCaracteristicas() async {
    try {
      final uri = Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetCharacteristics');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['caracteristicas'];
        setState(() {
          caracteristicas =
              list.map((json) => Caracteristica.fromJson(json)).toList();
          _loadingChars = false;
        });
      } else {
        throw Exception('Falha ao carregar características');
      }
    } catch (e) {
      // opcional: exibir erro
      setState(() => _loadingChars = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar características: $e')),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    discountController.dispose();
    costController.dispose();
    validityController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
      final bytes = await pickedFile.readAsBytes();
      base64Image = base64Encode(bytes);
    }
  }

  Future<void> submitProduct() async {
    if (!_validatePrices()) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enderecoId = int.tryParse(authProvider.idEndereco ?? '') ?? 0;

    final uri = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/CreateProduct');

    final body = {
      "nome": nameController.text,
      "fk_id_Endereco": enderecoId,
      "fk_id_Categoria": getCategoryId(),
      "dias_vcto": int.tryParse(validityController.text) ?? 0,
      "valor_venda": _parseCurrency(priceController.text),
      "valor_custo": _parseCurrency(costController.text),
      "tamanho": "único",
      "descricao": descriptionController.text,
      "id_imagem": base64Image ?? "",
      "disponivel": true,
      "caracteristicas_IDs": selectedCharacteristics,
    };

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.accessToken}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto criado com sucesso!')),
        );
        // Navegação usando MaterialPageRoute
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VendorProductsPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar produto: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _parseCurrency(String value) {
    return double.tryParse(value
            .replaceAll('R\$ ', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')) ??
        0.0;
  }

  bool _validatePrices() {
    final price = _parseCurrency(priceController.text);
    final discount = _parseCurrency(discountController.text);

    if (discount > price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('O desconto não pode ser maior que o preço')),
      );
      return false;
    }
    return true;
  }

  int getCategoryId() {
    switch (category) {
      case 'Doce':
        return 188564336962606369;
      case 'Salgado':
        return 303744449465944688;
      case 'Bebida':
        return 321601065408987139;
      default:
        return 188564336962606369;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Criar produto',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            color: primaryColor,
            height: 2,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção de Imagem
                  Center(
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.image,
                                  size: 40, color: Colors.grey[400]),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: primaryColor,
                            shape: const CircleBorder(),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: pickImage,
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Icons.edit,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Nome do Produto
                  TextFormField(
                    controller: nameController,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Nome do produto',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe o nome'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Descrição
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Descrição',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preço e Desconto
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Preço',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              _parseCurrency(value ?? '0') <= 0
                                  ? 'Informe o preço'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: discountController,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Desconto',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Custo
                  TextFormField(
                    controller: costController,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Custo produção',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _parseCurrency(value ?? '0') <= 0
                        ? 'Informe o custo'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Validade
                  TextFormField(
                    controller: validityController,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Dias validade',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe a validade'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Categoria
                  DropdownButtonFormField<String>(
                    value: category,
                    items: ['Doce', 'Salgado', 'Bebida']
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        category = value!;
                      });
                    },
                    decoration: inputDecoration.copyWith(
                      labelText: 'Categoria',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Características
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Características do Produto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  if (_loadingChars)
                    Center(
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(primaryColor)))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: caracteristicas.map((c) {
                        final isSelected =
                            selectedCharacteristics.contains(c.id);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(c.descricao),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedCharacteristics.add(c.id);
                              } else {
                                selectedCharacteristics.remove(c.id);
                              }
                            });
                          },
                          selectedColor: primaryColor.withOpacity(0.2),
                          checkmarkColor: primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? primaryColor : Colors.grey[700],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 32),

                  // Botão Salvar
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : submitProduct,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Salvar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
