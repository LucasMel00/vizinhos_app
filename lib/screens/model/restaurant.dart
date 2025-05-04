import 'dart:convert';
import 'dart:typed_data';
import 'product.dart'; // Import Product model

class Restaurant {
  final String idEndereco;
  final String numero;
  final String logradouro;
  final String complemento;
  final String tipoEntrega;
  final String descricao;
  final String name;
  final String cep;
  final String? imageString; // Corresponds to id_Imagem
  final String? imagemUrl; // Corresponds to imagem_url (store profile image)
  final List<Product> produtos; // List of products

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
      produtos: productData, // Assign the parsed product list
    );
  }

  /// Returns a decoded image as Uint8List, or null if none.
  /// This likely refers to id_Imagem, not imagem_url which is a direct URL.
  Uint8List? get imageBytes {
    if (imageString == null || imageString!.isEmpty) return null;
    try {
      // Assuming id_Imagem might be base64, though it looks like a filename.
      // If it's just a filename, this getter might not be useful unless combined with a base URL.
      // Let's keep it for now, but be aware it might need adjustment based on how id_Imagem is used.
      return Base64Decoder().convert(imageString!);
    } catch (_) {
      return null;
    }
  }
}

