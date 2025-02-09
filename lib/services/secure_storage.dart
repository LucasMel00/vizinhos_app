import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Tokens de autenticação
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> setIdToken(String token) async {
    await _storage.write(key: 'id_token', value: token);
  }

  Future<String?> getIdToken() async {
    return await _storage.read(key: 'id_token');
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<void> setExpiresIn(int expiresIn) async {
    await _storage.write(key: 'expires_in', value: expiresIn.toString());
  }

  Future<int?> getExpiresIn() async {
    final value = await _storage.read(key: 'expires_in');
    return value != null ? int.parse(value) : null;
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'id_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'expires_in');
  }

  // Métodos para os dados da loja
  Future<void> setStoreInfo(Map<String, dynamic> storeInfo) async {
    await _storage.write(key: 'store_info', value: json.encode(storeInfo));
  }

  Future<Map<String, dynamic>?> getStoreInfo() async {
    try {
      final value = await _storage.read(key: 'store_info');
      if (value == null) return null;

      final decoded = json.decode(value);
      if (decoded is! Map ||
          decoded['storeName'] == null ||
          decoded['categories'] == null) {
        await _storage.delete(key: 'store_info');
        return null;
      }

      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      await _storage.delete(key: 'store_info');
      return null;
    }
  }

  Future<void> deleteStoreInfo() async {
    await _storage.delete(key: 'store_info');
  }

  // Novo método: Retorna todos os tokens armazenados
  Future<Map<String, String?>> getAllTokens() async {
    return {
      'access_token': await getAccessToken(),
      'id_token': await getIdToken(),
      'refresh_token': await getRefreshToken(),
      'expires_in': (await getExpiresIn())?.toString(),
    };
  }

  // Novo método: Retorna todos os dados armazenados
  Future<Map<String, dynamic>?> getAllData() async {
    return {
      'tokens': await getAllTokens(),
      'store_info': await getStoreInfo(),
    };
  }
}
