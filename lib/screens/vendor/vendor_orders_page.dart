import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:im_stepper/stepper.dart';
import 'package:vizinhos_app/services/secure_storage.dart';

// Cores do tema com melhor contraste e acessibilidade
final primaryColor = const Color(0xFFFbbc2c);
final secondaryColor = const Color(0xFF3B4351);
final successColor = const Color(0xFF4CAF50);
final warningColor = const Color(0xFFFFA000);
final infoColor = const Color(0xFF2196F3);
final errorColor = const Color(0xFFE53935);

// Enum com nomes mais consistentes e descritivos
enum OrderStatus { 
  pending, 
  paid, 
  preparing, 
  inDelivery,
  readyForPickup,
  completed, 
  canceled 
}

// Enum para os tipos de ordenação
enum SortType {
  newest,    // Mais recentes primeiro
  oldest,    // Mais antigos primeiro
  statusAsc, // Status em ordem crescente (pendente → concluído)
  statusDesc // Status em ordem decrescente (concluído → pendente)
}

class Order {
  final String id;
  final DateTime date;
  final double total;
  final OrderStatus status;
  final List<OrderProduct> products;
  final String? deliveryType; // 'delivery' ou 'retirada'

  Order({
    required this.id,
    required this.date,
    required this.total,
    required this.status,
    required this.products,
    this.deliveryType,
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
      deliveryType: json['tipo_entrega']?.toString(),
    );
  }

  // Método melhorado para parsing de status com melhor tratamento de erros
  static OrderStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pago':
        return OrderStatus.paid;
      case 'em_preparo':
        return OrderStatus.preparing;
      case 'em_rota':
        return OrderStatus.inDelivery;
      case 'pronto_para_retirada':
        return OrderStatus.readyForPickup;
      case 'completo':
        return OrderStatus.completed;
      case 'cancelado':
        return OrderStatus.canceled;
      default:
        // Verificação adicional para garantir que status com variações de nome sejam reconhecidos
        if (status.toLowerCase().contains('rota')) {
          return OrderStatus.inDelivery;
        } else if (status.toLowerCase().contains('retirada')) {
          return OrderStatus.readyForPickup;
        }
        return OrderStatus.pending;
    }
  }

  // Método para converter OrderStatus para string da API
  static String statusToApiString(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return 'pago';
      case OrderStatus.preparing:
        return 'em_preparo';
      case OrderStatus.inDelivery:
        return 'em_rota';
      case OrderStatus.readyForPickup:
        return 'pronto_para_retirada';
      case OrderStatus.completed:
        return 'completo';
      case OrderStatus.canceled:
        return 'cancelado';
      default:
        return 'pendente';
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
    
    try {
      final response = await http.get(Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetOrdersByStore?id_Loja=$storeId'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['pedidos'] as List)
            .map((order) => Order.fromJson(order))
            .toList();
      } else {
        debugPrint('GetOrdersByStore error: statusCode=${response.statusCode}, body=${response.body}');
        throw Exception('Falha ao carregar pedidos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao buscar pedidos: $e');
      throw Exception('Falha ao carregar pedidos: $e');
    }
  }

  /// Send a request to change order status via API
  static Future<bool> changeOrderStatus(String orderId, OrderStatus newStatus) async {
    final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/ChangeOrderStatus'
    );
    
    final statusString = Order.statusToApiString(newStatus);
    final body = json.encode({'id_Pedido': orderId, 'status': statusString});
    
    debugPrint('ChangeOrderStatus -> Patch $url');
    debugPrint('Request body: $body');

    try {
      final response = await http.patch(url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      debugPrint('Response -> statusCode: ${response.statusCode}, body: ${response.body}');
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Falha ao atualizar status: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Erro ao atualizar status: $e');
      return false;
    }
  }
}

class OrdersVendorPage extends StatefulWidget {
  final String? deliveryType;
  const OrdersVendorPage({Key? key, this.deliveryType}) : super(key: key);

  @override
  _OrdersVendorPageState createState() => _OrdersVendorPageState();
}

