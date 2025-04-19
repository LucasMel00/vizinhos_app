import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vizinhos_app/services/auth_provider.dart'; // Importa o AuthProvider

class ApiService {
  final AuthProvider _authProvider = AuthProvider(); // Instancia o AuthProvider

  // Método para obter os dados da loja
  Future<Map<String, dynamic>?> fetchStoreById(String idEndereco) async {
    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetAddressById?id_Endereco=$idEndereco');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Retorna os dados da loja
      } else {
        throw Exception('Falha ao carregar dados da loja');
      }
    } catch (e) {
      print('Erro ao obter dados da loja: $e');
      return null;
    }
  }
}
