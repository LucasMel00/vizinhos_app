import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For copy to clipboard
import 'package:intl/intl.dart';
import 'package:im_stepper/stepper.dart'; // Importando o pacote im_stepper
import 'package:vizinhos_app/screens/user/home_page_user.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/screens/user/user_account_page.dart';
import '../model/order_models.dart';
import '../provider/order_service.dart';

// Cores do tema com melhor contraste e acessibilidade
final primaryColor = const Color(0xFFFbbc2c);
final secondaryColor = const Color(0xFF3B4351);
final successColor = const Color(0xFF4CAF50);
final warningColor = const Color(0xFFFFA000);
final infoColor = const Color(0xFF2196F3);
final errorColor = const Color(0xFFE53935);

// Enum para status de pedido para melhor consistência
enum OrderStatus {
  pending,
  awaitingPayment,
  paid,
  preparing,
  inDelivery,
  readyForPickup,
  completed,
  canceled
}

// Enum para tipos de entrega
enum DeliveryType {
  delivery,
  pickup
}

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

  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
    // Atualiza automaticamente status de pedidos pendentes ao abrir a página
    _refreshOrders();
  }

  Future<OrdersResponse> _fetchOrders() =>
      _ordersService.getOrdersByUser(widget.cpf);

  // Refresh handler: check pending-payment orders and update their status before reloading
  Future<void> _refreshOrders() async {
    try {
      final resp = await _ordersService.getOrdersByUser(widget.cpf);
      final updates = resp.pedidos
          .where((o) => o.statusPedido.toLowerCase() == 'aguardando pagamento')
          .map((o) => _ordersService.updateOrderStatus(o.idPedido));
      await Future.wait(updates);
    } catch (e) {
      debugPrint('Erro ao atualizar pedidos pendentes: $e');
    } finally {
      setState(() {
        _ordersFuture = _fetchOrders();
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(double value) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);

  Future<void> _updateOrderStatus(String idPedido) async {
    setState(() => _updatingStatus[idPedido] = true);

    final success = await _ordersService.updateOrderStatus(idPedido);

    if (success) {
      setState(() => _ordersFuture = _fetchOrders());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Status atualizado com sucesso!'),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Erro ao atualizar status'),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    setState(() => _updatingStatus.remove(idPedido));
  }

  // Método para converter string de status para enum OrderStatus
  OrderStatus _parseOrderStatus(String status) {
    final statusLower = status.toLowerCase();
    
    if (statusLower.contains('aguardando pagamento')) {
      return OrderStatus.awaitingPayment;
    } else if (statusLower.contains('pago') || statusLower.contains('confirmado')) {
      return OrderStatus.paid;
    } else if (statusLower.contains('preparo')) {
      return OrderStatus.preparing;
    } else if (statusLower.contains('rota') || statusLower.contains('caminho')) {
      return OrderStatus.inDelivery;
    } else if (statusLower.contains('retirada') && !statusLower.contains('aguardando')) {
      return OrderStatus.readyForPickup;
    } else if (statusLower.contains('concluído') || statusLower.contains('entregue') || statusLower.contains('retirado')) {
      return OrderStatus.completed;
    } else if (statusLower.contains('cancelado')) {
      return OrderStatus.canceled;
    } else if (statusLower.contains('pendente')) {
      return OrderStatus.pending;
    } else {
      return OrderStatus.pending;
    }
  }

  // Método para determinar o tipo de entrega
  DeliveryType _getDeliveryType(OrderModel order) {
    // Verificar se há informação explícita sobre o tipo de entrega
    if (order.tipoEntrega != null) {
      final tipoLower = order.tipoEntrega!.toLowerCase();
      if (tipoLower.contains('delivery') || tipoLower.contains('entrega')) {
        return DeliveryType.delivery;
      } else if (tipoLower.contains('retirada') || tipoLower.contains('pickup')) {
        return DeliveryType.pickup;
      }
    }
    
    // Se não houver informação explícita, tentar inferir pelo status
    final statusLower = order.statusPedido.toLowerCase();
    if (statusLower.contains('rota') || statusLower.contains('caminho') || statusLower.contains('entrega')) {
      return DeliveryType.delivery;
    } else if (statusLower.contains('retirada')) {
      return DeliveryType.pickup;
    }
    
    // Padrão: delivery
    return DeliveryType.delivery;
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
          automaticallyImplyLeading: false,
          backgroundColor: primaryColor,
          title: const Text(
            'Meus Pedidos',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator.adaptive(
              onRefresh: _refreshOrders,
              child: FutureBuilder<OrdersResponse>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator.adaptive(),
                          SizedBox(height: 16),
                          Text('Carregando seus pedidos...'),
                        ],
                      ),
                    );
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
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _OrderCard(
                        order: orders[index],
                        updating:
                            _updatingStatus[orders[index].idPedido] ?? false,
                        onUpdateStatus: _updateOrderStatus,
                        formatDate: _formatDate,
                        formatCurrency: _formatCurrency,
                        parseOrderStatus: _parseOrderStatus,
                        getDeliveryType: _getDeliveryType,
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
              color: primaryColor,
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
  final OrderStatus Function(String) parseOrderStatus;
  final DeliveryType Function(OrderModel) getDeliveryType;

  const _OrderCard({
    required this.order,
    required this.updating,
    required this.onUpdateStatus,
    required this.formatDate,
    required this.formatCurrency,
    required this.parseOrderStatus,
    required this.getDeliveryType,
  });

  @override
  Widget build(BuildContext context) {
    final orderStatus = parseOrderStatus(order.statusPedido);
    final deliveryType = getDeliveryType(order);
    final canUpdate = [OrderStatus.pending, OrderStatus.awaitingPayment].contains(orderStatus);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stepper visual no topo
          OrderStepperWidget(
            order: order,
            orderStatus: orderStatus,
            deliveryType: deliveryType,
          ),
          
          // Informações principais do pedido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com ID e status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${order.idPedido.substring(0, 6).toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildStatusChip(orderStatus),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Data e hora
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(order.dataPedido),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                    const Spacer(),
                    // Tipo de entrega
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            deliveryType == DeliveryType.delivery 
                                ? Icons.delivery_dining 
                                : Icons.store,
                            size: 14,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            deliveryType == DeliveryType.delivery ? 'Entrega' : 'Retirada',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Lista de produtos (expansível)
                ExpansionTile(
                  title: const Text(
                    'Produtos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  children: order.produtos.map((produto) => _ProductItem(
                    product: produto,
                    formatCurrency: formatCurrency,
                  )).toList(),
                ),
                
                const SizedBox(height: 12),
                
                // Total do pedido
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.grey[700]
                      ),
                    ),
                    Text(
                      formatCurrency(order.valorTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
                
                // Código PIX (copia e cola) apenas se estiver aguardando pagamento
                if (order.qrCode != null && orderStatus == OrderStatus.awaitingPayment) ...[
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.qr_code, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'PIX (Copia e Cola)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B4351),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          order.qrCode!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.copy),
                            label: const Text('Copiar código'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: order.qrCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Código PIX copiado para área de transferência')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Botão de atualização (se aplicável)
                if (canUpdate) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: updating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(updating ? 'Atualizando...' : 'Verificar pagamento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: updating ? null : () => onUpdateStatus(order.idPedido),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Método para construir o chip de status com cores e ícones contextuais
  Widget _buildStatusChip(OrderStatus status) {
    // Determina cor e ícone com base no status
    Color color;
    IconData icon;
    String label;
    
    switch (status) {
      case OrderStatus.pending:
        color = Colors.grey[700]!;
        icon = Icons.hourglass_empty;
        label = 'Pendente';
        break;
      case OrderStatus.awaitingPayment:
        color = Colors.orange[700]!;
        icon = Icons.payments_outlined;
        label = 'Aguardando Pagamento';
        break;
      case OrderStatus.paid:
        color = Colors.blue[700]!;
        icon = Icons.payments_outlined;
        label = 'Pago';
        break;
      case OrderStatus.preparing:
        color = Colors.amber[700]!;
        icon = Icons.restaurant;
        label = 'Em Preparo';
        break;
      case OrderStatus.inDelivery:
        color = Colors.lightBlue[700]!;
        icon = Icons.delivery_dining;
        label = 'Em Rota';
        break;
      case OrderStatus.readyForPickup:
        color = Colors.amber[700]!;
        icon = Icons.store;
        label = 'Pronto para Retirada';
        break;
      case OrderStatus.completed:
        color = Colors.green[700]!;
        icon = Icons.check_circle;
        label = 'Concluído';
        break;
      case OrderStatus.canceled:
        color = Colors.red[700]!;
        icon = Icons.cancel;
        label = 'Cancelado';
        break;
    }
    
    // Se o status original tiver um texto específico, usá-lo em vez do padrão
    if (order.statusPedido.isNotEmpty) {
      label = order.statusPedido;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      )
    );
  }
}

// Widget de stepper usando im_stepper
class OrderStepperWidget extends StatelessWidget {
  final OrderModel order;
  final OrderStatus orderStatus;
  final DeliveryType deliveryType;
  
  const OrderStepperWidget({
    required this.order,
    required this.orderStatus,
    required this.deliveryType,
  });

  @override
  Widget build(BuildContext context) {
    // Determina o texto e ícone do quarto passo com base no tipo de entrega
    String fourthStepLabel = deliveryType == DeliveryType.delivery 
        ? 'Em rota' 
        : 'Pronto para retirada';
    
    IconData fourthStepIcon = deliveryType == DeliveryType.delivery 
        ? Icons.delivery_dining 
        : Icons.store;
    
    // Determina o step atual
    int activeStep = _getActiveStep(orderStatus);
    
    // Lista de ícones para o stepper
    List<IconData> icons = [
      Icons.shopping_bag,
      Icons.payments_outlined,
      Icons.restaurant,
      fourthStepIcon,
      Icons.check_circle,
    ];
    
    // Lista de textos para o stepper
    List<String> labels = [
      'Pedido realizado',
      'Pagamento confirmado',
      'Em preparo',
      fourthStepLabel,
      deliveryType == DeliveryType.delivery ? 'Pedido entregue' : 'Pedido retirado',
    ];
    
    final double maxStepperWidth = MediaQuery.of(context).size.width - 32;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: maxStepperWidth,
                maxWidth: maxStepperWidth,
              ),
              child: IconStepper(
                icons: icons.map((icon) => Icon(icon, color: Colors.white)).toList(),
                activeStep: activeStep,
                enableNextPreviousButtons: false,
                enableStepTapping: false,
                activeStepColor: primaryColor,
                activeStepBorderColor: primaryColor,
                activeStepBorderWidth: 0,
                lineColor: Colors.grey[300],
                lineLength: 50,
                lineDotRadius: 1.5,
                stepRadius: 20,
                stepColor: Colors.grey[300],
                stepPadding: 0,
              ),
            ),
          ),
           const SizedBox(height: 8),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: List.generate(
               labels.length,
               (i) => Expanded(
                 child: Text(
                   labels[i],
                   textAlign: TextAlign.center,
                   style: TextStyle(
                     fontSize: 12,
                     color: i <= activeStep ? primaryColor : Colors.grey[600],
                     fontWeight: i == activeStep ? FontWeight.bold : FontWeight.normal,
                   ),
                 ),
               ),
             ),
           ),
         ],
       ),
     );
  }
  
  // Método para determinar o passo ativo com base no status
  int _getActiveStep(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return 4;
      case OrderStatus.inDelivery:
        return 3;
      case OrderStatus.readyForPickup:
        return 3;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.paid:
        return 1;
      case OrderStatus.awaitingPayment:
        return 0;
      case OrderStatus.pending:
        return 0;
      case OrderStatus.canceled:
        return 0; // Para cancelados, mostramos no início
    }
  }
}

class _ProductItem extends StatelessWidget {
  final ProductModel product;
  final String Function(double) formatCurrency;

  const _ProductItem({required this.product, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              product.imagemProduto,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nomeProduto,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Loja: ${product.loja.nomeLoja}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${product.quantidade}x',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatCurrency(product.valorUnitario),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(product.quantidade * product.valorUnitario),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
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
            Icon(Icons.error_outline, size: 60, color: errorColor),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Seus pedidos aparecerão aqui quando você fizer uma compra',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Explorar produtos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
