import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/services/app_theme.dart';
import '../model/product.dart'; 
import '../../services/auth_provider.dart';

const primaryColor = Color(0xFFFbbc2c);
List<String> availableSizes = ['Grande', 'Médio', 'Pequeno'];

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Product controllers
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController validityCtrl;
  late MoneyMaskedTextController priceCtrl;
  late MoneyMaskedTextController costCtrl;
  late MoneyMaskedTextController discountCtrl; // Desconto geral do produto

  // Batch controllers
  late TextEditingController batchQuantityCtrl;
  late MoneyMaskedTextController batchDiscountPriceCtrl; // Preço com desconto específico do LOTE
  late TextEditingController batchManufactureDateCtrl;
  DateTime? _selectedManufactureDate; // Para armazenar a data selecionada

  String size = 'Médio';
  String category = 'Doce';
  File? selectedImage;
  String? imageId;
  String? imageUrl;
  bool _isLoading = false;
  bool _loadingChars = true;
  // Não precisa mais de _loadingBatch ou _batchDetails

  List<Characteristic> allChars = [];
  List<String> selectedCharIds = [];

  @override
  void initState() {
    super.initState();
    // Debug: print incoming product details including lote
    debugPrint("[DEBUG] Opening EditProductScreen with product: ${jsonEncode(widget.product.toJson())}");
    debugPrint("[DEBUG] Raw lote object: ${widget.product.lote}");
    debugPrint("[DEBUG] Computed id_lote: ${widget.product.id_lote}");
    debugPrint("[DEBUG] quantidade (widget.product.quantidade): ${widget.product.quantidade}");
    debugPrint("[DEBUG] dataFabricacao: ${widget.product.dataFabricacao}");
    _initializeControllers(); // Inicializa todos os controllers
    _fetchCaracteristicas();
  }

  void _initializeControllers() {
    // --- Product Controllers ---
    nameCtrl = TextEditingController(text: widget.product.nome);
    descCtrl = TextEditingController(text: widget.product.descricao);
    validityCtrl = TextEditingController(text: widget.product.diasValidade.toString());

    priceCtrl = MoneyMaskedTextController(
        initialValue: widget.product.valorVenda,
        decimalSeparator: ',',
        thousandSeparator: '.',
        leftSymbol: 'R\$ ');
    costCtrl = MoneyMaskedTextController(
        initialValue: widget.product.valorCusto,
        decimalSeparator: ',',
        thousandSeparator: '.',
        leftSymbol: 'R\$ ');
    // Controller para o desconto GERAL do produto
    discountCtrl = MoneyMaskedTextController(
        initialValue: widget.product.desconto ?? 0,
        decimalSeparator: ',',
        thousandSeparator: '.',
        leftSymbol: 'R\$ ');

    // --- Batch Controllers (inicializados a partir dos campos do Product) ---
    // Assume que 'widget.product.quantidade' existe e é a quantidade do lote
    batchQuantityCtrl = TextEditingController(text: widget.product.quantidade?.toString() ?? '');

    // Usa o campo correto do modelo Product para o preço com desconto do lote
    double initialBatchDiscountPrice = widget.product.valorVendaDesc; // Corrigido!
    batchDiscountPriceCtrl = MoneyMaskedTextController(
        initialValue: initialBatchDiscountPrice,
        decimalSeparator: ",",
        thousandSeparator: ".",
        leftSymbol: "R\$ ");

    // Assume que 'widget.product.dataFabricacao' existe e é um DateTime?
    _selectedManufactureDate = widget.product.dataFabricacao;
    batchManufactureDateCtrl = TextEditingController(
      text: _selectedManufactureDate != null
          ? DateFormat('dd/MM/yyyy').format(_selectedManufactureDate!)
          : '',
    );

    // --- Outras Inicializações --- 
    selectedCharIds = widget.product.caracteristicas?.map((c) => c.id_Caracteristica).toList() ?? [];
    category = widget.product.categoria;
    size = availableSizes.contains(widget.product.tamanho)
        ? widget.product.tamanho
        : availableSizes.first;
    imageId = widget.product.imageId;
    imageUrl = widget.product.imagemUrl;
  }

  Future<void> _fetchCaracteristicas() async {
    // ... (código do _fetchCaracteristicas permanece o mesmo)
    setState(() => _loadingChars = true);
    try {
      final r = await http.get(Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetCharacteristics'));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        setState(() {
          allChars = (data["caracteristicas"] as List)
              .map((j) => Characteristic.fromJson(j as Map<String, dynamic>))
              .toList();
        });
      } else {
        throw Exception('Erro ${r.statusCode} ao buscar características');
      }
    } catch (e) {
      debugPrint('Erro ao carregar características: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar características: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingChars = false);
    }
  }

  // Não precisa mais de _fetchBatchDetails

  Future<void> pickImage() async {
    // ... (código do pickImage permanece o mesmo)
    final pf = await _picker.pickImage(source: ImageSource.gallery);
    if (pf == null) return;

    setState(() {
      selectedImage = File(pf.path);
      _isLoading = true; // Usar _isLoading geral
    });

    try {
      final ext = pf.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
        throw Exception('Formato não suportado. Use JPG, PNG, GIF ou WebP.');
      }

      final normExt = ext == 'jpeg' ? 'jpg' : ext;
      final bytes = await pf.readAsBytes();
      final b64 = base64Encode(bytes);
      final payload = {'image': b64, 'file_extension': normExt};

      // <<=== SUBSTITUA PELA SUA URL REAL PARA SALVAR IMAGEM
      final resp = await http.post(
        Uri.parse('https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/SaveProductImage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (resp.statusCode != 200) {
        throw Exception('Erro ao enviar imagem: ${resp.body}');
      }

      final json = jsonDecode(resp.body);
      final fileName = json['file_name'].toString();

      setState(() {
        imageId = fileName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem enviada com sucesso!')),
      );
    } catch (e) {
      debugPrint('Erro ao processar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar imagem: $e')),
      );
    } finally {
       // Resetar loading APÓS a tentativa de salvar imagem
       if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProductAndBatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    String? errorMessage;

    try {
      // 1. Atualiza o produto
      print("Atualizando produto...");
      final productResponse = await _updateProduct(auth.accessToken!);
      if (productResponse.statusCode != 200) {
        throw Exception('Falha ao atualizar produto: ${productResponse.body}');
      }
      print("Produto atualizado com sucesso.");

      // 2. Atualiza o lote SE o produto tiver um ID de lote associado
      //    Assume que 'widget.product.lote' é o ID do lote (String?)
      final batchId = widget.product.id_lote; // Corrigido para usar id_lote
      // ADICIONANDO LOG PARA DEBUG:
      print("DEBUG: Verificando ID do lote. Valor de widget.product.id_lote: 	'$batchId'");
      if (batchId != null && batchId.isNotEmpty) {         print("Atualizando lote ID: $batchId...");
        final batchResponse = await _updateBatch(auth.accessToken!, batchId);
        if (batchResponse.statusCode != 200) {
          errorMessage = 'Produto atualizado, mas falha ao atualizar lote: ${batchResponse.body}';
          throw Exception(errorMessage);
        }
         print("Lote atualizado com sucesso.");
      } else {
        print("Produto não possui ID de lote associado. Pulando atualização do lote.");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto e lote atualizados com sucesso!')),
      );
      Navigator.pop(context, true); // Retorna true para indicar sucesso

    } catch (e) {
      debugPrint('Erro ao atualizar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage ?? 'Erro ao atualizar: $e')),
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<http.Response> _updateProduct(String token) async {
    // Garantir que o ID da imagem original seja usado se nenhum novo for selecionado
    final String? finalImageId = imageId ?? widget.product.imageId;

    // Corpo da requisição para /UpdateProduct (usa snake_case para as chaves)
    final body = <String, dynamic>{
      'id_Produto': widget.product.id,
      'nome': nameCtrl.text,
      'fk_id_Categoria': _categoryId(category),
      'dias_vcto': int.tryParse(validityCtrl.text) ?? 0,
      'valor_venda': _toNum(priceCtrl.text),
      'valor_custo': _toNum(costCtrl.text),
      'descricao': descCtrl.text,
      'tamanho': size,
      'disponivel': widget.product.disponivel,
      'caracteristicas_IDs': selectedCharIds,
      'id_imagem': finalImageId ?? '', // Envia string vazia se for nulo (backend exige)
      'desconto': _toNum(discountCtrl.text),
      'flag_oferta': false,
    };

    // Remove o desconto se for zero ou negativo (opcional, depende do backend)
    if (body['desconto'] <= 0) {
      body.remove('desconto');
    }

    print("Enviando atualização do produto: ${jsonEncode(body)}");

    // <<=== SUBSTITUA PELA SUA URL REAL PARA ATUALIZAR PRODUTO
    return await http.put(
      Uri.parse('https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateProduct'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(body),
    );
  }

  // Recebe o ID do lote como parâmetro
  Future<http.Response> _updateBatch(String token, String batchId) async {
    // Formata a data selecionada para YYYY-MM-DD
    String? formattedDate;
    if (_selectedManufactureDate != null) {
       formattedDate = DateFormat('yyyy-MM-dd').format(_selectedManufactureDate!);
    }

    // Corpo da requisição para /UpdateBatch (usa snake_case para as chaves corretas)
    final body = <String, dynamic>{
      'id_lote': batchId,  // corrigido para id_lote
      'quantidade': int.tryParse(batchQuantityCtrl.text) ?? 0,
      'valor_venda_desc': _toNum(batchDiscountPriceCtrl.text),
      'dt_fabricacao': formattedDate,
    };

    debugPrint("[DEBUG] Enviando atualização do lote com body: ${jsonEncode(body)}");

    // Envia requisição para atualizar lote
    final response = await http.put(
      Uri.parse('https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateBatch'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(body),
    );
    debugPrint("[DEBUG] Resposta UpdateBatch: status=${response.statusCode}, body=${response.body}");
    return response;
  }

  // Função auxiliar para converter valor monetário mascarado para double
  double _toNum(String v) =>
      double.tryParse(v.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.')) ?? 0;

  // Função auxiliar para obter ID da categoria
  int _categoryId(String c) {
    switch (c) {
      case 'Doce': return 188564336962606369;
      case 'Salgado': return 303744449465944688;
      case 'Bebida': return 321601065408987139;
      default: return 188564336962606369; // Padrão para Doce
    }
  }

  // Função para exibir o DatePicker
  Future<void> _selectManufactureDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedManufactureDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedManufactureDate) {
      setState(() {
        _selectedManufactureDate = picked;
        batchManufactureDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Funções auxiliares para imagem (mantidas como antes)
  ImageProvider? _getProductImageProvider() {
    if (selectedImage != null) {
      return FileImage(selectedImage!);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return NetworkImage(imageUrl!);
    }
    return null;
  }

  DecorationImage? _getProductImageDecoration() {
    final provider = _getProductImageProvider();
    if (provider != null) {
      return DecorationImage(image: provider, fit: BoxFit.cover);
    }
    return null;
  }

  Widget _getProductImageChild() {
    if (_getProductImageProvider() == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.grey[600], size: 40),
            const SizedBox(height: 8),
            Text('Adicionar Imagem', style: TextStyle(color: Colors.grey[700]))
          ],
        ),
      );
    }
    return Container(); // Retorna container vazio se a imagem estiver definida
  }

  @override
  Widget build(BuildContext context) {
    // Definição da decoração de input (mantida como antes)
    final dec = InputDecoration(
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 1.5)),
      labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
      suffixIcon: null, // Reset suffix icon
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Produto e Lote',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold, // Deixa o título em bold
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 255, 255, 255)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: const Color.fromARGB(255, 255, 255, 255), height: 2),
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
                  // --- Seção da Imagem do Produto ---
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: _getProductImageDecoration(),
                      ),
                      child: _getProductImageChild(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Seção de Detalhes do Produto ---
                  const Text('Informações do Produto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: dec.copyWith(labelText: 'Nome do produto'),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descCtrl,
                    decoration: dec.copyWith(labelText: 'Descrição'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          decoration: dec.copyWith(labelText: 'Preço Venda (Produto)'),
                          keyboardType: TextInputType.number,
                          validator: (v) => _toNum(v!) <= 0 ? 'Informe preço válido' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                     
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: costCtrl,
                    decoration: dec.copyWith(labelText: 'Custo produção'),
                    keyboardType: TextInputType.number,
                    validator: (v) => _toNum(v!) <= 0 ? 'Informe custo válido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: validityCtrl,
                    decoration: dec.copyWith(labelText: 'Dias validade'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Informe dias válidos' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: size,
                    items: availableSizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => size = v!),
                    decoration: dec.copyWith(labelText: 'Tamanho'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: ['Doce', 'Salgado', 'Bebida'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => category = v!),
                    decoration: dec.copyWith(labelText: 'Categoria'),
                  ),
                  const SizedBox(height: 24),

                  // --- Seção de Características ---
                  Text('Características', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  const SizedBox(height: 8),
                  _loadingChars
                      ? Center(child: CircularProgressIndicator(color: primaryColor))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: allChars.map((ch) {
                            final sel = selectedCharIds.contains(ch.id_Caracteristica);
                            return FilterChip(
                              label: Text(ch.descricao),
                              selected: sel,
                              onSelected: (b) => setState(() {
                                b ? selectedCharIds.add(ch.id_Caracteristica)
                                  : selectedCharIds.remove(ch.id_Caracteristica);
                              }),
                              selectedColor: primaryColor.withOpacity(0.2),
                              checkmarkColor: primaryColor,
                              labelStyle: TextStyle(color: sel ? primaryColor : Colors.grey[700]),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 32),

                  // --- Seção de Informações do Lote ---
                  // Mostra seção de lote sempre que há quantidade retornada (mesmo sem id_lote)
                  if (widget.product.quantidade != null) ...[
                   const Text('Informações do Lote', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   Column(
                     children: [
                        TextFormField(
                          controller: batchQuantityCtrl,
                          decoration: dec.copyWith(labelText: 'Quantidade no Lote'),
                          keyboardType: TextInputType.number,
                          validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0 ? 'Informe quantidade válida' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: batchDiscountPriceCtrl,
                          decoration: dec.copyWith(labelText: 'Preço Venda c/ Desconto (Lote)'),
                          keyboardType: TextInputType.number,
                          // Validação opcional
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: batchManufactureDateCtrl,
                          decoration: dec.copyWith(
                            labelText: 'Data de Fabricação (dd/MM/yyyy)',
                            suffixIcon: IconButton(
                                icon: Icon(Icons.calendar_today, color: primaryColor),
                                onPressed: () => _selectManufactureDate(context),
                            )
                          ),
                          readOnly: true, // Impede digitação direta
                          onTap: () => _selectManufactureDate(context),
                          validator: (v) => v == null || v.isEmpty ? 'Informe a data de fabricação' : null,
                        ),
                     ],
                   ),
                   const SizedBox(height: 32),
                  ],

                  // --- Botão Salvar ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProductAndBatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Salvar Alterações', style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                  const SizedBox(height: 20), // Espaço extra no final
                ],
              ),
            ),
          ),
          // Overlay de Loading geral
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}

