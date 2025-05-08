import 'dart:convert';
import 'dart:typed_data';

class Characteristic {
  final String idCaracteristica;
  final String descricao;

  Characteristic({
    required this.idCaracteristica,
    required this.descricao,
  });

  factory Characteristic.fromJson(Map<String, dynamic> json) {
    return Characteristic(
      idCaracteristica: json['id_Caracteristica'] ?? '',
      descricao: json['descricao'] ?? '',
    );
  }
}

