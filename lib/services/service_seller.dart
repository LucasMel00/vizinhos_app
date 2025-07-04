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

    final body = jsonEncode({
      'userId': userId,
      'nomeLoja': storeName,
      'categorias': categories,
      'descricaoCurta': description,
      if (fotoPerfil != null) 'fotoPerfil': fotoPerfil,
      if (fotoPerfilType != null) 'fotoPerfilType': fotoPerfilType,
    });

    print("----- REQUISIÇÃO SENDO GERADA -----");
    print("URL:  24{url}");
    print(
        "Headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer  24{authToken}' }");
    print("Body:  24{body}");
    print("----- FIM DA REQUISIÇÃO -----");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer  24{authToken}',
      },
      body: body,
    );

    print("----- RESPOSTA RECEBIDA -----");
    print("Status Code:  24{response.statusCode}");
    print("Body da resposta:  24{response.body}");
    print("----- FIM DA RESPOSTA -----");

    if (response.statusCode != 200) {
      throw Exception(
          'Erro ao criar perfil de vendedor:  24{response.body}, status code:  24{response.statusCode}');
    }
  }
}
