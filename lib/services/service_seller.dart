import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SellerService {
  final String apiUrl;
  final String authToken;

  SellerService({required this.apiUrl, required this.authToken});

  Future<Map<String, dynamic>> createSellerProfile({
    required String userId,
    required String storeName,
    required List<String> categories,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/seller'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'userId': userId,
          'nomeLoja': storeName,
          'categorias': categories,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Falha ao criar perfil de vendedor: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro na conexão: $e');
    }
  }

  Future<Map<String, dynamic>> getSellerProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/user/$userId'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Falha ao obter perfil: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro na conexão: $e');
    }
  }
}
