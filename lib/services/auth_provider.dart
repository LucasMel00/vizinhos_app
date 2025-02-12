import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/vendor/create_store_screen.dart';
import 'secure_storage.dart';

class AuthProvider with ChangeNotifier {
  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  int? _expiresIn;
  bool _isSeller = false;
  bool _isLoading = true;
  Map<String, dynamic> _userInfo = {};
  Map<String, dynamic>? _storeInfo;
  Map<String, dynamic>? get storeInfo => _storeInfo;

  final SecureStorage _secureStorage = SecureStorage();

  // Getters
  String? get accessToken => _accessToken;
  String? get idToken => _idToken;
  String? get refreshToken => _refreshToken;
  int? get expiresIn => _expiresIn;
  bool get isSeller => _isSeller;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _accessToken != null && !_isTokenExpired;
  Map<String, dynamic> get userInfo => _userInfo;

  AuthProvider() {
    print('🔄 AuthProvider inicializado');
    _initAuth();
  }

  Future<void> _initAuth() async {
    print('🔍 Iniciando carga de dados de autenticação...');
    await loadAuthData();
    if (isLoggedIn) {
      print('🔐 Usuário já autenticado. Verificando status de vendedor...');
      await _checkSellerStatus();
    }
  }

  Future<void> loadAuthData() async {
    try {
      print('🔑 Buscando tokens no SecureStorage...');
      _accessToken = await _secureStorage.getAccessToken();
      _idToken = await _secureStorage.getIdToken();
      _refreshToken = await _secureStorage.getRefreshToken();
      _expiresIn = await _secureStorage.getExpiresIn();

      print('✅ Tokens recuperados:');
      print(
          ' - Access Token: ${_accessToken != null ? "✔️ (${_accessToken!.substring(0, 15)}...)" : "❌"}');
      print(
          ' - ID Token: ${_idToken != null ? "✔️ (${_idToken!.substring(0, 15)}...)" : "❌"}');
      print(
          ' - Refresh Token: ${_refreshToken != null ? "✔️ (${_refreshToken!.substring(0, 15)}...)" : "❌"}');
      print(' - Expira em: $_expiresIn segundos');

      if (_idToken != null) {
        print('🔓 Decodificando ID Token...');
        _userInfo = _decodeIdToken(_idToken!);
        _isSeller =
            _userInfo['custom:is_seller']?.toString().toLowerCase() == 'true';
        print('👤 Informações do usuário:');
        print(' - User ID: ${_userInfo['sub']}');
        print(' - E-mail: ${_userInfo['email']}');
        print(' - Vendedor: $_isSeller');
      }
    } catch (e, stack) {
      print('‼️ ERRO ao carregar dados de autenticação: $e');
      print('Stack trace: $stack');
      await _secureStorage.deleteTokens();
    } finally {
      _isLoading = false;
      print('🏁 Carga de autenticação concluída');
      notifyListeners();
    }
  }

