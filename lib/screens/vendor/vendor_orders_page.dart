import 'package:flutter/material.dart';

final primaryColor = const Color(0xFFFbbc2c);

enum OrderStatus { pending, preparing, completed, canceled }

class Order {
  final int id;
  final DateTime dateTime;
  final double total;
  final OrderStatus status;
  final List<String> items;

  Order({
    required this.id,
    required this.dateTime,
    required this.total,
    required this.status,
    required this.items,
  });
}

class OrdersVendorPage extends StatelessWidget {
  final List<Order> orders = [
    Order(
      id: 1024,
      dateTime: DateTime(2024, 3, 26, 14, 30),
      total: 24.0,
      status: OrderStatus.pending,
      items: ['2x Bolo de Chocolate', '1x Torta de Morango'],
    ),
    Order(
      id: 1023,
      dateTime: DateTime(2024, 3, 26, 13, 45),
      total: 0,
      status: OrderStatus.preparing,
      items: ['1x Cheesecake', '1x Sonho'],
    ),
  ];

  String statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendente';
      case OrderStatus.preparing:
        return 'Em preparo';
      case OrderStatus.completed:
        return 'Concluído';
      case OrderStatus.canceled:
        return 'Cancelado';
    }
  }

  Color statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return primaryColor.withOpacity(0.15);
      case OrderStatus.preparing:
        return Colors.grey[200]!;
      case OrderStatus.completed:
        return Colors.green[100]!;
      case OrderStatus.canceled:
        return Colors.red[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pedidos da Loja',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Container(
            color: primaryColor,
            height: 2,
          ),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => SizedBox(height: 16),
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(order: order);
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusText = {
      OrderStatus.pending: 'Pendente',
      OrderStatus.preparing: 'Em preparo',
      OrderStatus.completed: 'Concluído',
      OrderStatus.canceled: 'Cancelado',
    }[order.status]!;

    final statusColor = {
      OrderStatus.pending: primaryColor.withOpacity(0.15),
      OrderStatus.preparing: Colors.grey[200],
      OrderStatus.completed: Colors.green[100],
      OrderStatus.canceled: Colors.red[100],
    }[order.status]!;

    final statusTextColor = {
      OrderStatus.pending: primaryColor,
      OrderStatus.preparing: Colors.grey[600],
      OrderStatus.completed: Colors.green[800],
      OrderStatus.canceled: Colors.red[800],
    }[order.status]!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.5,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status e número do pedido
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  '#${order.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Data e valor
            Row(
              children: [
                Text(
                  '${order.dateTime.day.toString().padLeft(2, '0')} '
                  '${_monthName(order.dateTime.month)} '
                  '${order.dateTime.year} • '
                  '${order.dateTime.hour.toString().padLeft(2, '0')}:${order.dateTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Spacer(),
                if (order.total > 0)
                  Text(
                    'R\$ ${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            // Itens
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    '• $item',
                    style: TextStyle(fontSize: 14),
                  ),
                )),
            SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                // Navegar para detalhes do pedido
              },
              child: Text(
                'Ver detalhes',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: _buildActionButtons(context, order.status),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: Text(
                'Aceitar pedido',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: Text('Recusar pedido'),
            ),
          ),
        ];
      case OrderStatus.preparing:
        return [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: Text(
                'Pedido pronto',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: Text('Cancelar pedido'),
            ),
          ),
        ];
      default:
        return [];
    }
  }

  String _monthName(int month) {
    const months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez'
    ];
    return months[month - 1];
  }
}
