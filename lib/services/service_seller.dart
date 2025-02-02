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

  /// Cria o perfil de vendedor enviando os campos:
  /// - userId
  /// - nomeLoja
  /// - categorias
  Future<void> createSellerProfile({
    required String userId,
    required String storeName,
    required List<String> categories,
  }) async {
    final authToken = authProvider.accessToken;
    if (authToken == null) {
      throw Exception('Usuário não autenticado');
    }

    final url = Uri.parse(apiUrl);

    // Cria o payload conforme o modelo desejado
    final body = jsonEncode({
      'userId': userId,
      'nomeLoja': storeName,
      'categorias': categories,
    });

    // Log para ver como a requisição está sendo gerada
    print("----- REQUISIÇÃO SENDO GERADA -----");
    print("URL: $url");
    print(
        "Headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }");
    print("Body: $body");
    print("----- FIM DA REQUISIÇÃO -----");

    // Envia a requisição HTTP POST
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );

    // Log completo da resposta
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
