import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/model/lote.dart';
import 'package:vizinhos_app/screens/model/cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _currentStoreId; // ID da loja atual do carrinho

  Map<String, CartItem> get items => _items;
  int get itemCount => _items.length;
  double get totalAmount => _items.values.fold(0, (sum, item) => sum + (item.product.valorVenda * item.quantity));
  String? get currentStoreId => _currentStoreId;

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final cartData = await _storage.read(key: 'cart');
    final storeId = await _storage.read(key: 'cart_store_id');
    if (cartData != null) {
      _items = Map<String, CartItem>.from(
        jsonDecode(cartData).map((key, value) =>
          MapEntry(key, CartItem.fromJson(value)))
      );
      _currentStoreId = storeId;
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    await _storage.write(
      key: 'cart',
      value: jsonEncode(_items.map((key, value) => MapEntry(key, value.toJson()))),
    );
    await _storage.write(
      key: 'cart_store_id',
      value: _currentStoreId,
    );
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
      // Se removeu o último item, limpa a loja
      if (_items.isEmpty) _currentStoreId = null;
    }
    _saveCart();
    notifyListeners();
  }

  int getAvailableToAdd(Product product) {
    if (product.lote == null) return 0;
    int loteQuantidade = 0;
    if (product.lote is Map) {
      loteQuantidade = int.tryParse(product.lote['quantidade'].toString()) ?? 0;
    } else if (product.lote is Lote) {
      loteQuantidade = (product.lote as Lote).quantidade ?? 0;
    } else if (product.lote is String) {
      loteQuantidade = product.quantidade ?? 0;
    }
    if (loteQuantidade <= 0) return 0;
    final inCart = _items[product.id]?.quantity ?? 0;
    return loteQuantidade - inCart;
  }

  /// Retorna true se conseguiu adicionar, false se não pôde (loja diferente)
  bool addItem(Product product) {
    final productStoreId = product.fkIdEndereco.toString(); // ajuste se o campo for diferente

    // Bloqueia se o carrinho já tem produtos de outra loja
    if (_currentStoreId != null && _currentStoreId != productStoreId) {
      return false;
    }

    // Se o carrinho está vazio, define a loja
    if (_items.isEmpty) {
      _currentStoreId = productStoreId;
    }

    if (getAvailableToAdd(product) <= 0) return true;

    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(product: product, quantity: 1),
      );
    }
    _saveCart();
    notifyListeners();
    return true;
  }

  void removeItem(String productId) {
    _items.remove(productId);
    if (_items.isEmpty) _currentStoreId = null;
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _currentStoreId = null;
    _saveCart();
    notifyListeners();
  }
}
