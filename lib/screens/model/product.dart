import 'dart:convert';

import 'package:vizinhos_app/screens/model/lote.dart';

// Classe Characteristic
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

// Classe Product
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
  final dynamic lote; // Pode ser objeto Lote ou apenas o id_lote (String)
  final DateTime? dataFabricacao;
  final int? quantidade;
  final bool flagOferta; // Adicionado campo para flag de oferta

  // Getter para manter compatibilidade com código antigo
 String? get id_lote {
  if (lote == null) return null;
  if (lote is String) return lote as String;
  if (lote is Map<String, dynamic> && lote['id'] != null) {
    return lote['id']?.toString();
  }
  if (lote is Map<String, dynamic> && lote['id_Lote'] != null) {
    return lote['id_Lote']?.toString();
  }
  if (lote is Lote) {
    return lote.idLote;
  }
  return null;
}

  // Função auxiliar para obter a quantidade a partir do lote, se presente
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
    this.flagOferta = false, // Valor padrão false
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

    // Lote pode ser um objeto ou apenas um id_lote
    dynamic loteObj;
    
   if (json['lote'] != null) {
  // Se for um Map, tenta converter para Lote
  if (json['lote'] is Map<String, dynamic>) {
    loteObj = Lote.fromJson(json['lote']);
  } else {
    loteObj = json['lote']; // Caso não seja um Map
  }
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
      flagOferta: json['flag_oferta'] ?? false, // Mapeamento da flag de oferta
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
      // Envia id_lote se for string, ou lote se for objeto
      if (lote != null) (lote is String ? 'id_lote' : 'lote'): lote,
      if (dataFabricacao != null)
        'dt_fabricacao': dataFabricacao!.toIso8601String().split('T')[0],
      'quantidade': quantidade ?? _getQuantidadeFromLote(lote),
      'flag_oferta': flagOferta, // Incluir flag de oferta no JSON
    };
  }
}
