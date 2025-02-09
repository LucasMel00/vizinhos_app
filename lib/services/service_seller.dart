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
  }) async {
    try {
      final authToken = authProvider.accessToken;
      if (authToken == null) throw Exception('Usuário não autenticado');

      final url = Uri.parse(apiUrl);
      // seller_service.dart
      final body = jsonEncode({
        'userId': userId,
        'nomeLoja': storeName, // Alterado de storeName para nomeLoja
        'categorias': categories, // Alterado de categories para categorias
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // Força sincronização após criação
        await authProvider.syncSellerProfile();
      } else {
        throw Exception('Erro ao criar perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao criar perfil de vendedor: $e');
      rethrow;
    }
  }
}
