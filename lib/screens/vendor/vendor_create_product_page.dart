import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:vizinhos_app/screens/vendor/vendor_products_page.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:intl/intl.dart';

import '../../services/app_theme.dart';

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

  // Novos controllers para o lote
  final fabricationDateController = TextEditingController();
  final quantityController = TextEditingController();

  String category = 'Doce';
  // Adicionando opção de tamanho
  String size = 'Médio'; // Valor padrão
  List<String> availableSizes = ['Grande', 'Médio', 'Pequeno'];

  File? selectedImage;
  String? imageId; // Renomeado de base64Image para imageId para maior clareza

  // Lista dinâmica de características carregada da API
  List<Caracteristica> caracteristicas = [];
  List<String> selectedCharacteristics = [];
  bool _isLoading = false;
  bool _loadingChars = true;

  // Variável para armazenar o ID do produto criado
  String? createdProductId;

  @override
  void initState() {
    super.initState();
    _fetchCaracteristicas();

    // Inicializa a data de fabricação com a data atual
    fabricationDateController.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Inicializa a quantidade com um valor padrão
    quantityController.text = "1";
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
    fabricationDateController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  // Função atualizada para usar a API SaveStoreImage
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        _isLoading = true; // Mostrar indicador de carregamento
      });

      try {
        // Obter a extensão do arquivo
        final String extension = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
          throw Exception(
              'Formato de imagem não suportado. Use JPG, PNG, GIF ou WebP.');
        }

        // Normalizar extensão (jpg/jpeg)
        final String normalizedExtension =
            extension == 'jpeg' ? 'jpg' : extension;

        // Ler os bytes da imagem
        final bytes = await pickedFile.readAsBytes();

        // Converter para base64
        final String base64Image = base64Encode(bytes);

        // Preparar o payload para a API SaveStoreImage
        final Map<String, dynamic> payload = {
          'image': base64Image,
          'file_extension': normalizedExtension
        };

        // Enviar para a API SaveStoreImage
        final response = await http.post(
          Uri.parse(
              'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/SaveProductImage'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        // Depuração: imprimir a resposta completa
        print('Resposta da API SaveStoreImage: ${response.body}');

        // Verificar resposta
        if (response.statusCode == 200) {
          try {
            // Decodificar a resposta JSON
            final Map<String, dynamic> responseData = jsonDecode(response.body);

            // Extrair o nome do arquivo
            final String fileName = responseData['file_name'];

            // Depuração: imprimir o valor extraído
            print('Nome do arquivo extraído: $fileName');

            // Armazenar o ID da imagem (nome do arquivo)
            setState(() {
              imageId = fileName; // Armazena o ID da imagem, não o base64
              _isLoading = false;
            });

            // Feedback para o usuário
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Imagem enviada com sucesso!")),
            );
          } catch (jsonError) {
            print('Erro ao decodificar JSON: $jsonError');
            print('Conteúdo da resposta: ${response.body}');
            throw Exception('Erro ao processar resposta da API: $jsonError');
          }
        } else {
          throw Exception('Falha ao enviar imagem: ${response.body}');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao processar imagem: ${e.toString()}")),
        );
      }
    }
  }

  // Método para selecionar data de fabricação
  Future<void> _selectFabricationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        fabricationDateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Método para calcular o valor de venda com desconto
  double _calcularValorVendaDesconto() {
    final desconto = _parseCurrency(discountController.text);
    return desconto;
  }

  // Método atualizado para criar o produto e depois o lote
  Future<void> submitProduct() async {
    if (!_validatePrices()) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Verificar se a imagem foi selecionada
    if (selectedImage == null || imageId == null || imageId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecione uma imagem para o produto')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enderecoId = int.tryParse(authProvider.idEndereco ?? '') ?? 0;

    setState(() => _isLoading = true);

    try {
      // 1. Criar o produto
      final produtoUri = Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/CreateProduct');

      final produtoBody = {
        "nome": nameController.text,
        "fk_id_Endereco": enderecoId,
        "fk_id_Categoria": getCategoryId(),
        "dias_vcto": int.tryParse(validityController.text) ?? 0,
        "valor_venda": _parseCurrency(priceController.text),
        "valor_custo": _parseCurrency(costController.text),
        "tamanho": size,
        "descricao": descriptionController.text,
        "id_imagem": imageId,
        "disponivel": true,
        "caracteristicas_IDs": selectedCharacteristics,
      };

      // Depuração: imprimir o body antes de enviar
      print('Body do request de produto: ${jsonEncode(produtoBody)}');

      final produtoResponse = await http.post(
        produtoUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.accessToken}',
        },
        body: jsonEncode(produtoBody),
      );

      // Depuração: imprimir a resposta completa
      print('Status code produto: ${produtoResponse.statusCode}');
      print('Resposta produto completa: ${produtoResponse.body}');

      if (produtoResponse.statusCode == 200) {
        // Extrair o ID do produto da resposta
        try {
          final produtoData = jsonDecode(produtoResponse.body);

          // Log detalhado da resposta para depuração
          print('Resposta decodificada: $produtoData');
          print('Tipo da resposta: ${produtoData.runtimeType}');
          print(
              'Chaves disponíveis: ${produtoData is Map ? produtoData.keys.toList() : "Não é um Map"}');

          // Verificar se a resposta contém o ID do produto diretamente ou em uma estrutura aninhada
          if (produtoData is Map) {
            if (produtoData.containsKey('id_Produto')) {
              createdProductId = produtoData['id_Produto'].toString();
              print('ID do produto encontrado diretamente: $createdProductId');
            } else if (produtoData.containsKey('produto') &&
                produtoData['produto'] is Map) {
              createdProductId =
                  produtoData['produto']['id_Produto'].toString();
              print(
                  'ID do produto encontrado em estrutura aninhada: $createdProductId');
            } else if (produtoData.containsKey('message') &&
                produtoData.containsKey('produto_id')) {
              createdProductId = produtoData['produto_id'].toString();
              print(
                  'ID do produto encontrado como produto_id: $createdProductId');
            } else {
              // Tentar encontrar qualquer campo que possa conter o ID
              for (var key in produtoData.keys) {
                if (key.toLowerCase().contains('id') &&
                    produtoData[key] != null) {
                  createdProductId = produtoData[key].toString();
                  print(
                      'Possível ID do produto encontrado em campo $key: $createdProductId');
                  break;
                }
              }
            }
          }

          if (createdProductId == null || createdProductId!.isEmpty) {
            throw Exception(
                'ID do produto não encontrado na resposta. Resposta completa: ${produtoResponse.body}');
          }
        } catch (e) {
          print('Erro ao extrair ID do produto: $e');
          throw Exception(
              'Erro ao extrair ID do produto: $e. Resposta completa: ${produtoResponse.body}');
        }

        // 2. Criar o lote associado ao produto
        await _createBatch(createdProductId!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto e lote criados com sucesso!')),
        );

        // Navegação usando MaterialPageRoute
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VendorProductsPage(),
          ),
        );
      } else {
        throw Exception('Erro ao criar produto: ${produtoResponse.body}');
      }
    } catch (e) {
      print('Erro durante o processo de criação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Método para criar o lote associado ao produto
  Future<void> _createBatch(String produtoId) async {
    try {
      final loteUri = Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/CreateBatch');

      // Validação e parsing da quantidade
      final quantidade = int.tryParse(quantityController.text);
      if (quantidade == null || quantidade <= 0) {
        throw Exception('Quantidade inválida');
      }

      // Calcula o valor de venda com desconto e garante formato string com ponto
      final valorVendaDesc = _calcularValorVendaDesconto().toStringAsFixed(2);

      // Monta o body do lote
      final loteBody = {
        "fk_id_Produto": produtoId,
        "dt_fabricacao": fabricationDateController.text,
        "valor_venda_desc": _calcularValorVendaDesconto(),
        "quantidade": quantidade
      };

      // Headers explícitos e corretos
      final headers = {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${Provider.of<AuthProvider>(context, listen: false).accessToken}',
        'Accept': 'application/json',
      };

      print('Enviando lote: $loteBody');
      print('Headers: $headers');

      final loteResponse = await http.post(
        loteUri,
        headers: headers,
        body: jsonEncode(loteBody),
      );

      print('Status code lote: ${loteResponse.statusCode}');
      print('Resposta lote: ${loteResponse.body}');

      if (loteResponse.statusCode != 200) {
        throw Exception('Erro ao criar lote: ${loteResponse.body}');
      } else {
        final loteData = jsonDecode(loteResponse.body);
        if (loteData is Map && loteData.containsKey('lote')) {
          final loteId = loteData['lote']['id_Lote'];
          print('ID do lote criado: $loteId');
        }
      }
    } catch (e) {
      print('Erro ao criar lote: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Aviso: Produto criado, mas houve erro ao criar o lote: $e'),
        ),
      );
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
        backgroundColor: AppTheme.primaryColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Criar produto',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
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
                      labelText: 'Dias de validade',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe a validade'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Divisor para seção de lotes
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informações do Lote',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 2,
                          color: primaryColor.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),

                  // Data de Fabricação
                  GestureDetector(
                    onTap: _selectFabricationDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: fabricationDateController,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Data de Fabricação',
                          suffixIcon:
                              Icon(Icons.calendar_today, color: primaryColor),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Informe a data de fabricação'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quantidade
                  TextFormField(
                    controller: quantityController,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Quantidade no Lote',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a quantidade';
                      }
                      final quantidade = int.tryParse(value);
                      if (quantidade == null || quantidade <= 0) {
                        return 'Quantidade deve ser um número positivo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Categoria
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categoria',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: category,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            borderRadius: BorderRadius.circular(10),
                            items: ['Doce', 'Salgado', 'Bebida']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  category = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tamanho
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tamanho',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: size,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            borderRadius: BorderRadius.circular(10),
                            items: availableSizes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  size = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Características
                  if (_loadingChars)
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  else if (caracteristicas.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Características',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...caracteristicas.map((caracteristica) {
                          return CheckboxListTile(
                            title: Text(caracteristica.descricao),
                            value: selectedCharacteristics
                                .contains(caracteristica.id),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedCharacteristics
                                      .add(caracteristica.id);
                                } else {
                                  selectedCharacteristics
                                      .remove(caracteristica.id);
                                }
                              });
                            },
                            activeColor: primaryColor,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          );
                        }).toList(),
                      ],
                    ),
                  const SizedBox(height: 30),

                  // Botão de Criar Produto
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : submitProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Criar Produto e Lote',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
