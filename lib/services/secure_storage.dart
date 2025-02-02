import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Salva o Access Token
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  // Obtém o Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  // Salva o ID Token
  Future<void> setIdToken(String token) async {
    await _storage.write(key: 'id_token', value: token);
  }

  // Obtém o ID Token
  Future<String?> getIdToken() async {
    return await _storage.read(key: 'id_token');
  }

  // Salva o Refresh Token
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  // Obtém o Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  // Salva o tempo de expiração do token
  Future<void> setExpiresIn(int expiresIn) async {
    await _storage.write(key: 'expires_in', value: expiresIn.toString());
  }

  // Obtém o tempo de expiração do token
  Future<int?> getExpiresIn() async {
    final value = await _storage.read(key: 'expires_in');
    return value != null ? int.parse(value) : null;
  }

  // Remove todos os tokens
  Future<void> deleteTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'id_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'expires_in');
  }
}
