import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FCMService {
  // URLs das APIs
  static const String updateFCMUrl = 'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateFCM';
  static const String createFCMUrl = 'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/CreateFCM';

  /// Função principal para registrar ou atualizar o token FCM
  /// Implementa a lógica de "tentar atualizar primeiro, criar se falhar"
  static Future<bool> registerFCMToken({
    required String cpf,
    required String fcmToken,
    http.Client? client,
  }) async {
    try {
      final httpClient = client ?? http.Client();
      
      // Primeiro, tenta atualizar o token
      final bool updateSuccess = await _updateFCMToken(
        cpf: cpf, 
        fcmToken: fcmToken,
        client: httpClient
      );
      
      // Se a atualização for bem-sucedida, retorna true
      if (updateSuccess) {
        debugPrint('Token FCM atualizado com sucesso');
        return true;
      }
      
      // Se a atualização falhar, tenta criar um novo registro
      final bool createSuccess = await _createFCMToken(
        cpf: cpf, 
        fcmToken: fcmToken,
        client: httpClient
      );
      
      if (createSuccess) {
        debugPrint('Token FCM criado com sucesso após falha na atualização');
        return true;
      } else {
        debugPrint('Falha ao criar token FCM após falha na atualização');
        return false;
      }
    } catch (e) {
      debugPrint('Erro ao registrar token FCM: $e');
      return false;
    }
  }

  /// Tenta atualizar o token FCM existente
  static Future<bool> _updateFCMToken({
    required String cpf,
    required String fcmToken,
    required http.Client client,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(updateFCMUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'cpf': cpf,
          'fcmToken': fcmToken,
        }),
      );

      // Verifica se a atualização foi bem-sucedida (código 200)
      if (response.statusCode == 200) {
        return true;
      }
      
      // Se o código for 404 (usuário não encontrado) ou qualquer outro erro,
      // retorna false para que a função principal tente criar um novo registro
      debugPrint('Falha ao atualizar token FCM. Código: ${response.statusCode}, Resposta: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Exceção ao atualizar token FCM: $e');
      return false;
    }
  }

  /// Tenta criar um novo registro de token FCM
  static Future<bool> _createFCMToken({
    required String cpf,
    required String fcmToken,
    required http.Client client,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(createFCMUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'cpf': cpf,
          'fcmToken': fcmToken,
        }),
      );

      // Verifica se a criação foi bem-sucedida (código 200)
      if (response.statusCode == 200) {
        return true;
      }
      
      debugPrint('Falha ao criar token FCM. Código: ${response.statusCode}, Resposta: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Exceção ao criar token FCM: $e');
      return false;
    }
  }
}
