import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vizinhos_app/screens/model/order.dart';
import 'package:vizinhos_app/services/mps.dart';

class OrdersProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _ordersKey = 'user_orders';
  List<Order> _orders = [];
  final MercadoPagoService _mercadoPago = MercadoPagoService(
      'TEST-1356231261866648-051013-0d2ef2167a37e823d733d05ec30379f0-2430273423');

  List<Order> get orders => [..._orders];

  OrdersProvider() {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final ordersJson = await _storage.read(key: _ordersKey);
    if (ordersJson != null) {
      _orders = (jsonDecode(ordersJson) as List)
          .map((json) => Order.fromJson(json))
          .toList();
      notifyListeners();
    }
  }

  Future<void> _saveOrders() async {
    await _storage.write(
      key: _ordersKey,
      value: jsonEncode(_orders.map((o) => o.toJson()).toList()),
    );
  }

  Future<void> addOrder(Order order) async {
    _orders.insert(0, order);
    await _saveOrders();
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = Order(
        id: _orders[index].id,
        date: _orders[index].date,
        total: _orders[index].total,
        status: newStatus,
        items: _orders[index].items,
        paymentId: _orders[index].paymentId,
      );
      await _saveOrders();
      notifyListeners();
    }
  }

  Future<void> checkPaymentStatus(Order order) async {
    if (order.paymentId == null) return;

    try {
      final paymentData = await _mercadoPago.getPayment(order.paymentId!);
      await updateOrderStatus(order.id, paymentData['status']);
    } catch (e) {
      debugPrint('Erro ao verificar status: $e');
    }
  }
}
