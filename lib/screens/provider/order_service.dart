import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/order_models.dart';

class OrdersService {
  final String baseUrl = 'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com';

  Future<OrdersResponse> getOrdersByUser(String cpf) async {
    try {
      final url = Uri.parse('$baseUrl/GetOrdersByUser?cpf=$cpf');
      print("Request URL: $url"); // Debug: print request
      final response = await http.get(url);
      print("Response (${response.statusCode}): ${response.body}"); // Debug: print response

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return OrdersResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        // Usuário não tem pedidos ou CPF não encontrado
        return OrdersResponse(pedidos: []);
      } else {
        throw Exception('Falha ao carregar pedidos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar pedidos: $e');
    }
  }


  Future<bool> updateOrderStatus(String idPedido) async {
    try {
      final url = Uri.parse('$baseUrl/UpdateOrderStatus');
      final body = jsonEncode({"id_Pedido": idPedido});
      print("Request URL: $url"); // Debug: print request;
      print("Request Body: $body"); // Debug: print request body
      print("Id Pedido: $idPedido"); // Debug: print idPedido
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
