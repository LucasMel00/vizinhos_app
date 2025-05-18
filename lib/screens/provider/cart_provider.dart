import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/model/cart_item.dart';
import 'package:vizinhos_app/screens/model/lote.dart';

enum AddItemResult {
  success,           // Item adicionado com sucesso
  differentStore,    // Item de loja diferente, precisa de confirmação
  unavailable        // Item indisponível
}

class CartProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _cartKey = 'cart';
  static const _storeKey = 'cart_store_id';

  Map<String, CartItem> _items = {};
  String? _currentStoreId;

  CartProvider() {
    _loadCart();
  }

  Map<String, CartItem> get items => {..._items};
  List<CartItem> get itemsList => _items.values.toList();
  int get itemCount => _items.length;
  double get totalAmount => _items.values
      .fold(0, (sum, ci) => sum + ci.product.valorVenda * ci.quantity);
  String? get currentStoreId => _currentStoreId;

  Future<void> _loadCart() async {
    final cartJson = await _storage.read(key: _cartKey);
    final storeId = await _storage.read(key: _storeKey);
    if (cartJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(cartJson);
      _items = decoded.map(
        (k, v) => MapEntry(k, CartItem.fromJson(v)),
      );
      _currentStoreId = storeId;
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    await _storage.write(
      key: _cartKey,
      value: jsonEncode(_items.map((k, v) => MapEntry(k, v.toJson()))),
    );
    if (_currentStoreId != null) {
      await _storage.write(key: _storeKey, value: _currentStoreId!);
    } else {
      await _storage.delete(key: _storeKey);
    }
  }

  // Método modificado para verificar se o produto é de uma loja diferente
  AddItemResult checkItemStore(Product product) {
    final storeId = product.fkIdEndereco.toString();
    if (_currentStoreId != null && _currentStoreId != storeId) {
      return AddItemResult.differentStore;
    }
    if (getAvailableToAdd(product) <= 0) {
      return AddItemResult.unavailable;
    }
    return AddItemResult.success;
  }

  // Método original modificado para retornar um enum em vez de boolean
  AddItemResult addItem(Product product) {
    final storeId = product.fkIdEndereco.toString();
    
    // Verifica se o produto é de uma loja diferente
    if (_currentStoreId != null && _currentStoreId != storeId) {
      return AddItemResult.differentStore;
    }
    
    // Verifica disponibilidade
    if (getAvailableToAdd(product) <= 0) {
      return AddItemResult.unavailable;
    }
    
    // Se o carrinho estiver vazio, define a loja atual
    if (_items.isEmpty) _currentStoreId = storeId;
    
    // Adiciona o item ao carrinho
    _items.update(
      product.id,
      (ci) => CartItem(product: ci.product, quantity: ci.quantity + 1),
      ifAbsent: () => CartItem(product: product, quantity: 1),
    );
    _saveCart();
    notifyListeners();
    return AddItemResult.success;
  }

  // Novo método para adicionar produto de outra loja, limpando o carrinho atual
  void addItemFromDifferentStore(Product product) {
    // Limpa o carrinho atual
    _items.clear();
    _currentStoreId = product.fkIdEndereco.toString();
    
    // Adiciona o novo produto
    _items[product.id] = CartItem(product: product, quantity: 1);
    _saveCart();
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    final ci = _items[productId]!;
    if (ci.quantity > 1) {
      _items[productId] =
          CartItem(product: ci.product, quantity: ci.quantity - 1);
    } else {
      _items.remove(productId);
      if (_items.isEmpty) _currentStoreId = null;
    }
    _saveCart();
    notifyListeners();
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

  int getAvailableToAdd(Product product) {
    int loteQtd = 0;
    final lote = product.lote;
    if (lote is Map) {
      loteQtd = int.tryParse('${lote['quantidade']}') ?? 0;
    } else if (lote is Lote) {
      loteQtd = lote.quantidade ?? 0;
    } else if (lote is String) {
      loteQtd = int.tryParse(product.quantidade?.toString() ?? '') ?? 0;
    }
    final inCart = _items[product.id]?.quantity ?? 0;
    return (loteQtd - inCart).clamp(0, loteQtd);
  }

  // Método para preparar os dados do pedido no formato esperado pela nova API
  Map<String, dynamic> prepareOrderData({
    required String tipoEntrega,
    required int idLoja,
    String? userCpf,
  }) {
    // Preparar itens do pedido
    final itemPedido = itemsList.map((item) {
      return {
        'fk_id_Lote': item.product.id_lote, // usa o getter para pegar o id do lote        'quantidade_item': item.quantity,
        'preco_unitario': item.product.valorVenda,
        'quantidade_item': item.quantity,
      };
    }).toList();

    // Montar objeto de pedido
    final orderData = {
      'id_Loja': idLoja,
      'valor': totalAmount,
      'tipo_entrega': tipoEntrega,
      'item_pedido': itemPedido,
      
    };
    
    // Adicionar CPF apenas se disponível
    if (userCpf != null && userCpf.isNotEmpty) {
      orderData['fk_Usuario_cpf'] = userCpf;
    }
    
    return orderData;
  }
}
