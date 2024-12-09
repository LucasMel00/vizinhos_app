// lib/services/secure_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Chaves para armazenamento
  static const String _tokenKey = 'authToken';

  // Escrever token
  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Ler token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Deletar token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
