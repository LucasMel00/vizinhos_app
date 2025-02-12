import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys for storing data
  static const String _accessTokenKey = 'access_token';
  static const String _idTokenKey = 'id_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresInKey = 'expires_in';
  static const String _storeInfoKey = 'store_info';

  // Methods for tokens

  Future<void> setAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> setIdToken(String token) async {
    await _storage.write(key: _idTokenKey, value: token);
  }

  Future<String?> getIdToken() async {
    return await _storage.read(key: _idTokenKey);
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> setExpiresIn(int seconds) async {
    await _storage.write(key: _expiresInKey, value: seconds.toString());
  }

  Future<int?> getExpiresIn() async {
    final value = await _storage.read(key: _expiresInKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresInKey);
  }

  // Methods for store information

  /// Stores the seller’s store information as a JSON string.
  Future<void> setStoreInfo(Map<String, dynamic> storeInfo) async {
    await _storage.write(key: _storeInfoKey, value: json.encode(storeInfo));
  }

  Future<Map<String, dynamic>?> getStoreInfo() async {
    final storeInfoJson = await _storage.read(key: _storeInfoKey);
    if (storeInfoJson != null) {
      return Map<String, dynamic>.from(json.decode(storeInfoJson));
    }
    return null;
  }

  /// Deletes the stored seller’s store information.
  Future<void> deleteStoreInfo() async {
    await _storage.delete(key: _storeInfoKey);
  }

  /// Retorna todos os valores armazenados no Secure Storage.
  Future<Map<String, String>> readAllValues() async {
    return await _storage.readAll();
  }
}
