import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../model/product.dart';
import '../../services/auth_provider.dart';
import 'vendor_products_page.dart';

const primaryColor = Color(0xFFFbbc2c);
List<String> availableSizes = ['Grande', 'Médio', 'Pequeno'];

class Caracteristica {
  final String id;
  final String descricao;
  Caracteristica({required this.id, required this.descricao});
  factory Caracteristica.fromJson(Map<String, dynamic> j) => Caracteristica(
        id: j['id_Caracteristica'].toString(),
        descricao: j['descricao'] ?? '',
      );
}

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController validityCtrl;
  late MoneyMaskedTextController priceCtrl;
  late MoneyMaskedTextController costCtrl;
  late MoneyMaskedTextController discountCtrl;

  String size = 'Médio';
  String category = 'Doce';
  File? selectedImage;
  String? imageId; // armazena o id do backend
  bool _isLoading = false, _loadingChars = true;

  List<Caracteristica> allChars = [];
  List<String> selectedChars = [];

  @override
  void initState() {
    super.initState();
    // Controllers
    nameCtrl = TextEditingController(text: widget.product.nome);
    descCtrl = TextEditingController(text: widget.product.descricao);
    validityCtrl =
        TextEditingController(text: widget.product.diasValidade.toString());

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
    discountCtrl = MoneyMaskedTextController(
        initialValue: widget.product.desconto ?? 0,
        decimalSeparator: ',',
        thousandSeparator: '.',
        leftSymbol: 'R\$ ');

    // Pré–seleção
    selectedChars = List.from(widget.product.caracteristicasIDs);
    category = widget.product.categoria;
    size = availableSizes.contains(size) ? size : availableSizes.first;

    // IMPORTANTE: Inicializa o imageId com o ID da imagem atual do produto
    imageId = widget.product.imageId;

    debugPrint(
        'Inicializando produto ${widget.product.id} com ID de imagem: $imageId');

    _fetchCaracteristicas();
  }

  Future<void> _fetchCaracteristicas() async {
    try {
      final r = await http.get(Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetCharacteristics'));
      final data = jsonDecode(r.body);
      setState(() {
        allChars = (data['caracteristicas'] as List)
            .map((j) => Caracteristica.fromJson(j))
            .toList();
        _loadingChars = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar características: $e');
      setState(() => _loadingChars = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar características: $e')),
      );
    }
  }

  Future<void> pickImage() async {
    final pf = await _picker.pickImage(source: ImageSource.gallery);
    if (pf == null) return;

    setState(() {
      selectedImage = File(pf.path);
      _isLoading = true;
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

      final resp = await http.post(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/SaveProductImage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (resp.statusCode != 200) {
        throw Exception('Erro ao enviar imagem: ${resp.body}');
      }

      final json = jsonDecode(resp.body);
      final fileName = json['file_name'].toString();

      debugPrint('Nova imagem enviada com sucesso. ID: $fileName');

      setState(() {
        imageId = fileName;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem enviada com sucesso!')),
      );
    } catch (e) {
      debugPrint('Erro ao processar imagem: $e');
      setState(() {
        _isLoading = false;
        // Importante: não limpar o imageId aqui para manter o ID anterior em caso de erro
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar imagem: $e')),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      // CORREÇÃO CRÍTICA: Se o imageId for nulo, mas o produto tiver um ID de imagem,
      // use o ID de imagem do produto original para garantir que a imagem não seja perdida
      if (imageId == null && widget.product.imageId != null) {
        debugPrint(
            'Usando ID de imagem original do produto: ${widget.product.imageId}');
        imageId = widget.product.imageId;
      }

      // Verificar se temos um ID de imagem
      if (imageId == null) {
        debugPrint('AVISO: ID da imagem é nulo ao salvar o produto');
      } else {
        debugPrint('Salvando produto com ID de imagem: $imageId');
      }

      final body = <String, dynamic>{
        'id_Produto': widget.product.id,
        'nome': nameCtrl.text,
        'fk_id_Categoria': _categoryId(category),
        'dias_vcto': int.parse(validityCtrl.text),
        'valor_venda': _toNum(priceCtrl.text),
        'valor_custo': _toNum(costCtrl.text),
        'descricao': descCtrl.text,
        'tamanho': size,
        'disponivel': widget.product.disponivel,
        'caracteristicas_IDs': selectedChars,
      };

      // IMPORTANTE: Sempre incluir o ID da imagem no corpo da requisição,
      // mesmo que seja o ID original do produto
      if (imageId != null) {
        body['id_imagem'] = imageId!;
      } else if (widget.product.imageId != null) {
        body['id_imagem'] = widget.product.imageId!;
      }

      // Adicionar desconto apenas se for maior que zero
      final desconto = _toNum(discountCtrl.text);
      if (desconto > 0) {
        body['desconto'] = desconto;
      }

      debugPrint('Enviando corpo da requisição: ${jsonEncode(body)}');

      final resp = await http.put(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateProduct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.accessToken}'
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      } else {
        final err = jsonDecode(resp.body);
        throw Exception(err['message'] ?? resp.body);
      }
    } catch (e) {
      debugPrint('Erro ao atualizar produto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _toNum(String v) =>
      double.tryParse(
          v.replaceAll(RegExp(r'[R\$\.\s]'), '').replaceAll(',', '.')) ??
      0;

  int _categoryId(String c) {
    switch (c) {
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
  Widget build(BuildContext c) {
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
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Produto',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: primaryColor, height: 2),
        ),
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _getProductImageDecoration(),
                  ),
                  child: _getProductImageChild(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameCtrl,
                decoration: dec.copyWith(labelText: 'Nome do produto'),
                validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descCtrl,
                decoration: dec.copyWith(labelText: 'Descrição'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: TextFormField(
                  controller: priceCtrl,
                  decoration: dec.copyWith(labelText: 'Preço'),
                  keyboardType: TextInputType.number,
                  validator: (v) => _toNum(v!) <= 0 ? 'Informe preço' : null,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: TextFormField(
                  controller: discountCtrl,
                  decoration: dec.copyWith(labelText: 'Desconto'),
                  keyboardType: TextInputType.number,
                )),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: costCtrl,
                decoration: dec.copyWith(labelText: 'Custo produção'),
                validator: (v) => _toNum(v!) <= 0 ? 'Informe custo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: validityCtrl,
                decoration: dec.copyWith(labelText: 'Dias validade'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Informe dias' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: size,
                items: availableSizes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => size = v!),
                decoration: dec.copyWith(labelText: 'Tamanho'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                items: ['Doce', 'Salgado', 'Bebida']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => category = v!),
                decoration: dec.copyWith(labelText: 'Categoria'),
              ),
              const SizedBox(height: 24),
              Text(
                'Características',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              _loadingChars
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allChars.map((ch) {
                        final sel = selectedChars.contains(ch.id);
                        return FilterChip(
                          label: Text(ch.descricao),
                          selected: sel,
                          onSelected: (b) => setState(() {
                            b
                                ? selectedChars.add(ch.id)
                                : selectedChars.remove(ch.id);
                          }),
                          selectedColor: primaryColor.withOpacity(0.2),
                          checkmarkColor: primaryColor,
                          labelStyle: TextStyle(
                            color: sel ? primaryColor : Colors.grey[700],
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SALVAR ALTERAÇÕES',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
              ),
            ]),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.1),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ]),
    );
  }

  // Método para obter a decoração da imagem do produto
  DecorationImage? _getProductImageDecoration() {
    if (selectedImage != null) {
      // Se temos uma imagem selecionada localmente
      return DecorationImage(
        image: FileImage(selectedImage!),
        fit: BoxFit.cover,
      );
    } else if (widget.product.imagemUrl != null &&
        widget.product.imagemUrl!.isNotEmpty) {
      // Se temos uma URL de imagem
      return DecorationImage(
        image: NetworkImage(widget.product.imagemUrl!),
        fit: BoxFit.cover,
      );
    }
    return null; // Sem imagem
  }

  // Método para obter o widget filho da imagem do produto
  Widget? _getProductImageChild() {
    if (selectedImage == null &&
        (widget.product.imagemUrl == null ||
            widget.product.imagemUrl!.isEmpty)) {
      // Se não temos imagem, mostrar ícone
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: Colors.grey[400], size: 40),
            const SizedBox(height: 8),
            Text(
              'Adicionar imagem',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }
    return null; // Se temos imagem, não precisamos de um widget filho
  }
}
