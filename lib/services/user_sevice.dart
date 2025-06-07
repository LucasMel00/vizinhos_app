import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String apiUrl;
  final String authToken;

  UserService({required this.apiUrl, required this.authToken});

  Future<Map<String, dynamic>> getUserInfo(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/GetUserByEmail?email=$email'),
        headers: {},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Falha ao carregar dados do usuário: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro na conexão: $e');
    }
  }
}