class _OrdersVendorPageState extends State<OrdersVendorPage> 
    with WidgetsBindingObserver {
  late Future<List<Order>> _futureOrders;
  OrderStatus? _selectedStatus = OrderStatus.paid; // Filtro padrão: pagos
  List<Order> _allOrders = [];
  bool _isLoading = false;
  
  // Adicionando variável para controlar o tipo de ordenação
  SortType _currentSortType = SortType.newest;

  String? get deliveryType => widget.deliveryType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOrders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _loadOrders() {
    setState(() {
      _isLoading = true;
      _futureOrders = OrderService.fetchOrders().then((orders) {
        _allOrders = orders;
        _isLoading = false;
        return orders;
      }).catchError((error) {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar pedidos: $error'))
        );
        return <Order>[];
      });
    });
  }

  // Método para filtrar e ordenar os pedidos
  List<Order> _getFilteredAndSortedOrders() {
    // Primeiro filtramos por status (se houver um selecionado)
    List<Order> filteredOrders = _selectedStatus == null 
        ? List.from(_allOrders) 
        : _allOrders.where((o) => o.status == _selectedStatus).toList();
    
    // Depois ordenamos conforme o tipo de ordenação selecionado
    switch (_currentSortType) {
      case SortType.newest:
        filteredOrders.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortType.oldest:
        filteredOrders.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortType.statusAsc:
        filteredOrders.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case SortType.statusDesc:
        filteredOrders.sort((a, b) => b.status.index.compareTo(a.status.index));
        break;
    }
    
    return filteredOrders;
  }

  // Método para obter o nome do tipo de ordenação atual
  String _getSortTypeName(SortType type) {
    switch (type) {
      case SortType.newest:
        return 'Mais recentes';
      case SortType.oldest:
        return 'Mais antigos';
      case SortType.statusAsc:
        return 'Status (A → Z)';
      case SortType.statusDesc:
        return 'Status (Z → A)';
    }
  }

  // Método para obter o ícone do tipo de ordenação atual
  IconData _getSortTypeIcon(SortType type) {
    switch (type) {
      case SortType.newest:
        return Icons.arrow_downward;
      case SortType.oldest:
        return Icons.arrow_upward;
      case SortType.statusAsc:
        return Icons.sort;
      case SortType.statusDesc:
        return Icons.sort;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadOrders();
    }
  }

  /// Pull-to-refresh: reload orders when user swipes down
  Future<void> _refreshOrders() async {
    _loadOrders();
    await _futureOrders;
  }

  // Método para mostrar o diálogo de seleção de ordenação
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordenar por'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Opção: Mais recentes primeiro
            ListTile(
              leading: Icon(
                Icons.arrow_downward,
                color: _currentSortType == SortType.newest ? primaryColor : Colors.grey,
              ),
              title: const Text('Mais recentes primeiro'),
              selected: _currentSortType == SortType.newest,
              selectedColor: primaryColor,
              onTap: () {
                setState(() {
                  _currentSortType = SortType.newest;
                });
                Navigator.pop(context);
              },
            ),
            
            // Opção: Mais antigos primeiro
            ListTile(
              leading: Icon(
                Icons.arrow_upward,
                color: _currentSortType == SortType.oldest ? primaryColor : Colors.grey,
              ),
              title: const Text('Mais antigos primeiro'),
              selected: _currentSortType == SortType.oldest,
              selectedColor: primaryColor,
              onTap: () {
                setState(() {
                  _currentSortType = SortType.oldest;
                });
                Navigator.pop(context);
              },
            ),
            
            const Divider(),
            
            // Opção: Status em ordem crescente
            ListTile(
              leading: Icon(
                Icons.sort,
                color: _currentSortType == SortType.statusAsc ? primaryColor : Colors.grey,
              ),
              title: const Text('Status (Pendente → Concluído)'),
              selected: _currentSortType == SortType.statusAsc,
              selectedColor: primaryColor,
              onTap: () {
                setState(() {
                  _currentSortType = SortType.statusAsc;
                });
                Navigator.pop(context);
              },
            ),
            
            // Opção: Status em ordem decrescente
            ListTile(
              leading: Icon(
                Icons.sort,
                color: _currentSortType == SortType.statusDesc ? primaryColor : Colors.grey,
              ),
              title: const Text('Status (Concluído → Pendente)'),
              selected: _currentSortType == SortType.statusDesc,
              selectedColor: primaryColor,
              onTap: () {
                setState(() {
                  _currentSortType = SortType.statusDesc;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
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
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filtro e ordenação com design melhorado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Primeira linha: Filtro por status
                  Row(
                    children: [
                      Icon(Icons.filter_alt_outlined, color: secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Filtrar:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButton<OrderStatus?>(
                              value: _selectedStatus,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Todos'),
                                ),
                                DropdownMenuItem(
                                  value: OrderStatus.paid,
                                  child: Row(
                                    children: [
                                      Icon(Icons.payments_outlined, size: 18, color: infoColor),
                                      const SizedBox(width: 8),
                                      const Text('Pagos'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: OrderStatus.preparing,
                                  child: Row(
                                    children: [
                                      Icon(Icons.restaurant, size: 18, color: warningColor),
                                      const SizedBox(width: 8),
                                      const Text('Em preparo'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: OrderStatus.inDelivery,
                                  child: Row(
                                    children: [
                                      Icon(Icons.delivery_dining, size: 18, color: infoColor),
                                      const SizedBox(width: 8),
                                      const Text('Em rota'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: OrderStatus.readyForPickup,
                                  child: Row(
                                    children: [
                                      Icon(Icons.store, size: 18, color: warningColor),
                                      const SizedBox(width: 8),
                                      const Text('Pronto para retirada'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: OrderStatus.completed,
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 18, color: successColor),
                                      const SizedBox(width: 8),
                                      const Text('Concluídos'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: OrderStatus.canceled,
                                  child: Row(
                                    children: [
                                      Icon(Icons.cancel, size: 18, color: errorColor),
                                      const SizedBox(width: 8),
                                      const Text('Cancelados'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: OrderStatus.pending,
                                  child: Row(
                                    children: [
                                      Icon(Icons.hourglass_empty, size: 18, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      const Text('Pendentes'),
                                    ],
                                  ),
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
                  
                  const SizedBox(height: 12),
                  
                  // Segunda linha: Ordenação
                  InkWell(
                    onTap: _showSortDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sort, color: secondaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Ordenar por:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getSortTypeName(_currentSortType),
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            _getSortTypeIcon(_currentSortType),
                            color: primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de pedidos
            Expanded(
              child: FutureBuilder<List<Order>>(
                future: _futureOrders,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Carregando pedidos...'),
                        ],
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: errorColor),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar pedidos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: errorColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadOrders,
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
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (_allOrders.isEmpty && snapshot.data != null) {
                    _allOrders = snapshot.data!;
                  }
                  
                  final orders = _getFilteredAndSortedOrders();
                  
                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum pedido encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF666666)
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedStatus != null 
                                ? 'Tente selecionar outro filtro'
                                : 'Não há pedidos disponíveis no momento',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshOrders,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Atualizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      // Wrap list in RefreshIndicator for pull-to-refresh
                      return RefreshIndicator(
                        onRefresh: _refreshOrders,
                        color: primaryColor,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? constraints.maxWidth * 0.1 : 16,
                            vertical: 16,
                          ),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return OrderCard(
                              order: orders[index],
                              isWide: isWide,
                              onStatusChanged: _loadOrders,
                            );
                          },
                        ),
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

class OrderCard extends StatefulWidget {
  final Order order;
  final bool isWide;
  final VoidCallback onStatusChanged;

  const OrderCard({
    required this.order,
    this.isWide = false,
    required this.onStatusChanged,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  OrderStatus? _selectedNextStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _initializeNextStatus();
  }

  // Inicializa o próximo status baseado no tipo de entrega e status atual
  void _initializeNextStatus() {
    final order = widget.order;
    
    if (order.status == OrderStatus.preparing) {
      // Seleciona automaticamente o próximo status baseado no tipo de entrega
      if (order.deliveryType == 'delivery') {
        _selectedNextStatus = OrderStatus.inDelivery;
      } else if (order.deliveryType == 'retirada') {
        _selectedNextStatus = OrderStatus.readyForPickup;
      }
    }
  }

  // Cores mais vibrantes e acessíveis para os status
  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return Colors.blue[700]!;
      case OrderStatus.preparing:
        return Colors.orange[700]!;
      case OrderStatus.inDelivery:
        return Colors.lightBlue[700]!;
      case OrderStatus.readyForPickup:
        return Colors.amber[700]!;
      case OrderStatus.completed:
        return Colors.green[700]!;
      case OrderStatus.canceled:
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  // Ícones para cada status
  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return Icons.payments_outlined;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.inDelivery:
        return Icons.delivery_dining;
      case OrderStatus.readyForPickup:
        return Icons.store;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.canceled:
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return 'Pago';
      case OrderStatus.preparing:
        return 'Em preparo';
      case OrderStatus.inDelivery:
        return 'Em rota';
      case OrderStatus.readyForPickup:
        return 'Pronto para retirada';
      case OrderStatus.completed:
        return 'Concluído';
      case OrderStatus.canceled:
        return 'Cancelado';
      default:
        return 'Pendente';
    }
  }

  // Método para atualizar o status do pedido
  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final success = await OrderService.changeOrderStatus(widget.order.id, newStatus);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(_statusIcon(newStatus), color: Colors.white),
                const SizedBox(width: 12),
                Text('Status atualizado: ${_statusLabel(newStatus)}'),
              ],
            ),
            backgroundColor: _statusColor(newStatus),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        widget.onStatusChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Falha ao atualizar status'),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(widget.isWide ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status stepper usando im_stepper
            ImStepperWidget(order: order),
            const SizedBox(height: 16),
            
            // Cabeçalho do pedido com informações principais
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _statusColor(order.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(order.status),
                        size: 18,
                        color: _statusColor(order.status),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusLabel(order.status),
                        style: TextStyle(
                          color: _statusColor(order.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        order.deliveryType == 'delivery' 
                            ? Icons.delivery_dining 
                            : Icons.store,
                        size: 16,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.deliveryType == 'delivery' ? 'Entrega' : 'Retirada',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: secondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // ID do pedido e data
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${order.id.substring(0, 6).toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(order.date),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Lista de produtos com design melhorado
            ...order.products.map((product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.image,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                      if (product.quantity > 1)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              '${product.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${product.quantity}x',
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
                              'R\$${product.unitPrice.toStringAsFixed(2)}',
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
                    'R\$${(product.quantity * product.unitPrice).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )),
            
            const Divider(height: 24),
            
            // Total do pedido com design melhorado
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
                  'R\$${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Botões de ação com design melhorado
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final order = widget.order;
    
    // Pedido pago → Iniciar preparo
    if (order.status == OrderStatus.paid) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.restaurant),
              label: const Text('Iniciar preparo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isUpdating 
                  ? null 
                  : () => _updateOrderStatus(OrderStatus.preparing),
            ),
          ),
        ],
      );
    }
    
    // Em preparo → Em rota (delivery) ou Pronto para retirada (retirada)
    if (order.status == OrderStatus.preparing) {
      // Interface melhorada para seleção do próximo status
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Texto explicativo
          Text(
            'Selecione o próximo status do pedido:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          
          // Opções de status como cards selecionáveis
          Row(
            children: [
              // Opção "Em rota" (para delivery)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedNextStatus = OrderStatus.inDelivery;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedNextStatus == OrderStatus.inDelivery
                          ? infoColor.withOpacity(0.15)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedNextStatus == OrderStatus.inDelivery
                            ? infoColor
                            : Colors.grey[300]!,
                        width: _selectedNextStatus == OrderStatus.inDelivery ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          size: 28,
                          color: _selectedNextStatus == OrderStatus.inDelivery
                              ? infoColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Em rota',
                          style: TextStyle(
                            fontWeight: _selectedNextStatus == OrderStatus.inDelivery
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _selectedNextStatus == OrderStatus.inDelivery
                                ? infoColor
                                : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Para delivery',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Opção "Pronto para retirada"
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedNextStatus = OrderStatus.readyForPickup;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedNextStatus == OrderStatus.readyForPickup
                          ? warningColor.withOpacity(0.15)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedNextStatus == OrderStatus.readyForPickup
                            ? warningColor
                            : Colors.grey[300]!,
                        width: _selectedNextStatus == OrderStatus.readyForPickup ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.store,
                          size: 28,
                          color: _selectedNextStatus == OrderStatus.readyForPickup
                              ? warningColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pronto para retirada',
                          style: TextStyle(
                            fontWeight: _selectedNextStatus == OrderStatus.readyForPickup
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _selectedNextStatus == OrderStatus.readyForPickup
                                ? warningColor
                                : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Para retirada na loja',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Botão de atualização
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedNextStatus == OrderStatus.inDelivery
                  ? infoColor
                  : (_selectedNextStatus == OrderStatus.readyForPickup
                      ? warningColor
                      : Colors.blue),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _selectedNextStatus == null || _isUpdating
                ? null
                : () => _updateOrderStatus(_selectedNextStatus!),
            child: _isUpdating
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Atualizando...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_selectedNextStatus == OrderStatus.inDelivery
                          ? Icons.delivery_dining
                          : Icons.store),
                      const SizedBox(width: 8),
                      Text(
                        _selectedNextStatus == OrderStatus.inDelivery
                            ? 'Confirmar saída para entrega'
                            : 'Confirmar pronto para retirada',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
          
          // Dica para o usuário
          if (_selectedNextStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _selectedNextStatus == OrderStatus.inDelivery
                    ? 'O cliente será notificado que o pedido está em rota de entrega.'
                    : 'O cliente será notificado que o pedido está pronto para retirada na loja.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    }
    
    // Em rota ou Pronto para retirada → Concluído
    if (order.status == OrderStatus.inDelivery || order.status == OrderStatus.readyForPickup) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: Text(
              order.status == OrderStatus.inDelivery
                  ? 'Confirmar entrega'
                  : 'Confirmar retirada',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: successColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isUpdating
                ? null
                : () => _updateOrderStatus(OrderStatus.completed),
          ),
          
          // Dica para o usuário
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              order.status == OrderStatus.inDelivery
                  ? 'Confirme apenas quando o pedido for entregue ao cliente.'
                  : 'Confirme apenas quando o cliente retirar o pedido na loja.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    
    // Pedido concluído - mostrar mensagem de confirmação
    if (order.status == OrderStatus.completed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: successColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: successColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido concluído com sucesso',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: successColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Este pedido foi finalizado e não requer mais ações.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Pedido cancelado - mostrar mensagem de cancelamento
    if (order.status == OrderStatus.canceled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: errorColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: errorColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido cancelado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: errorColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Este pedido foi cancelado e não requer mais ações.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}

// Widget de stepper usando im_stepper
class ImStepperWidget extends StatelessWidget {
  final Order order;
  
  const ImStepperWidget({required this.order});

  @override
  Widget build(BuildContext context) {
    // Determina o tipo de entrega do pedido
    final String deliveryType = order.deliveryType?.toLowerCase() ?? '';
    final bool isDelivery = deliveryType == 'delivery';
    
    // Determina o status atual para exibição dinâmica
    final bool isInDelivery = order.status == OrderStatus.inDelivery;
    final bool isReadyForPickup = order.status == OrderStatus.readyForPickup;
    
    // Determina o texto e ícone do quarto passo com base no status atual e tipo de entrega
    String fourthStepLabel;
    IconData fourthStepIcon;
    
    // Lógica para determinar o texto e ícone do quarto passo
    if (isDelivery || isInDelivery) {
      // Para delivery ou quando o status já é "Em rota"
      fourthStepLabel = 'Em rota';
      fourthStepIcon = Icons.delivery_dining;
    } else {
      // Para retirada ou quando o status já é "Pronto para retirada"
      fourthStepLabel = 'Pronto para retirada';
      fourthStepIcon = Icons.store;
    }
    
    // Determina o step atual com lógica melhorada para garantir o avanço correto
    int activeStep = 0;
    
    // Primeiro verificamos o status pelo enum para garantir consistência
    switch (order.status) {
      case OrderStatus.completed:
        activeStep = 4;
        break;
      case OrderStatus.inDelivery:
        activeStep = 3;
        break;
      case OrderStatus.readyForPickup:
        activeStep = 3;
        break;
      case OrderStatus.preparing:
        activeStep = 2;
        break;
      case OrderStatus.paid:
        activeStep = 1;
        break;
      default:
        activeStep = 0;
    }
    
    // Verificação adicional para garantir que o status seja exibido corretamente
    if (order.status.toString().contains('inDelivery') || 
        (order.deliveryType == 'delivery' && order.status.toString().toLowerCase().contains('rota'))) {
      activeStep = 3;
    } else if (order.status.toString().contains('readyForPickup') || 
               (order.deliveryType == 'retirada' && order.status.toString().toLowerCase().contains('retirada'))) {
      activeStep = 3;
    }
    
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
      isDelivery ? 'Pedido entregue' : 'Pedido retirado',
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Usando IconStepper do pacote im_stepper
          IconStepper(
            icons: icons.map((icon) => Icon(icon)).toList(),
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
          
          // Adicionando os textos abaixo dos ícones
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
          
          // Data do pedido
          if (order.date != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(order.date),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}
