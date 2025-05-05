import 'package:flutter/foundation.dart';
import 'package:vizinhos_app/screens/model/cart_item.dart';
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/model/lote.dart';
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

  // Helper to get available quantity from lote using id_lote
  int _getAvailableQuantity(Product product) {
    if (product.id_lote == null) return 0;
    try {
      Lote? lote;
      if (product.id_lote is String) {
        lote = Lote.fromJson(json.decode(product.id_lote!));
      } else if (product.id_lote is Lote) {
        lote = product.id_lote as Lote?;
      } else if (product.id_lote is Map<String, dynamic>) {
        lote = Lote.fromJson(product.id_lote as Map<String, dynamic>);
      }
      return (lote?.quantidade as int?) ?? 0;
    } catch (e) {
      print("Error getting available quantity from lote: $e");
      return 0;
    }
  }

  void addItem(Product product) {
    final availableQuantity = _getAvailableQuantity(product);
    if (availableQuantity <= 0) {
      print("Product ${product.nome} is out of stock.");
      // Optionally: Show a message to the user
      return;
    }

    if (_items.containsKey(product.id)) {
      // Increase quantity if item already exists and quantity is available
      if ((_items[product.id]!.quantity + 1) <= availableQuantity) {
         _items.update(
          product.id,
          (existingCartItem) => CartItem(
            product: existingCartItem.product,
            quantity: existingCartItem.quantity + 1,
          ),
        );
      } else {
         print("Cannot add more ${product.nome}. Max quantity reached.");
         // Optionally: Show a message to the user
      }
    } else {
      // Add new item
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

