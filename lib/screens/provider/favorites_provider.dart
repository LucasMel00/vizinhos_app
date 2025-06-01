import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vizinhos_app/screens/model/restaurant.dart';

class FavoritesProvider with ChangeNotifier {
  static const String _favoritesKey = 'favorite_stores';
  List<Restaurant> _favoriteStores = [];

  List<Restaurant> get favoriteStores => [..._favoriteStores];

  FavoritesProvider() {
    _loadFavorites();
  }

  // Carrega os favoritos do SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesString = prefs.getString(_favoritesKey);
      
      if (favoritesString != null) {
        final List<dynamic> decodedJson = jsonDecode(favoritesString);
        _favoriteStores = decodedJson
            .map((jsonItem) => Restaurant.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar favoritos: $e');
    }
  }

  // Salva os favoritos no SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedJson = jsonEncode(
        _favoriteStores.map((store) => store.toJson()).toList(),
        

      );
      await prefs.setString(_favoritesKey, encodedJson);
    } catch (e) {
      print('Erro ao salvar favoritos: $e');
    }
  }

  // Verifica se uma loja está nos favoritos
  bool isFavorite(String storeId) {
    return _favoriteStores.any((store) => store.idEndereco == storeId);
  }

  // Adiciona ou remove uma loja dos favoritos
  Future<void> toggleFavorite(Restaurant restaurant) async {
    final isCurrentlyFavorite = isFavorite(restaurant.idEndereco);
    
    if (isCurrentlyFavorite) {
      _favoriteStores.removeWhere((store) => store.idEndereco == restaurant.idEndereco);
    } else {
      _favoriteStores.add(restaurant);
    }
    
    await _saveFavorites();
    notifyListeners();
  }

  // Remove uma loja dos favoritos
  Future<void> removeFavorite(String storeId) async {
    _favoriteStores.removeWhere((store) => store.idEndereco == storeId);
    await _saveFavorites();
    notifyListeners();
  }

  // Limpa todos os favoritos
  Future<void> clearFavorites() async {
    _favoriteStores.clear();
    await _saveFavorites();
    notifyListeners();
  }

  // Getter para o número de favoritos
  int get favoritesCount => _favoriteStores.length;
}