  Future<void> login({
    required String accessToken,
    required String idToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    try {
      print('🔐 Iniciando processo de login...');

      await _secureStorage.setAccessToken(accessToken);
      await _secureStorage.setIdToken(idToken);
      await _secureStorage.setRefreshToken(refreshToken);
      await _secureStorage.setExpiresIn(expiresIn);

      _accessToken = accessToken;
      _idToken = idToken;
      _refreshToken = refreshToken;
      _expiresIn = expiresIn;

      print('🔓 Decodificando novo ID Token...');
      _userInfo = _decodeIdToken(idToken);
      _isSeller =
          _userInfo['custom:is_seller']?.toString().toLowerCase() == 'true';

      print('🔄 Verificando status de vendedor na API...');
      await _checkSellerStatus();

      print('🎉 Login realizado com sucesso!');
      notifyListeners();
    } catch (e, stack) {
      print('‼️ ERRO durante o login: $e');
      print('Stack trace: $stack');
      await logout();
      rethrow;
    }
  }

  Future<void> logout() async {
    print('🚪 Iniciando logout...');
    try {
      await _secureStorage.deleteTokens();
      _accessToken = null;
      _idToken = null;
      _refreshToken = null;
      _expiresIn = null;
      _isSeller = false;
      _userInfo = {};
      print('✅ Logout realizado com sucesso');
      notifyListeners();
    } catch (e, stack) {
      print('‼️ ERRO durante logout: $e');
      print('Stack trace: $stack');
    }
  }

  Future<void> fetchUserDataFromAPI() async {
    if (_accessToken == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/user'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final newData = json.decode(response.body);
        print('📦 Novos dados recebidos: $newData');

        // Atualiza o status de vendedor
        final sellerValue = newData['IsSeller'];
        if (sellerValue is bool) {
          _isSeller = sellerValue;
        } else if (sellerValue is String) {
          _isSeller = sellerValue.toLowerCase() == 'true';
        } else {
          _isSeller = false;
        }

        // Se houver sellerProfile, armazene no Secure Storage e na variável local
        if (newData.containsKey('sellerProfile') &&
            newData['sellerProfile'] != null) {
          _storeInfo = newData['sellerProfile'];
          await _secureStorage.setStoreInfo(_storeInfo!);
        } else {
          // Se não houver sellerProfile, pode limpar o que estiver salvo
          await _secureStorage.deleteStoreInfo();
          _storeInfo = null;
        }

        // Atualiza outras informações do usuário (caso deseje armazená-las)
        _userInfo = {..._userInfo, ...newData};

        // Se desejar, também atualize o ID Token caso ele venha na resposta
        if (newData.containsKey('IdToken')) {
          _idToken = newData['IdToken'];
          await _secureStorage.setIdToken(_idToken!);
          _userInfo = _decodeIdToken(_idToken!);
        }

        notifyListeners();
      } else {
        print('‼️ Falha na requisição: ${response.statusCode}');
      }
    } catch (e, stack) {
      print('‼️ Erro ao buscar dados do usuário: $e');
      print('Stack trace: $stack');
    }
  }

  Future<void> updateSellerStatus(bool status) async {
    print('🔄 Atualizando status de vendedor para: $status');
    try {
      _isSeller = status;
      _userInfo = {..._userInfo, 'custom:is_seller': status.toString()};

      if (_idToken != null) {
        await _secureStorage.setIdToken(_idToken!);
      }

      print('✅ Status de vendedor atualizado');
      notifyListeners();
    } catch (e, stack) {
      print('‼️ ERRO ao atualizar status de vendedor: $e');
      print('Stack trace: $stack');
    }
  }

