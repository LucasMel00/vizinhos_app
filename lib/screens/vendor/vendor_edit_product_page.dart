import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/model/product.dart';
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

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late MoneyMaskedTextController priceController;
  late MoneyMaskedTextController discountController;
  late MoneyMaskedTextController costController;

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController validityController;

  String category = 'Doce';
  File? selectedImage;
  String? base64Image;
  List<Caracteristica> caracteristicas = [];
  List<String> selectedCharacteristics = [];
  bool _isLoading = false;
  bool _loadingChars = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchCaracteristicas();
    selectedCharacteristics = widget.product.caracteristicasIDs;
    category = widget.product.categoria;
  }

  void _initializeControllers() {
    nameController = TextEditingController(text: widget.product.nome);
    descriptionController =
        TextEditingController(text: widget.product.descricao);
    validityController =
        TextEditingController(text: widget.product.diasValidade.toString());

    priceController = MoneyMaskedTextController(
      initialValue: widget.product.valorVenda,
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
    );

    costController = MoneyMaskedTextController(
      initialValue: widget.product.valorCusto,
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
    );

    discountController = MoneyMaskedTextController(
      initialValue: widget.product.desconto ?? 0,
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
    );
  }

  Future<void> _fetchCaracteristicas() async {
    try {
      final response = await http.get(Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetCharacteristics'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          caracteristicas = (data['caracteristicas'] as List)
              .map((json) => Caracteristica.fromJson(json))
              .toList();
          _loadingChars = false;
        });
      } else {
        throw Exception('Falha ao carregar características');
      }
    } catch (e) {
      setState(() => _loadingChars = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar características: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
      final bytes = await pickedFile.readAsBytes();
      base64Image = base64Encode(bytes);
    }
  }

  Future<void> _saveProduct() async {
    if (!_validatePrices()) return;
    if (!_formKey.currentState!.validate()) return;

    // Validação do ID do produto
    if (widget.product.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID do produto inválido')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final requestBody = {
      "id_Produto": widget.product.id, // Campo corrigido com P maiúsculo
      "nome": nameController.text,
      "fk_id_Categoria": getCategoryId(),
      "dias_vcto": int.parse(validityController.text),
      "valor_venda": _parseCurrency(priceController.text),
      "valor_custo": _parseCurrency(costController.text),
      "descricao": descriptionController.text,
      "id_imagem": base64Image ?? widget.product.imagemBase64,
      "disponivel": widget.product.disponivel,
      "caracteristicas_IDs": selectedCharacteristics,
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${authProvider.accessToken}',
    };

    try {
      final response = await http.put(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateProduct'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VendorProductsPage()),
        );
      } else {
        throw Exception('Erro na atualização: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e')),
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
            content: Text('Desconto não pode ser maior que o preço')),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Produto',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: primaryColor, height: 2),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: (base64Image != null ||
                                widget.product.imagemBase64 != null)
                            ? DecorationImage(
                                image: MemoryImage(
                                  base64Image != null
                                      ? base64Decode(base64Image!)
                                      : base64Decode(
                                          widget.product.imagemBase64!),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (base64Image == null &&
                              widget.product.imagemBase64 == null)
                          ? Center(
                              child: Icon(Icons.image, color: Colors.grey[400]))
                          : null,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: nameController,
                    decoration:
                        inputDecoration.copyWith(labelText: 'Nome do produto'),
                    validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration:
                        inputDecoration.copyWith(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          decoration:
                              inputDecoration.copyWith(labelText: 'Preço'),
                          keyboardType: TextInputType.number,
                          validator: (v) => _parseCurrency(v!) <= 0
                              ? 'Informe o preço'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: discountController,
                          decoration:
                              inputDecoration.copyWith(labelText: 'Desconto'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: costController,
                    decoration:
                        inputDecoration.copyWith(labelText: 'Custo produção'),
                    validator: (v) =>
                        _parseCurrency(v!) <= 0 ? 'Informe o custo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: validityController,
                    decoration:
                        inputDecoration.copyWith(labelText: 'Dias validade'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Informe a validade' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: ['Doce', 'Salgado', 'Bebida']
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => category = v!),
                    decoration:
                        inputDecoration.copyWith(labelText: 'Categoria'),
                  ),
                  const SizedBox(height: 24),
                  Text('Características',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      )),
                  const SizedBox(height: 8),
                  _loadingChars
                      ? Center(
                          child: CircularProgressIndicator(color: primaryColor))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: caracteristicas
                              .map((c) => FilterChip(
                                    selected:
                                        selectedCharacteristics.contains(c.id),
                                    label: Text(c.descricao),
                                    onSelected: (s) => setState(() => s
                                        ? selectedCharacteristics.add(c.id)
                                        : selectedCharacteristics.remove(c.id)),
                                    selectedColor:
                                        primaryColor.withOpacity(0.2),
                                    checkmarkColor: primaryColor,
                                    labelStyle: TextStyle(
                                      color:
                                          selectedCharacteristics.contains(c.id)
                                              ? primaryColor
                                              : Colors.grey[700],
                                    ),
                                  ))
                              .toList(),
                        ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SALVAR ALTERAÇÕES',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
