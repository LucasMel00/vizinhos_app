// lib/services/auth_provider.dart

import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  int? _expiresIn;

  // Getters para acessar os tokens
  String? get accessToken => _accessToken;
  String? get idToken => _idToken;
  String? get refreshToken => _refreshToken;
  int? get expiresIn => _expiresIn;

  // Verifica se o usuário está autenticado
  bool get isAuthenticated => _accessToken != null;

  // Carrega os tokens armazenados ao iniciar o aplicativo
  Future<void> loadTokens() async {
    final tokens = await _authService.getTokens();
    _accessToken = tokens['accessToken'];
    _idToken = tokens['idToken'];
    _refreshToken = tokens['refreshToken'];
    _expiresIn = tokens['expiresIn'];
    notifyListeners();
  }

  // Salva os tokens após o login
  Future<void> login({
    required String accessToken,
    required String idToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    _accessToken = accessToken;
    _idToken = idToken;
    _refreshToken = refreshToken;
    _expiresIn = expiresIn;
    await _authService.saveTokens({
      'accessToken': accessToken,
      'idToken': idToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    });
    notifyListeners();
  }

  // Remove os tokens ao fazer logout
  Future<void> logout() async {
    _accessToken = null;
    _idToken = null;
    _refreshToken = null;
    _expiresIn = null;
    await _authService.deleteTokens();
    notifyListeners();
  }
}
