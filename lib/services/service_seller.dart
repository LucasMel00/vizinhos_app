import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/services/auth_provider.dart';

class SellerService {
  final String apiUrl;
  final AuthProvider authProvider;

  SellerService({
    required this.apiUrl,
    required this.authProvider,
  });

  /// Cria o perfil de vendedor enviando os seguintes campos:
  /// - userId
  /// - storeName
  /// - categorias
  /// - descricaoCurta
  /// - fotoPerfil (opcional, em base64)
  /// - fotoPerfilType (opcional, ex: image/jpeg)
  Future<void> createSellerProfile({
    required String userId,
    required String storeName,
    required List<String> categories,
    required String description,
    String? fotoPerfil,
    String? fotoPerfilType,
  }) async {
    final authToken = authProvider.accessToken;
    if (authToken == null) {
      throw Exception('Usuário não autenticado');
    }

    final url = Uri.parse(apiUrl);

    // Agora usamos "storeName" no lugar de "nomeLoja"
    final body = jsonEncode({
      'userId': userId,
      'storeName': storeName,
      'categorias': categories,
      'descricaoCurta': description,
      if (fotoPerfil != null) 'fotoPerfil': fotoPerfil,
      if (fotoPerfilType != null) 'fotoPerfilType': fotoPerfilType,
    });

    print("----- REQUISIÇÃO SENDO GERADA -----");
    print("URL: $url");
    print("Headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $authToken' }");
    print("Body: $body");
    print("----- FIM DA REQUISIÇÃO -----");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: body,
    );

    print("----- RESPOSTA RECEBIDA -----");
    print("Status Code: ${response.statusCode}");
    print("Body da resposta: ${response.body}");
    print("----- FIM DA RESPOSTA -----");

    if (response.statusCode != 200) {
      throw Exception(
          'Erro ao criar perfil de vendedor: ${response.body}, status code: ${response.statusCode}');
    }
  }
}
