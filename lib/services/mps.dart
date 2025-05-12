import 'dart:convert';
import 'package:http/http.dart' as http;

class MercadoPagoService {
  static const String _baseUrl = 'https://api.mercadopago.com/v1';
  final String accessToken;

  MercadoPagoService(this.accessToken);

  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    final url = Uri.parse('$_baseUrl/payments/$paymentId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao consultar pagamento: ${response.statusCode}');
    }
  }
}
