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
  /// - nomeLoja
  /// - categorias
  /// - descricaoCurta
  /// - endereco (CEP, rua, bairro, número, complemento)
  /// - fotoPerfil (opcional, em base64)
  /// - fotoPerfilType (opcional, ex: image/jpeg)
  Future<void> createSellerProfile({
    required String userId,
    required String storeName,
    required List<String> categories,
    required String description,
    required Map<String, String> address,
    String? fotoPerfil,
    String? fotoPerfilType,
  }) async {
    final authToken = authProvider.accessToken;
    if (authToken == null) {
      throw Exception('Usuário não autenticado');
    }

    final url = Uri.parse(apiUrl);

    // Cria o payload conforme o modelo esperado pela API
    final body = jsonEncode({
      'userId': userId,
      'nomeLoja': storeName,
      'categorias': categories,
      'descricaoCurta': description,
      'endereco': {
        'CEP': address['CEP'],
        'rua': address['rua'],
        'bairro': address['bairro'],
        'numero': address['numero'],
        'complemento': address['complemento'],
      },
      if (fotoPerfil != null) 'fotoPerfil': fotoPerfil,
      if (fotoPerfilType != null) 'fotoPerfilType': fotoPerfilType,
    });

    print("----- REQUISIÇÃO SENDO GERADA -----");
    print("URL: $url");
    print(
        "Headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $authToken' }");
    print("Body: $body");
    print("----- FIM DA REQUISIÇÃO -----");

    // Envia a requisição HTTP POST
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
