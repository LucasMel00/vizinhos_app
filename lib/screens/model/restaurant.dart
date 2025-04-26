import 'dart:convert';
import 'dart:typed_data';

class Restaurant {
  final String idEndereco;
  final String numero;
  final String logradouro;
  final String complemento;
  final String tipoEntrega;
  final String descricao;
  final String name;
  final String cep;
  final String? imageString;

  Restaurant({
    required this.idEndereco,
    required this.numero,
    required this.logradouro,
    required this.complemento,
    required this.tipoEntrega,
    required this.descricao,
    required this.name,
    required this.cep,
    this.imageString,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      idEndereco: json['id_Endereco'] ?? '',
      numero: json['numero'] ?? '',
      logradouro: json['logradouro'] ?? '',
      complemento: json['complemento'] ?? '',
      tipoEntrega: json['tipo_Entrega'] ?? '',
      descricao: json['descricao_Loja'] ?? '',
      name: json['nome_Loja'] ?? '',
      cep: json['cep'] ?? '',
      imageString: json['id_Imagem'] as String?,
    );
  }

  /// Returns a decoded image as Uint8List, or null if none.
  Uint8List? get imageBytes {
    if (imageString == null || imageString!.isEmpty) return null;
    try {
      return Base64Decoder().convert(imageString!);
    } catch (_) {
      return null;
    }
  }
}
