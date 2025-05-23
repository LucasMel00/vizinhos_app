import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Importar apenas o que precisamos
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

enum DeliveryType {
  delivery,
  pickup
}

// Classe simples para armazenar as opções de filtro
class OrderFilters {
  DateTime? startDate;
  DateTime? endDate;
  Set<OrderStatus> statusFilters;
  Set<DeliveryType> deliveryTypes;
  
  OrderFilters({
    this.startDate,
    this.endDate,
    Set<OrderStatus>? statusFilters,
    Set<DeliveryType>? deliveryTypes,
  }) : 
    statusFilters = statusFilters ?? {},
    deliveryTypes = deliveryTypes ?? {};
    
  bool get isEmpty => 
    startDate == null && 
    endDate == null && 
    statusFilters.isEmpty && 
    deliveryTypes.isEmpty;
    
  int get activeFilterCount {
    int count = 0;
    if (startDate != null) count++;
    if (endDate != null) count++;
    count += statusFilters.length;
    count += deliveryTypes.length;
    return count;
  }
  
  // Reset all filters
  void reset() {
    startDate = null;
    endDate = null;
    statusFilters.clear();
    deliveryTypes.clear();
  }
  
  // Create a copy of the current filters
  OrderFilters copy() {
    return OrderFilters(
      startDate: startDate,
      endDate: endDate,
      statusFilters: Set.from(statusFilters),
      deliveryTypes: Set.from(deliveryTypes),
    );
  }
}

// Widget de diálogo para o filtro de pedidos
class OrderFilterDialog extends StatefulWidget {
  final OrderFilters filters;
  final Color primaryColor;
  final Function(OrderFilters) onApply;
  
  const OrderFilterDialog({
    Key? key,
    required this.filters,
    required this.primaryColor,
    required this.onApply,
  }) : super(key: key);
  
  @override
  _OrderFilterDialogState createState() => _OrderFilterDialogState();
}

class _OrderFilterDialogState extends State<OrderFilterDialog> {
  late OrderFilters _tempFilters;
  
  @override
  void initState() {
    super.initState();
    _tempFilters = widget.filters.copy();
  }
  
  // Retorna uma string formatada para exibição da data
  String _formatDate(DateTime? date) {
    if (date == null) return "Selecionar";
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Retorna o nome amigável do status
  String _getStatusName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Pendente';
      case OrderStatus.awaitingPayment: return 'Aguardando Pagamento';
      case OrderStatus.paid: return 'Pago';
      case OrderStatus.preparing: return 'Em Preparo';
      case OrderStatus.inDelivery: return 'Em Rota';
      case OrderStatus.readyForPickup: return 'Pronto para Retirada';
      case OrderStatus.completed: return 'Concluído';
      case OrderStatus.canceled: return 'Cancelado';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.filter_list, color: widget.primaryColor),
          const SizedBox(width: 8),
          const Text('Filtrar Pedidos'),
          const Spacer(),
          // Botão para limpar filtros
          TextButton(
            onPressed: () {
              setState(() {
                _tempFilters.reset();
              });
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtro por período
            const Text(
              'Período',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            // Data inicial
            Row(
              children: [
                const Text('De: '),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_formatDate(_tempFilters.startDate)),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _tempFilters.startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: widget.primaryColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _tempFilters.startDate = picked;
                      });
                    }
                  },
                ),
                if (_tempFilters.startDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _tempFilters.startDate = null;
                      });
                    },
                  ),
              ],
            ),
            
            // Data final
            Row(
              children: [
                const Text('Até: '),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_formatDate(_tempFilters.endDate)),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _tempFilters.endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: widget.primaryColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _tempFilters.endDate = picked;
                      });
                    }
                  },
                ),
                if (_tempFilters.endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _tempFilters.endDate = null;
                      });
                    },
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Filtro por status
            const Text(
              'Status do Pedido',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            // Lista de chips para status
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OrderStatus.values.map((status) {
                final isSelected = _tempFilters.statusFilters.contains(status);
                return FilterChip(
                  selected: isSelected,
                  label: Text(_getStatusName(status)),
                  selectedColor: widget.primaryColor.withOpacity(0.2),
                  showCheckmark: false,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _tempFilters.statusFilters.add(status);
                      } else {
                        _tempFilters.statusFilters.remove(status);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Filtro por tipo de entrega
            const Text(
              'Tipo de Entrega',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            // Lista de chips para tipo de entrega
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Chip para entrega
                FilterChip(
                  selected: _tempFilters.deliveryTypes.contains(DeliveryType.delivery),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.delivery_dining, size: 16),
                      SizedBox(width: 4),
                      Text('Entrega'),
                    ],
                  ),
                  selectedColor: widget.primaryColor.withOpacity(0.2),
                  showCheckmark: false,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _tempFilters.deliveryTypes.add(DeliveryType.delivery);
                      } else {
                        _tempFilters.deliveryTypes.remove(DeliveryType.delivery);
                      }
                    });
                  },
                ),
                
                const SizedBox(width: 8),
                
                // Chip para retirada
                FilterChip(
                  selected: _tempFilters.deliveryTypes.contains(DeliveryType.pickup),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.store, size: 16),
                      SizedBox(width: 4),
                      Text('Retirada'),
                    ],
                  ),
                  selectedColor: widget.primaryColor.withOpacity(0.2),
                  showCheckmark: false,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _tempFilters.deliveryTypes.add(DeliveryType.pickup);
                      } else {
                        _tempFilters.deliveryTypes.remove(DeliveryType.pickup);
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Aplicar'),
          onPressed: () {
            widget.onApply(_tempFilters);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
