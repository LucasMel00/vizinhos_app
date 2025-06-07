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

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'total': total,
        'status': status,
        'items': items.map((item) => item.toJson()).toList(),
        'paymentId': paymentId,
        'storeId': storeId,
      };

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

  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(date);

  String get formattedTotal => NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(total);

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

  String get formattedUnitPrice => NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(unitPrice);

  String get formattedTotal => NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(total);
}

class StoreModel {
  final String idLoja;
  final String nomeLoja;
  final String imagemLoja;
  final String enderecoLoja;
  final String cepLoja;

  StoreModel({
    required this.idLoja,
    required this.nomeLoja,
    required this.imagemLoja,
    required this.enderecoLoja,
    required this.cepLoja,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      idLoja: json['id_loja']?.toString() ?? '',
      nomeLoja: json['nome_loja']?.toString() ?? '',
      imagemLoja: json['imagem_loja']?.toString() ?? '',
      enderecoLoja: json['endereco_loja']?.toString() ?? '',
      cepLoja: json['cep_loja']?.toString() ?? '',
    );
  }
}

class ProductModel {
  final String nomeProduto;
  final String imagemProduto;
  final int quantidade;
  final double valorUnitario;
  final StoreModel loja;

  ProductModel({
    required this.nomeProduto,
    required this.imagemProduto,
    required this.quantidade,
    required this.valorUnitario,
    required this.loja,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int parseQuantidade(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    double parseValorUnitario(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return ProductModel(
      nomeProduto: json['nome_produto']?.toString() ?? '',
      imagemProduto: json['imagem_produto']?.toString() ?? '',
      quantidade: parseQuantidade(json['quantidade']),
      valorUnitario: parseValorUnitario(json['valor_unitario']),
      loja: StoreModel.fromJson(json['loja'] ?? {}),
    );
  }
}

class OrderModel {
  final String idPedido;
  final String idPagamento;
  final String statusPedido;
  final double valorTotal;
  final String dataPedido;
  final String? qrCode;
  final String? qrCodeBase64;
  final List<ProductModel> produtos;

  OrderModel({
    required this.idPedido,
    required this.idPagamento,
    required this.statusPedido,
    required this.valorTotal,
    required this.dataPedido,
    this.qrCode,
    this.qrCodeBase64,
    required this.produtos,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    double parseValorTotal(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    List<ProductModel> produtosList = [];
    if (json['produtos'] != null) {
      produtosList = List<ProductModel>.from(
        (json['produtos'] as List).map(
          (produto) => ProductModel.fromJson(produto),
        ),
      );
    }

    return OrderModel(
      idPedido: json['id_Pedido']?.toString() ?? '',
      idPagamento: json['id_Pagamento']?.toString() ?? '',
      statusPedido: json['status_pedido']?.toString() ?? '',
      valorTotal: parseValorTotal(json['valor_total']),
      dataPedido: json['data_pedido']?.toString() ?? '',
      qrCode: json['qr_code']?.toString(),
      qrCodeBase64: json['qr_code_base64']?.toString(),
      produtos: produtosList,
    );
  }
}

class OrdersResponse {
  final List<OrderModel> pedidos;

  OrdersResponse({required this.pedidos});

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      pedidos: List<OrderModel>.from(
        (json['pedidos'] as List).map(
          (pedido) => OrderModel.fromJson(pedido),
        ),
      ),
    );
  }
}
