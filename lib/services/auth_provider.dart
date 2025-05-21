import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  int? _expiresIn;
  bool _isSeller = false;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  Map<String, dynamic> _userInfo = {};
  Map<String, dynamic>? _storeInfo;
  String? _email;
  String? _idEndereco; // Nova propriedade
  String? _fcmToken;
  String? _cpf;

  // Constantes para evitar erros de digitação nas chaves
  static const String KEY_ACCESS_TOKEN = 'accessToken';
  static const String KEY_ID_TOKEN = 'idToken';
  static const String KEY_REFRESH_TOKEN = 'refreshToken';
  static const String KEY_EXPIRES_IN = 'expiresIn';
  static const String KEY_EMAIL = 'email';
  static const String KEY_STORE_INFO = 'storeInfo';
  static const String KEY_ID_ENDERECO = 'idEndereco';
  static const String KEY_FCM_TOKEN = 'fcmToken';
  static const String KEY_CPF = 'cpf';

  final _storage = FlutterSecureStorage();

  // Getters
  String? get accessToken => _accessToken;
  String? get idToken => _idToken;
  String? get refreshToken => _refreshToken;
  int? get expiresIn => _expiresIn;
  bool get isSeller => _isSeller;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _accessToken != null && !_isTokenExpired;
  Map<String, dynamic> get userInfo => _userInfo;
  Map<String, dynamic>? get storeInfo => _storeInfo;
  String? get email => _email;
  String? get idEndereco => _idEndereco;
  String? get fcmToken => _fcmToken;
  String? get cpf => _cpf;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    await _loadAuthData();
    if (isLoggedIn) {
      await _checkSellerStatus();
    }
    _isLoading = false;
    notifyListeners();
  }

  // Adiciona um setter para atualizar o idEndereco

  // Recupera o idEndereco do storage
  Future<void> loadIdEndereco() async {
    _idEndereco = await _storage.read(key: 'idEndereco');
    notifyListeners();
  }

  // Atualiza o idEndereco e armazena no storage
  Future<void> setIdEndereco(String idEndereco) async {
    _idEndereco = idEndereco;
    await _storage.write(key: 'idEndereco', value: idEndereco);
    notifyListeners();
  }

  // Recupera o cpf do storage
  Future<void> loadCpf() async {
    _cpf = await _storage.read(key: KEY_CPF);
    notifyListeners();
  }

  // Atualiza o cpf e armazena no storage
  Future<void> setCpf(String cpf) async {
    _cpf = cpf;
    await _storage.write(key: KEY_CPF, value: cpf);
    notifyListeners();
  }

  // Recupera o fcmToken do storage
  Future<void> loadFcmToken() async {
    _fcmToken = await _storage.read(key: KEY_FCM_TOKEN);
    notifyListeners();
  }

  // Atualiza o fcmToken e armazena no storage
  Future<void> setFcmToken(String fcmToken) async {
    _fcmToken = fcmToken;
    await _storage.write(key: KEY_FCM_TOKEN, value: fcmToken);
    notifyListeners();
  }

  Future<void> _loadAuthData() async {
    try {
      _accessToken = await _storage.read(key: KEY_ACCESS_TOKEN);
      _idToken = await _storage.read(key: KEY_ID_TOKEN);
      _refreshToken = await _storage.read(key: KEY_REFRESH_TOKEN);
      final expiresInStr = await _storage.read(key: KEY_EXPIRES_IN);
      _expiresIn = expiresInStr != null ? int.tryParse(expiresInStr) : null;
      _email = await _storage.read(key: KEY_EMAIL);

      if (_idToken != null) {
        _userInfo = _decodeIdToken(_idToken!);
        _isSeller =
            _userInfo['custom:is_seller']?.toString().toLowerCase() == 'true';
      }
    } catch (e) {
      print('Erro ao carregar tokens: $e');
      await _storage.deleteAll();
      _accessToken = null;
      _idToken = null;
      _refreshToken = null;
      _expiresIn = null;
      _email = null;
      _userInfo = {};
    }
  }

  Future<void> setEmail(String email) async {
    _email = email;
    await _storage.write(key: KEY_EMAIL, value: email);
    notifyListeners();
  }

  Future<void> login({
    required String accessToken,
    required String idToken,
    required String refreshToken,
    required int expiresIn,
    required String email,
  }) async {
    print('AuthProvider: iniciando login');
    try {
      // Atualiza variáveis em memória
      _accessToken = accessToken;
      _idToken = idToken;
      _refreshToken = refreshToken;
      _expiresIn = expiresIn;
      _email = email;

      // Persiste no storage seguro
      await _storage.write(key: KEY_ACCESS_TOKEN, value: accessToken);
      await _storage.write(key: KEY_ID_TOKEN, value: idToken);
      await _storage.write(key: KEY_REFRESH_TOKEN, value: refreshToken);
      await _storage.write(key: KEY_EXPIRES_IN, value: expiresIn.toString());
      await _storage.write(key: KEY_EMAIL, value: email);

      if (_idToken != null) {
        _userInfo = _decodeIdToken(_idToken!);
        _isSeller =
            _userInfo['custom:is_seller']?.toString().toLowerCase() == 'true';
      }

      _isAuthenticated = true;
      print('AuthProvider: login bem-sucedido, notificando listeners');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: erro no login - $e');
      throw Exception('Erro ao armazenar informações de autenticação: $e');
    }
  }

  Future<void> logout() async {
    // Limpar storage seguro
    await _storage.deleteAll();

    // Limpar variáveis em memória
    _accessToken = null;
    _idToken = null;
    _refreshToken = null;
    _expiresIn = null;
    _isSeller = false;
    _userInfo = {};
    _storeInfo = null;
    _email = null;
    _isAuthenticated = false;
    _fcmToken = null;
    _cpf = null;
    _idEndereco = null;

    notifyListeners();
  }

  Map<String, dynamic> _decodeIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) throw Exception('Formato de token inválido');
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  bool get _isTokenExpired {
    if (_expiresIn == null || _idToken == null) return true;
    try {
      final issuedAt = _userInfo['iat'] ?? 0;
      final expirationTime = issuedAt + _expiresIn!;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return currentTime >= expirationTime;
    } catch (_) {
      return true;
    }
  }

  Future<void> _checkSellerStatus() async {
    if (_accessToken == null) return;
    try {
      final response = await http.get(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/user'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sellerValue = data['IsSeller'];
        bool newSellerStatus;
        if (sellerValue is bool) {
          newSellerStatus = sellerValue;
        } else if (sellerValue is String) {
          newSellerStatus = sellerValue.toLowerCase() == 'true';
        } else {
          newSellerStatus = false;
        }
        if (newSellerStatus != _isSeller) {
          _isSeller = newSellerStatus;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void refreshUserData() {
    notifyListeners();
  }

  void updateCpf(cpf) {
    if (_userInfo.containsKey('custom:cpf')) {
      _userInfo['custom:cpf'] = cpf;
    } else {
      _userInfo['custom:cpf'] = cpf;
    }
    notifyListeners();
  }
}
