import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FCMService {
  static const String updateFCMUrl = 'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/UpdateFCM';
  static const String createFCMUrl = 'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/CreateFCM';

  static Future<bool> registerFCMToken({
    required String cpf,
    required String fcmToken,
    http.Client? client,
  }) async {
    try {
      final httpClient = client ?? http.Client();
      final bool updateSuccess = await _updateFCMToken(
        cpf: cpf, 
        fcmToken: fcmToken,
        client: httpClient
      );
      if (updateSuccess) {
        debugPrint('Token FCM atualizado com sucesso');
        return true;
      }
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
      if (response.statusCode == 200) {
        return true;
      }
      debugPrint('Falha ao atualizar token FCM. Código:  24{response.statusCode}, Resposta:  24{response.body}');
      return false;
    } catch (e) {
      debugPrint('Exceção ao atualizar token FCM: $e');
      return false;
    }
  }

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
