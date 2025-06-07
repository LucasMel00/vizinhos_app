import 'package:http/http.dart' as http;
import 'dart:convert';

class VendorService {
  static Future<Map<String, dynamic>> getStoreData(String idEndereco) async {
    try {
      final url = Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetAddressById?id_Endereco=$idEndereco');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load store data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load store data: $e');
    }
  }
}
