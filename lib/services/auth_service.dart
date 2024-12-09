// lib/services/auth_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Chaves para armazenar os tokens
  static const String _accessTokenKey = 'accessToken';
  static const String _idTokenKey = 'idToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _expiresInKey = 'expiresIn';

  // Salvar todos os tokens
  Future<void> saveTokens(Map<String, dynamic> tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens['accessToken']);
    await _storage.write(key: _idTokenKey, value: tokens['idToken']);
    await _storage.write(key: _refreshTokenKey, value: tokens['refreshToken']);
    await _storage.write(key: _expiresInKey, value: tokens['expiresIn'].toString());
  }

  // Obter todos os tokens
  Future<Map<String, dynamic>> getTokens() async {
    String? accessToken = await _storage.read(key: _accessTokenKey);
    String? idToken = await _storage.read(key: _idTokenKey);
    String? refreshToken = await _storage.read(key: _refreshTokenKey);
    String? expiresInStr = await _storage.read(key: _expiresInKey);
    int? expiresIn = expiresInStr != null ? int.tryParse(expiresInStr) : null;

    return {
      'accessToken': accessToken,
      'idToken': idToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }

  // Obter apenas o accessToken
  Future<String?> getToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Deletar todos os tokens
  Future<void> deleteTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresInKey);
  }
}
