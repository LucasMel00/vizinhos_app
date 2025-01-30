// lib/services/auth_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  int? _expiresIn;
  bool _isSeller = false;
  bool _isLoading = true;

  // Getters
  String? get accessToken => _accessToken;
  String? get idToken => _idToken;
  String? get refreshToken => _refreshToken;
  int? get expiresIn => _expiresIn;
  bool get isSeller => _isSeller;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _accessToken != null;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    _accessToken = prefs.getString('accessToken');
    _idToken = prefs.getString('idToken');
    _refreshToken = prefs.getString('refreshToken');
    _expiresIn = prefs.getInt('expiresIn');
    _isSeller = prefs.getBool('isSeller') ?? false;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login({
    required String accessToken,
    required String idToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('accessToken', accessToken);
    await prefs.setString('idToken', idToken);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setInt('expiresIn', expiresIn);

    // Decodificar o token para obter informações do usuário
    final userInfo = _decodeIdToken(idToken);
    _isSeller =
        userInfo['is_seller'] == true || userInfo['is_seller'] == 'true';
    await prefs.setBool('isSeller', _isSeller);

    _accessToken = accessToken;
    _idToken = idToken;
    _refreshToken = refreshToken;
    _expiresIn = expiresIn;

    notifyListeners();
  }

  Map<String, dynamic> _decodeIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token');
      }

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding ID token: $e');
      return {};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('accessToken');
    await prefs.remove('idToken');
    await prefs.remove('refreshToken');
    await prefs.remove('expiresIn');
    await prefs.remove('isSeller');

    _accessToken = null;
    _idToken = null;
    _refreshToken = null;
    _expiresIn = null;
    _isSeller = false;

    notifyListeners();
  }

  Future<String?> getUserId() async {
    if (_idToken == null) return null;
    final userInfo = _decodeIdToken(_idToken!);
    return userInfo['sub'];
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    if (_idToken == null) return {};
    return _decodeIdToken(_idToken!);
  }

  // Verifica se o token está expirado
  bool get isTokenExpired {
    if (_expiresIn == null) return true;
    final issuedAt = _decodeIdToken(_idToken!)['iat'] ?? 0;
    final expirationTime = issuedAt + _expiresIn!;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 > expirationTime;
  }
}
