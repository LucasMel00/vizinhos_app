import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/model/lote.dart';

class Characteristic {
  final String id_Caracteristica;
  final String descricao;

  Characteristic({
    required this.id_Caracteristica,
    required this.descricao,
  });

  factory Characteristic.fromJson(Map<String, dynamic> json) {
    return Characteristic(
      id_Caracteristica: json['id_Caracteristica']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_Caracteristica': id_Caracteristica,
      'descricao': descricao,
    };
  }
}

class Product {
  final String id;
  final String nome;
  final String descricao;
  final double valorVenda;
  final double valorCusto;
  final int diasValidade;
  late bool disponivel;
  final String categoria;
  final String fkIdEndereco;
  final String fkIdCategoria;
  final String tamanho;
  final double valorVendaDesc;
  final List<Characteristic>? caracteristicas;
  final String? imagemUrl;
  final String? imageId;
  final double? desconto;
  final dynamic lote;
  final DateTime? dataFabricacao;
  final int? quantidade;
  final bool flagOferta;

  String? get id_lote {
    if (lote == null) return null;
    if (lote is String && lote != 'null') return lote;
    if (lote is Map<String, dynamic>) {
      if (lote['id'] != null && lote['id'].toString() != 'null') {
        return lote['id'].toString();
      }
      if (lote['id_Lote'] != null && lote['id_Lote'].toString() != 'null') {
        return lote['id_Lote'].toString();
      }
    }
    if (lote is Lote && lote.idLote != 'null') {
      return lote.idLote;
    }
    return null;
  }

  static int? _getQuantidadeFromLote(dynamic lote) {
    if (lote is Map<String, dynamic> && lote['quantidade'] != null) {
      return _parseInt(lote['quantidade']);
    }
    return null;
  }

  Product({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.valorVenda,
    required this.valorCusto,
    required this.diasValidade,
    required this.disponivel,
    required this.categoria,
    required this.fkIdEndereco,
    required this.fkIdCategoria,
    required this.tamanho,
    required this.valorVendaDesc,
    required this.caracteristicas,
    this.imagemUrl,
    this.imageId,
    this.desconto,
    this.lote,
    this.dataFabricacao,
    this.quantidade,
    this.flagOferta = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<Characteristic> parseCharacteristics(dynamic characteristicsJson) {
      if (characteristicsJson == null) return [];
      if (characteristicsJson is List) {
        return characteristicsJson
            .where((item) => item is Map<String, dynamic>)
            .map(
                (item) => Characteristic.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      if (characteristicsJson is String) {
        try {
          List<dynamic> decodedList = jsonDecode(characteristicsJson);
          return decodedList
              .where((item) => item is Map<String, dynamic>)
              .map((item) =>
                  Characteristic.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    dynamic loteObj;
    if (json['lote'] != null) {
      if (json['lote'] is Map<String, dynamic>) {
        loteObj = Lote.fromJson(json['lote']);
      } else {
        loteObj = json['lote'];
      }
    } else if (json['id_lote'] != null &&
        json['id_lote'].toString() != 'null') {
      loteObj = json['id_lote'].toString();
    }

    return Product(
      id: json['id_Produto']?.toString() ??
          json['id_produto']?.toString() ??
          '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      valorVenda: _parseDouble(json['valor_venda']),
      valorCusto: _parseDouble(json['valor_custo']),
      diasValidade: _parseInt(json['dias_vcto']),
      disponivel: json['disponivel'] ?? false,
      categoria: json['categoria'] ?? 'Sem categoria',
      fkIdEndereco: json['fk_id_Endereco']?.toString() ?? '',
      fkIdCategoria: json['fk_id_Categoria']?.toString() ?? '',
      tamanho: json['tamanho']?.toString() ?? '',
      valorVendaDesc: _parseDouble(json['valor_venda_desc']),
      caracteristicas: parseCharacteristics(json['caracteristicas']),
      imagemUrl: json['imagem_url'],
      imageId: json['id_imagem']?.toString(),
      desconto: _parseDouble(json['desconto']),
      lote: loteObj,
      dataFabricacao: json['dt_fabricacao'] != null
          ? DateTime.tryParse(json['dt_fabricacao'])
          : null,
      quantidade: json['quantidade'] != null
          ? _parseInt(json['quantidade'])
          : _getQuantidadeFromLote(json['lote']),
      flagOferta: json['flag_oferta'] ?? false,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    List<String> caracteristicasIDs =
        caracteristicas?.map((c) => c.id_Caracteristica).toList() ?? [];

    return {
      'id_Produto': id,
      'nome': nome,
      'descricao': descricao,
      'valor_venda': valorVenda,
      'valor_custo': valorCusto,
      'dias_vcto': diasValidade,
      'disponivel': disponivel,
      'fk_id_Endereco': fkIdEndereco,
      'fk_id_Categoria': fkIdCategoria,
      'tamanho': tamanho,
      'valor_venda_desc': valorVendaDesc,
      'caracteristicas_IDs': caracteristicasIDs,
      if (imageId != null) 'id_imagem': imageId,
      if (desconto != null) 'desconto': desconto,
      if (lote != null) (lote is String ? 'id_lote' : 'lote'): lote,
      if (dataFabricacao != null)
        'dt_fabricacao': dataFabricacao!.toIso8601String().split('T')[0],
      'quantidade': quantidade ?? _getQuantidadeFromLote(lote),
      'flag_oferta': flagOferta,
    };
  }

  static Future<Product> fetchProductWithBatch(String productId) async {
    final productResp = await http.get(Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetProductById?id_Produto=$productId'));
    if (productResp.statusCode != 200) {
      throw Exception('Erro ao buscar produto: ${productResp.body}');
    }
    final productJson = jsonDecode(productResp.body);
    final product = Product.fromJson(productJson);

    if (product.id_lote != null && product.id_lote!.isNotEmpty) {
      return product;
    }

    final batchResp = await http.get(Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetBatchByProductId?fk_id_Produto=$productId'));
    if (batchResp.statusCode == 200) {
      final batchJson = jsonDecode(batchResp.body);
      if (batchJson['lotes'] != null &&
          batchJson['lotes'] is List &&
          batchJson['lotes'].isNotEmpty) {
        final loteData = batchJson['lotes'][0];
        return Product(
          id: product.id,
          nome: product.nome,
          descricao: product.descricao,
          valorVenda: product.valorVenda,
          valorCusto: product.valorCusto,
          diasValidade: product.diasValidade,
          disponivel: product.disponivel,
          categoria: product.categoria,
          fkIdEndereco: product.fkIdEndereco,
          fkIdCategoria: product.fkIdCategoria,
          tamanho: product.tamanho,
          valorVendaDesc: product.valorVendaDesc,
          caracteristicas: product.caracteristicas,
          imagemUrl: product.imagemUrl,
          imageId: product.imageId,
          desconto: product.desconto,
          lote: loteData,
          dataFabricacao: product.dataFabricacao,
          quantidade: product.quantidade,
          flagOferta: product.flagOferta,
        );
      }
    }
    return product;
  }
}
