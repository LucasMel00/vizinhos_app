// cart_provider.dart
import 'package:flutter/foundation.dart';
import 'package:vizinhos_app/screens/model/cart_item.dart';
import 'package:vizinhos_app/screens/model/lote.dart';
import 'package:vizinhos_app/screens/model/product.dart';
import 'dart:convert';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {}; // Use product ID as key for easy access
  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.subtotal;
    });
    return total;
  }

  // NOVO: Método público para verificar quantidade disponível
 int getAvailableQuantity(Product product) {
  // Recupere o lote (pode ser string JSON, objeto ou map)
  Lote? lote;
  if (product.id_lote != null) {
    if (product.id_lote is Lote) {
      lote = product.id_lote as Lote;
    } else if (product.id_lote is Map) {
      lote = Lote.fromJson((product.id_lote as Map).cast<String, dynamic>());
    } else if (product.id_lote is String && product.id_lote != '') {
        try {
          lote = Lote.fromJson(jsonDecode(product.id_lote!));
        } catch (_) {}
    }
  }
  // Converte a quantidade do lote para int
  final String? qtdStr = lote?.quantidade;
  final int qtdLote = int.tryParse(qtdStr ?? '') ?? 0;
  return qtdLote;
}

int getAvailableToAdd(Product product, Map<String, CartItem> items) {
  final totalQuantity = getAvailableQuantity(product);
  final inCart = items[product.id]?.quantity ?? 0;
  return totalQuantity - inCart;
}

  void addItem(Product product) {
    final availableToAdd = getAvailableToAdd(product, _items);
    
    if (availableToAdd <= 0) {
      print("Cannot add more ${product.nome}. Max quantity reached or out of stock.");
      return;
    }

    if (_items.containsKey(product.id)) {
      // Aumenta a quantidade se o produto já estiver no carrinho
      _items.update(
        product.id,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      // Adiciona novo item
      _items.putIfAbsent(
        product.id,
        () => CartItem(product: product, quantity: 1),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items = {};
    notifyListeners();
  }
}
