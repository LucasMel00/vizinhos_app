import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vizinhos_app/screens/user/home_page_user.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/screens/user/user_account_page.dart';
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
  Map<String, bool> _updatingStatus = {};

  int _selectedIndex = 2; // Orders is selected by default

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<OrdersResponse> _fetchOrders() =>
      _ordersService.getOrdersByUser(widget.cpf);

  String _formatDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(double value) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);

  Color _getStatusColor(String status) {
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
        return Colors.grey[800]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'aprovado':
        return Icons.check_circle;
      case 'pendente':
        return Icons.pending_actions;
      case 'aguardando pagamento':
        return Icons.payment;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Future<void> _updateOrderStatus(String idPedido) async {
    setState(() => _updatingStatus[idPedido] = true);

    final success = await _ordersService.updateOrderStatus(idPedido);

    if (success) {
      setState(() => _ordersFuture = _fetchOrders());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar status'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _updatingStatus.remove(idPedido));
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navegar para a página correspondente
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HomePage(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SearchPage(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
      case 2: // Orders
        break; // Already on this page
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => UserAccountPage(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
    }
  }

  Widget _buildNavIcon(
      IconData icon, String label, int index, BuildContext context) {
    bool isSelected = index == _selectedIndex;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color.fromARGB(255, 237, 236, 233)
                  : const Color.fromRGBO(59, 67, 81, 1).withOpacity(0.7),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? const Color.fromARGB(255, 21, 21, 21)
                    : const Color.fromRGBO(59, 67, 81, 1).withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading:
              false, // Hide back button when navigating via navbar
          backgroundColor: const Color(0xFFFbbc2c),
          title: const Text('Meus Pedidos'),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator.adaptive(
              onRefresh: () async =>
                  setState(() => _ordersFuture = _fetchOrders()),
              child: FutureBuilder<OrdersResponse>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  }

                  if (snapshot.hasError) {
                    return _ErrorView(
                      error: snapshot.error.toString(),
                      onRetry: () {
                        setState(() {
                          _ordersFuture = _fetchOrders();
                        });
                      },
                    );
                  }

                  final orders = snapshot.data?.pedidos ?? [];
                  if (orders.isEmpty) {
                    return const _EmptyOrdersView();
                  }

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth:
                            constraints.maxWidth > 600 ? 600 : double.infinity),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _OrderCard(
                        order: orders[index],
                        updating:
                            _updatingStatus[orders[index].idPedido] ?? false,
                        onUpdateStatus: _updateOrderStatus,
                        formatDate: _formatDate,
                        formatCurrency: _formatCurrency,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFbbc2c),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavIcon(Icons.home, 'Início', 0, context),
                _buildNavIcon(Icons.search, 'Buscar', 1, context),
                _buildNavIcon(Icons.list, 'Pedidos', 2, context),
                _buildNavIcon(Icons.person, 'Conta', 3, context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool updating;
  final Function(String) onUpdateStatus;
  final String Function(String) formatDate;
  final String Function(double) formatCurrency;

  const _OrderCard({
    required this.order,
    required this.updating,
    required this.onUpdateStatus,
    required this.formatDate,
    required this.formatCurrency,
  });

  Color _getStatusColor(String status) {
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
        return Colors.grey[800]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'aprovado':
        return Icons.check_circle;
      case 'pendente':
        return Icons.pending_actions;
      case 'aguardando pagamento':
        return Icons.payment;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUpdate = ['pendente', 'aguardando pagamento']
        .contains(order.statusPedido.toLowerCase());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Icon(_getStatusIcon(order.statusPedido),
            color: _getStatusColor(order.statusPedido)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Pedido #${order.idPedido.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (canUpdate)
                  updating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh),
                          color: Theme.of(context).primaryColor,
                          onPressed: () => onUpdateStatus(order.idPedido),
                        ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Data: ${formatDate(order.dataPedido)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        subtitle: Text(
          'Total: ${formatCurrency(order.valorTotal)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _OrderStatusChip(
              status: order.statusPedido,
              color: _getStatusColor(order.statusPedido),
              icon: _getStatusIcon(order.statusPedido),
            ),
          ),
          ..._buildProductList(order.produtos),
          if (order.qrCodeBase64 != null) _buildQrCodeSection(context, order),
        ],
      ),
    );
  }

  List<Widget> _buildProductList(List<ProductModel> produtos) {
    return [
      const Divider(height: 24),
      Text('Produtos', style: _sectionTitleStyle),
      const SizedBox(height: 8),
      ...produtos.map((produto) => _ProductItem(
            product: produto,
            formatCurrency: formatCurrency,
          )),
    ];
  }

  Widget _buildQrCodeSection(BuildContext context, OrderModel order) {
    return Column(
      children: [
        const Divider(height: 32),
        Text('Pagamento', style: _sectionTitleStyle),
        const SizedBox(height: 12),
        if (order.statusPedido.toLowerCase() == 'pendente' ||
            order.statusPedido.toLowerCase() == 'aguardando pagamento')
          Column(
            children: [
              const Text('Escaneie o QR Code para pagar'),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showFullScreenQr(context, order.qrCodeBase64!),
                child: Image.memory(
                  base64Decode(order.qrCodeBase64!),
                  height: 180,
                  width: 180,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copiar código do QR'),
                onPressed: () => _copyQrCode(context, order.qrCodeBase64!),
              ),
            ],
          )
        else
          const ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Pagamento processado'),
          ),
      ],
    );
  }

  TextStyle get _sectionTitleStyle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  void _showFullScreenQr(BuildContext context, String qrCode) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          panEnabled: true,
          child: Image.memory(base64Decode(qrCode)),
        ),
      ),
    );
  }

  void _copyQrCode(BuildContext context, String qrCode) {
    Clipboard.setData(ClipboardData(text: qrCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Código QR copiado para a área de transferência')),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final ProductModel product;
  final String Function(double) formatCurrency;

  const _ProductItem({required this.product, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.imagemProduto,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag),
        ),
      ),
      title: Text(product.nomeProduto),
      subtitle: Text('Loja: ${product.loja.nomeLoja}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
              '${product.quantidade}x ${formatCurrency(product.valorUnitario)}'),
          Text(
            formatCurrency(product.quantidade * product.valorUnitario),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final String status;
  final Color color;
  final IconData icon;

  const _OrderStatusChip({
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Ocorreu um erro ao carregar os pedidos',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrdersView extends StatelessWidget {
  const _EmptyOrdersView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'Nenhum pedido encontrado',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Seus pedidos aparecerão aqui quando você fizer uma compra',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
