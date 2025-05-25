import 'dart:convert';
import 'dart:typed_data';
import 'product.dart';

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
  final String? imagemUrl;
  final List<Product> produtos;
  final String? telefone;

  Restaurant({
    required this.idEndereco,
    required this.numero,
    required this.logradouro,
    required this.complemento,
    required this.tipoEntrega,
    required this.imagemUrl,
    required this.descricao,
    required this.name,
    required this.cep,
    this.imageString,
    required this.produtos,
    this.telefone,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    var produtosList = json['produtos'] as List?;
    List<Product> productData = produtosList != null
        ? produtosList.map((i) => Product.fromJson(i)).toList()
        : [];

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
      imagemUrl: json['imagem_url'],
      produtos: productData,
      telefone: json['telefone'],
    );
  }

  Uint8List? get imageBytes {
    if (imageString == null || imageString!.isEmpty) return null;
    try {
      return Base64Decoder().convert(imageString!);
    } catch (_) {
      return null;
    }
  }
}

