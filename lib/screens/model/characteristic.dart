import 'dart:convert';
import 'dart:typed_data';

class Characteristic {
  final String idCaracteristica; // Nome no padrão Dart (camelCase)
  final String descricao;

  Characteristic({
    required this.idCaracteristica,
    required this.descricao,
  });

  factory Characteristic.fromJson(Map<String, dynamic> json) {
    return Characteristic(
      idCaracteristica: json['id_Caracteristica']?.toString() ?? '', // Mapeia do JSON snake_case
      descricao: json['descricao']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_Caracteristica': idCaracteristica, // Mantém snake_case para a API
      'descricao': descricao,
    };
  }
}