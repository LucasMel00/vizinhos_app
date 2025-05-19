import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vizinhos_app/services/secure_storage.dart';

final primaryColor = const Color(0xFFFbbc2c);

enum OrderStatus { pending, paid, preparing, completed, canceled }

class Order {
  final String id;
  final DateTime date;
  final double total;
  final OrderStatus status;
  final List<OrderProduct> products;

  Order({
    required this.id,
    required this.date,
    required this.total,
    required this.status,
    required this.products,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id_Pedido'],
      date: DateTime.parse(json['data_pedido']),
      total: double.parse(json['valor_total']),
      status: _parseStatus(json['status_pedido']),
      products: (json['produtos'] as List)
          .map((product) => OrderProduct.fromJson(product))
          .toList(),
    );
  }

  static OrderStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pago':
        return OrderStatus.paid;
      case 'em_preparo':
        return OrderStatus.preparing;
      case 'completo':
        return OrderStatus.completed;
      case 'cancelado':
        return OrderStatus.canceled;
      default:
        return OrderStatus.pending;
    }
  }
}

class OrderProduct {
  final String name;
  final String image;
  final int quantity;
  final double unitPrice;

  OrderProduct({
    required this.name,
    required this.image,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      name: json['nome_produto'],
      image: json['imagem_produto'],
      quantity: int.parse(json['quantidade']),
      unitPrice: double.parse(json['valor_unitario']),
    );
  }
}

class OrderService {
  static Future<List<Order>> fetchOrders() async {
    final storage = SecureStorage();
    final storeId = await storage.getEnderecoId();
    
    final response = await http.get(Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetOrdersByStore?id_Loja=$storeId'
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['pedidos'] as List)
          .map((order) => Order.fromJson(order))
          .toList();
    } else {
      throw Exception('Falha ao carregar pedidos');
    }
  }
}

class OrdersVendorPage extends StatefulWidget {
  @override
  _OrdersVendorPageState createState() => _OrdersVendorPageState();
}

class _OrdersVendorPageState extends State<OrdersVendorPage> 
    with WidgetsBindingObserver {
  late Future<List<Order>> _futureOrders;
  OrderStatus? _selectedStatus = OrderStatus.paid; // Filtro padrão: pagos
  List<Order> _allOrders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _futureOrders = OrderService.fetchOrders().then((orders) {
        _allOrders = orders;
        return orders;
      });
    });
  }

  List<Order> _filteredOrders() {
    if (_selectedStatus == null) return _allOrders;
    return _allOrders.where((o) => o.status == _selectedStatus).toList();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pedidos da Loja',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: primaryColor,
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: primaryColor, height: 2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, color: Color(0xFF3B4351)),
                  const SizedBox(width: 8),
                  const Text('Filtrar:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<OrderStatus?>(
                          value: _selectedStatus,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem(
                              value: OrderStatus.paid,
                              child: Text('Pagos'),
                            ),
                            DropdownMenuItem(
                              value: OrderStatus.preparing,
                              child: Text('Em preparo'),
                            ),
                            DropdownMenuItem(
                              value: OrderStatus.completed,
                              child: Text('Concluídos'),
                            ),
                            DropdownMenuItem(
                              value: OrderStatus.canceled,
                              child: Text('Cancelados'),
                            ),
                            DropdownMenuItem(
                              value: OrderStatus.pending,
                              child: Text('Pendentes'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Order>>(
                future: _futureOrders,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_allOrders.isEmpty && snapshot.data != null) {
                    _allOrders = snapshot.data!;
                  }
                  final orders = _selectedStatus == null ? _allOrders : _filteredOrders();
                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text('Nenhum pedido encontrado', style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
                        ],
                      ),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? constraints.maxWidth * 0.2 : 12,
                          vertical: 16,
                        ),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return OrderCard(order: orders[index], isWide: isWide);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final bool isWide;

  const OrderCard({required this.order, this.isWide = false});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return Colors.blue[100]!;
      case OrderStatus.preparing:
        return Colors.orange[100]!;
      case OrderStatus.completed:
        return Colors.green[100]!;
      case OrderStatus.canceled:
        return Colors.red[100]!;
      default:
        return primaryColor.withOpacity(0.15);
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return 'Pago';
      case OrderStatus.preparing:
        return 'Em preparo';
      case OrderStatus.completed:
        return 'Concluído';
      case OrderStatus.canceled:
        return 'Cancelado';
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(order.status),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '#${order.id.substring(0, 6).toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(order.date),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...order.products.map((product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.image,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${product.quantity}x  ·  R\$${product.unitPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: ',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.grey[700]),
                ),
                Text(
                  'R\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (order.status == OrderStatus.paid) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _updateOrderStatus('em_preparo'),
              child: Text(
                'Iniciar preparo',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 10),

        ],
      );
    }
    return SizedBox.shrink();
  }

  void _updateOrderStatus(String newStatus) {
    // Implementar chamada à API para atualizar status
    print('Atualizar pedido ${order.id} para status: $newStatus');
  }
}

String _monthName(int month) {
  const months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];
  return months[month - 1];
}
