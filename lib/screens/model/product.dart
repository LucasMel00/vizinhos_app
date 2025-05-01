import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert'; // Import for jsonDecode

// Define the Characteristic class
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
  List<Characteristic>? caracteristicas; // Null check for characteristics
  final String? imagemUrl;
  final String? imageId;
  final double? desconto;
  final String? lote;
  final DateTime? dataFabricacao;
  final int? quantidade;

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
    required this.caracteristicas, // Changed parameter name
    this.imagemUrl,
    this.imageId,
    this.desconto,
    this.lote,
    this.dataFabricacao,
    required this.quantidade,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Updated function to parse characteristics
    List<Characteristic> parseCharacteristics(dynamic characteristicsJson) {
      if (characteristicsJson == null) return [];
      if (characteristicsJson is List) {
        return characteristicsJson
            .where((item) => item is Map<String, dynamic>)
            .map(
                (item) => Characteristic.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      // Handle if characteristicsJson is a stringified JSON array (less ideal but possible)
      if (characteristicsJson is String) {
        try {
          List<dynamic> decodedList = jsonDecode(characteristicsJson);
          return decodedList
              .where((item) => item is Map<String, dynamic>)
              .map((item) =>
                  Characteristic.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print('Error decoding characteristics string: $e');
          return [];
        }
      }
      return [];
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
      // Updated parsing logic for characteristics
      caracteristicas: parseCharacteristics(json['caracteristicas']),
      imagemUrl: json['imagem_url'],
      imageId: json['id_imagem']?.toString(),
      desconto: _parseDouble(json['desconto']),
      lote: json['lote']?.toString(),
      dataFabricacao: json['dt_fabricacao'] != null
          ? DateTime.tryParse(json['dt_fabricacao'])
          : null,
      quantidade: _parseInt(json['quantidade']),
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
    // Convert List<Characteristic> back to List<String> (IDs only) for sending
    // Assuming the backend expects only IDs when updating/creating
    List<String> caracteristicasIDs =
        caracteristicas!.map((c) => c.id_Caracteristica).toList();

    return {
      'id_Produto': id,
      'nome': nome,
      'descricao': descricao,
      'valor_venda': valorVenda,
      'valor_custo': valorCusto,
      'dias_vcto': diasValidade,
      'disponivel': disponivel,
      // 'categoria': categoria, // Categoria seems to be derived info, not sent back?
      'fk_id_Endereco': fkIdEndereco,
      'fk_id_Categoria': fkIdCategoria,
      'tamanho': tamanho,
      'valor_venda_desc': valorVendaDesc,
      'caracteristicas_IDs': caracteristicasIDs, // Sending only IDs back
      if (imageId != null) 'id_imagem': imageId,
      // if (desconto != null) 'desconto': desconto, // Desconto seems derived?
      // if (lote != null) 'lote': lote, // Lote seems derived?
      // if (dataFabricacao != null)
      //   'dt_fabricacao': dataFabricacao!.toIso8601String().split('T')[0], // Data fabricacao seems derived?
      'quantidade': quantidade,
    };
  }
}
