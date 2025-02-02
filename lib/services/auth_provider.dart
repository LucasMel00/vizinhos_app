import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'secure_storage.dart';

class AuthProvider with ChangeNotifier {
  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  int? _expiresIn;
  bool _isSeller = false;
  bool _isLoading = true;

  final SecureStorage _secureStorage = SecureStorage();

  // Getters
  String? get accessToken => _accessToken;
  String? get idToken => _idToken;
  String? get refreshToken => _refreshToken;
  int? get expiresIn => _expiresIn;
  bool get isSeller => _isSeller;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _accessToken != null && !isTokenExpired;

  AuthProvider() {
    loadAuthData();
  }

  // Carrega os tokens do SecureStorage ao iniciar
  Future<void> loadAuthData() async {
    try {
      print('🔍 Carregando tokens do SecureStorage...');

      _accessToken = await _secureStorage.getAccessToken();
      _idToken = await _secureStorage.getIdToken();
      _refreshToken = await _secureStorage.getRefreshToken();
      _expiresIn = await _secureStorage.getExpiresIn();

      print('✅ Tokens carregados:');
      print(' - Access Token: ${_accessToken != null ? "✔️" : "❌"}');
      print(' - ID Token: ${_idToken != null ? "✔️" : "❌"}');
      print(' - Refresh Token: ${_refreshToken != null ? "✔️" : "❌"}');
      print(' - Expires In: $_expiresIn');

      if (_idToken != null) {
        final userInfo = _decodeIdToken(_idToken!);
        _isSeller =
            userInfo['custom:is_seller']?.toString().toLowerCase() == 'true';
        print('👤 Informações do usuário decodificadas: $userInfo');
      }
    } catch (e) {
      print('❌ Erro ao carregar tokens: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Realiza o login e salva os tokens
  Future<void> login({
    required String accessToken,
    required String idToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    try {
      print('🔐 Salvando tokens no SecureStorage...');

      await _secureStorage.setAccessToken(accessToken);
      await _secureStorage.setIdToken(idToken);
      await _secureStorage.setRefreshToken(refreshToken);
      await _secureStorage.setExpiresIn(expiresIn);

      print('✅ Tokens salvos com sucesso!');

      final userInfo = _decodeIdToken(idToken);
      _isSeller =
          userInfo['custom:is_seller']?.toString().toLowerCase() == 'true';

      _accessToken = accessToken;
      _idToken = idToken;
      _refreshToken = refreshToken;
      _expiresIn = expiresIn;

      notifyListeners();
    } catch (e) {
      print('❌ Erro durante o login: $e');
      rethrow;
    }
  }

  // Realiza o logout e remove os tokens
  Future<void> logout() async {
    print('🚪 Realizando logout...');
    await _secureStorage.deleteTokens();
    _accessToken = null;
    _idToken = null;
    _refreshToken = null;
    _expiresIn = null;
    _isSeller = false;
    notifyListeners();
  }

  // Decodifica o ID Token para extrair informações do usuário
  Map<String, dynamic> _decodeIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) throw Exception('Formato de token inválido');

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      return json.decode(decoded);
    } catch (e) {
      print('❌ Erro ao decodificar ID Token: $e');
      return {};
    }
  }

  // Verifica se o token expirou
  bool get isTokenExpired {
    if (_expiresIn == null || _idToken == null) return true;

    try {
      final issuedAt = _decodeIdToken(_idToken!)['iat'] ?? 0;
      final expirationTime = issuedAt + _expiresIn!;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return currentTime > expirationTime;
    } catch (e) {
      print('❌ Erro ao verificar expiração do token: $e');
      return true;
    }
  }

  // Obtém o ID do usuário a partir do ID Token
  Future<String?> getUserId() async {
    if (_idToken == null) return null;
    final userInfo = _decodeIdToken(_idToken!);
    return userInfo['sub'];
  }

  // Obtém as informações do usuário a partir do ID Token
  Future<Map<String, dynamic>> getUserInfo() async {
    if (_idToken == null) return {};
    return _decodeIdToken(_idToken!);
  }
}
