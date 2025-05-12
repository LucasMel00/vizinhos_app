import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Order {
  final String id;
  final DateTime date;
  final double total;
  final String status;
  final List<OrderItem> items;
  final String? paymentId;
  final String? storeId;

  Order({
    required this.id,
    required this.date,
    required this.total,
    this.status = 'pending',
    required this.items,
    this.paymentId,
    this.storeId,
  });

  // Converte para Map (útil para JSON e Firestore)
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'total': total,
        'status': status,
        'items': items.map((item) => item.toJson()).toList(),
        'paymentId': paymentId,
        'storeId': storeId,
      };

  // Converte de Map para Order
  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] ?? '',
        date: DateTime.parse(json['date']),
        total: (json['total'] as num).toDouble(),
        status: json['status'] ?? 'pending',
        items: (json['items'] as List)
            .map((item) => OrderItem.fromJson(item))
            .toList(),
        paymentId: json['paymentId'],
        storeId: json['storeId'],
      );

  // Formata a data para exibição
  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(date);

  // Formata o valor total
  String get formattedTotal => NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(total);

  // Status traduzido
  String get statusText {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'rejected':
        return 'Rejeitado';
      case 'delivered':
        return 'Entregue';
      default:
        return status;
    }
  }

  // Cor do status
  Color get statusColor {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'delivered':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
  });

  // Valor total do item (quantidade x preço unitário)
  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'imageUrl': imageUrl,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] ?? '',
        name: json['name'] ?? '',
        quantity: json['quantity'] ?? 0,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        imageUrl: json['imageUrl'],
      );

  // Formata o valor unitário
  String get formattedUnitPrice => NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(unitPrice);

  // Formata o valor total do item
  String get formattedTotal => NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(total);
}
