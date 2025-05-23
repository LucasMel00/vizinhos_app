import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For copy to clipboard
import 'package:intl/intl.dart';
import 'package:im_stepper/stepper.dart'; // Importando o pacote im_stepper
import 'package:vizinhos_app/screens/user/home_page_user.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/screens/user/user_account_page.dart';
import '../model/order_models.dart';
import '../provider/order_service.dart';
import 'order_review_page.dart';

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
  canceled,
  refunded
}

// Enum para tipos de entrega
enum DeliveryType { delivery, pickup }

// Enum para ordenação de pedidos
enum SortOrder { newest, oldest }

class OrdersPage extends StatefulWidget {
  final String cpf;
  const OrdersPage({Key? key, required this.cpf}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrdersService _ordersService = OrdersService();
  List<OrderModel> _allOrders = [];
  List<OrderModel> _filteredOrders = [];
  bool _isLoading = false;
  Map<String, bool> _updatingStatus = {};

  // Variáveis para filtros
  DateTime? _startDate;
  DateTime? _endDate;
  Set<OrderStatus> _selectedStatusFilters = {};
  Set<DeliveryType> _selectedDeliveryTypes = {};
  bool _isFilterActive = false;
  
  // Variável para ordenação
  SortOrder _currentSortOrder = SortOrder.newest;
  
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  /// Loads orders, updates pending payments, and refreshes UI
  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      // Fetch and update pending-payment orders first
      final resp = await _ordersService.getOrdersByUser(widget.cpf);
      final pending = resp.pedidos
          .where((o) => o.statusPedido.toLowerCase().contains('aguardando pagamento'));
      await Future.wait(pending.map((o) => _ordersService.updateOrderStatus(o.idPedido)));
      // Fetch fresh orders list
      final fresh = await _ordersService.getOrdersByUser(widget.cpf);
      setState(() {
        _allOrders = fresh.pedidos;
      });
      // Apply current filters and sorting
      _applyFilters();
    } catch (e) {
      debugPrint('Erro ao carregar pedidos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Pull-to-refresh handler
  Future<void> _refreshOrders() async {
    await _loadOrders();
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
      setState(() => _allOrders = _allOrders.map((order) {
        if (order.idPedido == idPedido) {
          // Retorna uma nova instância de OrderModel com os mesmos dados, mas com o status atualizado
          return OrderModel(
            idPedido: order.idPedido,
            dataPedido: order.dataPedido,
            statusPedido: order.statusPedido, // Este campo será atualizado
            valorTotal: order.valorTotal,
            qrCode: order.qrCode,
            tipoEntrega: order.tipoEntrega,
            produtos: order.produtos, 
            idPagamento: order.idPagamento,
          );
        }
        return order;
      }).toList());
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
  // Método para aplicar os filtros e ordenação nos pedidos
  void _applyFilters() {
    List<OrderModel> filteredList;
    
    if (!_isFilterActive) {
      filteredList = List.from(_allOrders);
    } else {
      filteredList = _allOrders.where((order) {
        // Filtro por data
        if (_startDate != null || _endDate != null) {
          final orderDate = DateTime.parse(order.dataPedido);
          
          if (_startDate != null && orderDate.isBefore(_startDate!)) {
            return false;
          }
          
          if (_endDate != null) {
            // Adiciona 1 dia ao endDate para incluir pedidos feitos no próprio dia final
            final endDatePlusOne = _endDate!.add(const Duration(days: 1));
            if (orderDate.isAfter(endDatePlusOne)) {
              return false;
            }
          }
        }
        
        // Filtro por status
        if (_selectedStatusFilters.isNotEmpty) {
          final orderStatus = OrderUtils.parseOrderStatus(order.statusPedido);
          if (!_selectedStatusFilters.contains(orderStatus)) {
            return false;
          }
        }
        
        // Filtro por tipo de entrega
        if (_selectedDeliveryTypes.isNotEmpty) {
          final deliveryType = OrderUtils.getDeliveryType(order);
          if (!_selectedDeliveryTypes.contains(deliveryType)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    }
    
    // Aplicar ordenação
    filteredList.sort((a, b) {
      final dateA = DateTime.parse(a.dataPedido);
      final dateB = DateTime.parse(b.dataPedido);
      
      if (_currentSortOrder == SortOrder.newest) {
        return dateB.compareTo(dateA); // Mais recentes primeiro
      } else {
        return dateA.compareTo(dateB); // Mais antigos primeiro
      }
    });

    setState(() {
      _filteredOrders = filteredList;
    });
  }

  Widget _buildNavIcon(IconData icon, String label, int index, BuildContext context) {
    final bool isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // Navigate to the corresponding page
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
          case 2:
            // Current page
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
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
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
      child: Scaffold(        appBar: AppBar(
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
          actions: [
            // Botão para alternar ordenação
            PopupMenuButton<SortOrder>(
              icon: const Icon(Icons.sort, color: Colors.white),
              onSelected: (SortOrder order) {
                setState(() {
                  _currentSortOrder = order;
                });
                _applyFilters();
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOrder>>[
                PopupMenuItem<SortOrder>(
                  value: SortOrder.newest,
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: _currentSortOrder == SortOrder.newest ? primaryColor : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mais Recentes',
                        style: TextStyle(
                          color: _currentSortOrder == SortOrder.newest ? primaryColor : Colors.black,
                          fontWeight: _currentSortOrder == SortOrder.newest ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<SortOrder>(
                  value: SortOrder.oldest,
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: _currentSortOrder == SortOrder.oldest ? primaryColor : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mais Antigos',
                        style: TextStyle(
                          color: _currentSortOrder == SortOrder.oldest ? primaryColor : Colors.black,
                          fontWeight: _currentSortOrder == SortOrder.oldest ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator.adaptive(
          onRefresh: _refreshOrders,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator.adaptive(),
                      SizedBox(height: 16),
                      Text('Carregando seus pedidos...'),
                    ],
                  ),
                );              }
              if (_allOrders.isEmpty) {
                return const _EmptyOrdersView();
              }
              
              // Constrain width on large screens
              return ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth:
                        constraints.maxWidth > 600 ? 600 : double.infinity),
                child: Column(
                  children: [
                    // Indicador de ordenação
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _currentSortOrder == SortOrder.newest 
                                ? Icons.arrow_downward 
                                : Icons.arrow_upward,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentSortOrder == SortOrder.newest 
                                ? 'Ordenados por: Mais Recentes' 
                                : 'Ordenados por: Mais Antigos',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_filteredOrders.length} pedido${_filteredOrders.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Lista de pedidos
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _filteredOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          return _OrderCard(
                            order: order,
                            updating: _updatingStatus[order.idPedido] ?? false,
                            onUpdateStatus: _updateOrderStatus,
                            formatDate: _formatDate,
                            formatCurrency: _formatCurrency,
                            parseOrderStatus: OrderUtils.parseOrderStatus,
                            getDeliveryType: OrderUtils.getDeliveryType,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
                // Botão de avaliação para pedidos concluídos
                if (orderStatus == OrderStatus.completed) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderReviewPage(
                              orderId: order.idPedido,
                              idEndereco: int.tryParse(order.produtos.first.loja.idLoja) ?? 0,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: successColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Avaliar Pedido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
        break;      case OrderStatus.canceled:
        color = Colors.red[700]!;
        icon = Icons.cancel;
        label = 'Cancelado';
        break;
      case OrderStatus.refunded:
        color = Colors.orange[700]!;
        icon = Icons.monetization_on;
        label = 'Reembolsado';
        break;
    }
    
    // Se o status original tiver um texto específico, usá-lo em vez do padrão
    if (order.statusPedido.isNotEmpty) {
      // Ajustando o status "completo" para exibir "Pedido entregue" ou "Completo" corretamente
      if (status == OrderStatus.completed) {
        label = order.statusPedido.toLowerCase().contains('entregue') ? 'Pedido entregue' : 'Completo';
      } else {
        label = order.statusPedido;
      }
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
    // Para pedidos cancelados ou reembolsados, mostra uma representação visual diferente
    if (orderStatus == OrderStatus.canceled) {
      return _buildCanceledStepper(context);
    }

    if (orderStatus == OrderStatus.refunded) {
      return _buildRefundedStepper(context);
    }

    
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
  
  // Widget especial para pedidos cancelados
  Widget _buildCanceledStepper(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Linha visual para pedidos cancelados
          Row(
            children: [
              // Primeiro passo: Pedido realizado (sempre ativo)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              // Linha tracejada para cancelamento
              Expanded(
                child: CustomPaint(
                  size: const Size(double.infinity, 3),
                  painter: DashedLinePainter(
                    color: Colors.red[400]!,
                    strokeWidth: 3,
                  ),
                ),
              ),
              // Ícone de cancelamento
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.cancel,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Labels para pedidos cancelados
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pedido realizado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Pedido cancelado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mensagem explicativa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.red[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este pedido foi cancelado ',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget especial para pedidos reembolsados
  Widget _buildRefundedStepper(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
      color: Colors.orange[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.orange[200]!,
        width: 1,
      ),
      ),
      child: Column(
      children: [
        // Linha visual para pedidos reembolsados
        Row(
        children: [
          // Primeiro passo: Pedido realizado
          Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.shopping_bag,
            color: Colors.white,
            size: 20,
          ),
          ),
          // Linha tracejada para reembolso
          Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 3),
            painter: DashedLinePainter(
            color: Colors.orange[400]!,
            strokeWidth: 3,
            ),
          ),
          ),
          // Ícone de reembolso
          Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.orange[700],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.monetization_on,
            color: Colors.white,
            size: 20,
          ),
          ),
        ],
        ),
        const SizedBox(height: 12),
        // Labels para pedidos reembolsados
        Row(
        children: [
          Expanded(
          child: Text(
            'Pedido realizado',
            textAlign: TextAlign.center,
            style: TextStyle(
            fontSize: 12,
            color: primaryColor,
            fontWeight: FontWeight.w500,
            ),
          ),
          ),
          Expanded(
          child: Text(
            'Pedido reembolsado',
            textAlign: TextAlign.center,
            style: TextStyle(
            fontSize: 12,
            color: Colors.orange[700],
            fontWeight: FontWeight.bold,
            ),
          ),
          ),
        ],
        ),
        const SizedBox(height: 8),
        // Mensagem explicativa
        Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
            'Seu pedido foi rejeitado e o reembolso será processado em até 48 horas úteis',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange[800],
            ),
            textAlign: TextAlign.center,
            ),
          ),
          ],
        ),
        ),
      ],
      ),
    );
    }
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
      case OrderStatus.refunded:
        return 0; // Para reembolsados, mostramos no início
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
            onPressed: () {            Navigator.pushReplacement(
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

// Custom painter para criar linhas tracejadas
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  
  DashedLinePainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    double startX = 0;
    final y = size.height / 2;
    
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ImStepperWidget extends StatelessWidget {
  final OrderModel order;

  const ImStepperWidget({required this.order});

  @override
  Widget build(BuildContext context) {
    int activeStep = 0;

    switch (OrderUtils.parseOrderStatus(order.statusPedido)) {
      case OrderStatus.pending:
        activeStep = 0;
        break;
      case OrderStatus.paid:
        activeStep = 1;
        break;
      case OrderStatus.preparing:
        activeStep = 2;
        break;
      case OrderStatus.inDelivery:
      case OrderStatus.readyForPickup:
        activeStep = 3;
        break;
      case OrderStatus.completed:
        activeStep = 4;
        break;      case OrderStatus.canceled:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, color: errorColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pedido cancelado',
                style: TextStyle(
                  color: errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case OrderStatus.refunded:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.orange[700]!.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pedido reembolsado',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'O reembolso será processado em até 48 horas',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      case OrderStatus.awaitingPayment:
        activeStep = 0;
        break;
    }

    List<IconData> icons = [
      Icons.shopping_cart,
      Icons.payments_outlined,
      Icons.restaurant,
      order.tipoEntrega == 'delivery'
          ? Icons.delivery_dining
          : Icons.store,
      Icons.check_circle,
    ];

    return Container(
      height: 70,
      child: IconStepper(
        icons: icons.map((icon) => Icon(icon)).toList(),
        activeStep: activeStep,
        enableNextPreviousButtons: false,
        enableStepTapping: false,
        activeStepColor: primaryColor,
        activeStepBorderColor: primaryColor,
        activeStepBorderWidth: 1,
        activeStepBorderPadding: 3,
        lineColor: Colors.grey[300],
        lineLength: 50,
        lineDotRadius: 2,
        stepRadius: 16,
        stepColor: Colors.grey[200],
        stepPadding: 0,
      ),
    );
  }
}

class OrderUtils {  static OrderStatus parseOrderStatus(String status) {
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
    } else if (statusLower.contains('completo') || statusLower.contains('entregue') || statusLower.contains('retirado')) {
      return OrderStatus.completed;
    } else if (statusLower.contains('cancelado')) {
      return OrderStatus.canceled;
    } else if (statusLower.contains('reembolsado')) {
      return OrderStatus.refunded;
    } else if (statusLower.contains('pendente')) {
      return OrderStatus.pending;
    } else {
      return OrderStatus.pending;
    }
  }

  static DeliveryType getDeliveryType(OrderModel order) {
    if (order.tipoEntrega != null) {
      final tipoLower = order.tipoEntrega!.toLowerCase();
      if (tipoLower.contains('delivery') || tipoLower.contains('entrega')) {
        return DeliveryType.delivery;
      } else if (tipoLower.contains('retirada') || tipoLower.contains('pickup')) {
        return DeliveryType.pickup;
      }
    }

    final statusLower = order.statusPedido.toLowerCase();
    if (statusLower.contains('rota') || statusLower.contains('caminho')) {
      return DeliveryType.delivery;
    } else if (statusLower.contains('retirada')) {
      return DeliveryType.pickup;
    }

    return DeliveryType.delivery;
  }
}
