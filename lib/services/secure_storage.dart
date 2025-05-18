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
  static const String _idEnderecoKey = 'id_Endereco';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _cpf = 'cpf';
  
  // Mercado Pago keys
  static const String _mercadoPagoTokenKey = 'mercado_pago_token';
  static const String _mercadoPagoSkippedKey = 'mercado_pago_skipped';

  // Token methods
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> setFcmToken(String token) async {
    await _storage.write(key: _fcmTokenKey, value: token);
  }

  Future<String?> getFcmToken() async {
    return await _storage.read(key: _fcmTokenKey);
  }

  Future<void> setCpf(String cpf) async {
    await _storage.write(key: _cpf, value: cpf);
  }

  Future<String?> getCpf() async {
    return await _storage.read(key: _cpf);
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
    await _storage.delete(key: _fcmTokenKey);
    await _storage.delete(key: _cpf);
  }

  // Store info methods
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
  
  Future<void> deleteStoreInfo() async {
    await _storage.delete(key: _storeInfoKey);
  }

  Future<void> setEnderecoId(String idEndereco) async {
    await _storage.write(key: _idEnderecoKey, value: idEndereco);
  }

  Future<String?> getEnderecoId() async {
    return await _storage.read(key: _idEnderecoKey);
  }

  Future<void> deleteEnderecoId() async {
    await _storage.delete(key: _idEnderecoKey);
  }

  // Mercado Pago methods
  Future<void> setMercadoPagoToken(String token) async {
    await _storage.write(key: _mercadoPagoTokenKey, value: token);
    // Quando um token é salvo, automaticamente marcamos como não pulado
    await setMercadoPagoSkipped(false);
  }

  Future<String?> getMercadoPagoToken() async {
    return await _storage.read(key: _mercadoPagoTokenKey);
  }

  Future<void> setMercadoPagoSkipped(bool skipped) async {
    await _storage.write(key: _mercadoPagoSkippedKey, value: skipped.toString());
  }

  Future<bool> getMercadoPagoSkipped() async {
    final value = await _storage.read(key: _mercadoPagoSkippedKey);
    return value == 'true';
  }

  Future<void> deleteMercadoPagoData() async {
    await _storage.delete(key: _mercadoPagoTokenKey);
    await _storage.delete(key: _mercadoPagoSkippedKey);
  }

  // Utilitário geral
  Future<Map<String, String>> readAllValues() async {
    return await _storage.readAll();
  }
}