  Future<void> checkSellerStore(BuildContext context) async {
    if (!_isSeller) return;

    // Verifica primeiro se já temos _storeInfo carregado em memória
    if (_storeInfo != null) return;

    // Se não, busca no Secure Storage
    final storeInfo = await _secureStorage.getStoreInfo();

    if (storeInfo == null) {
      // Se não houver loja, redireciona para a tela de criação
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateStoreScreen(
            userId: _userInfo['sub'] ?? '',
          ),
        ),
      );
    } else {
      _storeInfo = storeInfo;
      notifyListeners();
    }
  }

  Future<void> _checkSellerStatus() async {
    if (_accessToken == null) return;

    print('🔍 Verificando status de vendedor na API...');
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

        print('📊 Resposta da API - É vendedor? $newSellerStatus');

        if (newSellerStatus != _isSeller) {
          print('🔄 Atualizando status local de vendedor');
          _isSeller = newSellerStatus;
          notifyListeners();
        }
      } else {
        print('⚠️ Falha ao verificar status: ${response.statusCode}');
      }
    } catch (e, stack) {
      print('‼️ ERRO ao verificar status de vendedor: $e');
      print('Stack trace: $stack');
    }
  }

  Map<String, dynamic> _decodeIdToken(String idToken) {
    try {
      print('🔍 Decodificando ID Token...');
      final parts = idToken.split('.');
      if (parts.length != 3) throw Exception('Formato de token inválido');

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final jsonMap = json.decode(decoded) as Map<String, dynamic>;

      print('✅ ID Token decodificado com sucesso');
      return jsonMap;
    } catch (e, stack) {
      print('‼️ ERRO ao decodificar ID Token: $e');
      print('Stack trace: $stack');
      return {};
    }
  }

  bool get _isTokenExpired {
    if (_expiresIn == null || _idToken == null) {
      print('⏳ Token expirado ou não disponível');
      return true;
    }

    try {
      final issuedAt = _userInfo['iat'] ?? 0;
      final expirationTime = issuedAt + _expiresIn!;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      print('⏰ Verificando expiração do token:');
      print(' - Emitido em: $issuedAt');
      print(' - Expira em: $expirationTime');
      print(' - Tempo atual: $currentTime');

      return currentTime >= expirationTime;
    } catch (e, stack) {
      print('‼️ ERRO ao verificar expiração do token: $e');
      print('Stack trace: $stack');
      return true;
    }
  }

  Future<void> refreshAuthToken() async {
    print('🔄 Tentativa de refresh do token...');
    try {
      final response = await http.post(
        Uri.parse('https://seu-domínio/refresh-token'),
        body: {'refresh_token': _refreshToken},
      );

      if (response.statusCode == 200) {
        final newTokens = json.decode(response.body);
        await login(
          accessToken: newTokens['access_token'],
          idToken: newTokens['id_token'],
          refreshToken: newTokens['refresh_token'],
          expiresIn: newTokens['expires_in'],
        );
        print('✅ Token atualizado com sucesso');
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e, stack) {
      print('‼️ ERRO ao atualizar token: $e');
      print('Stack trace: $stack');
      await logout();
    }
  }

  Future<void> refreshUserData() async {
    print('🔄 Forçando atualização completa dos dados do usuário');
    try {
      // 1. Recarrega tokens do armazenamento local
      await loadAuthData();

      // 2. Verifica se o token ainda é válido
      if (_isTokenExpired && _refreshToken != null) {
        print('⚠️ Token expirado, tentando renovar...');
        await refreshAuthToken();
      }

      // 3. Atualiza dados do usuário na API
      final response = await http.get(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/user'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final newData = json.decode(response.body);
        print('📦 Novos dados recebidos: $newData');

        // 4. Atualiza o status de vendedor
        final sellerValue = newData['IsSeller'];
        if (sellerValue is bool) {
          _isSeller = sellerValue;
        } else if (sellerValue is String) {
          _isSeller = sellerValue.toLowerCase() == 'true';
        } else {
          _isSeller = false;
        }

        // 5. Se houver sellerProfile, salva-o
        if (newData.containsKey('sellerProfile') &&
            newData['sellerProfile'] != null) {
          _storeInfo = newData['sellerProfile'];
          await _secureStorage.setStoreInfo(_storeInfo!);
        }

        // 6. Atualiza ID Token se necessário
        if (newData.containsKey('IdToken')) {
          _idToken = newData['IdToken'];
          await _secureStorage.setIdToken(_idToken!);
          _userInfo = _decodeIdToken(_idToken!);
        }

        // 7. Merge dos novos dados com os existentes
        _userInfo = {..._userInfo, ...newData};

        print('✅ Dados atualizados com sucesso');
        notifyListeners();
      } else {
        print('‼️ Falha na atualização: ${response.statusCode}');
        throw Exception('Failed to refresh user data');
      }
    } catch (e, stack) {
      print('‼️ ERRO crítico na atualização: $e');
      print('Stack trace: $stack');
      await logout();
      rethrow;
    }
  }

  void debugAuthState() {
    print('\n=== DEBUG AUTH STATE ===');
    print('Usuário logado: ${isLoggedIn ? "✅" : "❌"}');
    print('Tipo de usuário: ${_isSeller ? "Vendedor" : "Cliente"}');
    print('ID do usuário: ${_userInfo['sub'] ?? "N/A"}');
    print('Expira em: $_expiresIn segundos');
    print('Tokens válidos: ${!_isTokenExpired ? "✅" : "❌"}');
    print('========================\n');
  }
}
