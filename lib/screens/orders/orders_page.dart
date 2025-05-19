import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart';

import '../model/order_models.dart';
import '../provider/order_service.dart';

class OrdersPage extends StatefulWidget {
  final String cpf;
  const OrdersPage({Key? key, required this.cpf}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrdersService _ordersService = OrdersService();
  late Future<OrdersResponse> _ordersFuture;
  Map<String, bool> _loadingStatus = {};

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<OrdersResponse> _fetchOrders() {
    return _ordersService.getOrdersByUser(widget.cpf);
  }

  String formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(value);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprovado':
        return Colors.green;
      case 'pendente':
        return Colors.orange;
      case 'aguardando pagamento':
        return Colors.blue;
      case 'cancelado':
        return Colors.red;
      default:
        return const Color.fromARGB(255, 53, 218, 47);
    }
  }

  Future<void> _updateOrderStatus(String idPedido) async {
    setState(() {
      _loadingStatus[idPedido] = true;
    });
    final success = await _ordersService.updateOrderStatus(idPedido);
    if (success) {
      setState(() {
        _ordersFuture = _fetchOrders();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status atualizado!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar status')),
      );
    }
    setState(() {
      _loadingStatus[idPedido] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => HomePage())),
        ),
        title: const Text('Meus Pedidos'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: FutureBuilder<OrdersResponse>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar pedidos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _ordersFuture = _fetchOrders();
                      });
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.pedidos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum pedido encontrado',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você ainda não realizou nenhum pedido',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.pedidos;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _ordersFuture = _fetchOrders();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final statusLower = order.statusPedido.toLowerCase();
                final canUpdate = statusLower == 'pendente' || statusLower == 'aguardando pagamento';
                final isLoading = _loadingStatus[order.idPedido] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.all(16),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pedido #${order.idPedido.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    order.statusPedido,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor:
                                      getStatusColor(order.statusPedido),
                                ),
                                const SizedBox(width: 8),
                                if (canUpdate)
                                  isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.refresh,
                                              color: Colors.orange),
                                          tooltip: 'Atualizar status',
                                          onPressed: () =>
                                              _updateOrderStatus(order.idPedido),
                                        ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data: ${formatDate(order.dataPedido)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${formatCurrency(order.valorTotal)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      const Divider(),
                      const Text(
                        'Produtos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.produtos.map((produto) => _buildProductItem(produto)),
                      if (order.qrCodeBase64 != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Pagamento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (statusLower == 'pendente' ||
                            statusLower == 'aguardando pagamento')
                          Column(
                            children: [
                              const Text(
                                'Escaneie o QR Code para pagar',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Image.memory(
                                base64Decode(order.qrCodeBase64!),
                                height: 200,
                                width: 200,
                              ),
                            ],
                          )
                        else
                          const Text(
                            'Pagamento processado',
                            style: TextStyle(fontSize: 14),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductItem(ProductModel produto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              produto.imagemProduto,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child:
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produto.nomeProduto,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Loja: ${produto.loja.nomeLoja}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${produto.quantidade}x ${formatCurrency(produto.valorUnitario)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      formatCurrency(produto.quantidade * produto.valorUnitario),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
