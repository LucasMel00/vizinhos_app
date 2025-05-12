import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vizinhos_app/screens/model/order.dart';
import 'package:vizinhos_app/screens/provider/orders_provider.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart'; // Importe sua HomePage

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<OrdersProvider>(context, listen: false);

    // Verifica status dos pedidos pendentes
    for (final order in provider.orders.where((o) => o.status == 'pending')) {
      await provider.checkPaymentStatus(order);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>().orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateToHome(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(orders),
    );
  }

  // Método para navegar para a HomePage
  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildContent(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nenhum pedido encontrado',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToHome,
              child: const Text('Voltar para a página inicial'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (ctx, index) => _buildOrderCard(orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${order.id.substring(order.id.length - 5)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    order.statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: order.statusColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Data: ${order.formattedDate}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${order.formattedTotal}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (order.paymentId != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _viewOnMercadoPago(order.paymentId!),
                  child: const Text('Ver no Mercado Pago'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _navigateToHome,
                child: const Text('Voltar para Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewOnMercadoPago(String paymentId) async {
    final url = 'https://www.mercadopago.com.br/activities/search?q=$paymentId';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Mercado Pago')),
      );
    }
  }
}
