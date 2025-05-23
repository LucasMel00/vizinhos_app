import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderFiltersWidget extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<OrderStatus> selectedStatusFilters;
  final Set<DeliveryType> selectedDeliveryTypes;
  final bool isFilterActive;
  final Function(DateTime?, DateTime?, Set<OrderStatus>, Set<DeliveryType>, bool) onApplyFilters;
  final Function() onResetFilters;
  
  const OrderFiltersWidget({
    Key? key,
    this.startDate,
    this.endDate,
    required this.selectedStatusFilters,
    required this.selectedDeliveryTypes,
    required this.isFilterActive,
    required this.onApplyFilters,
    required this.onResetFilters,
  }) : super(key: key);

  @override
  _OrderFiltersWidgetState createState() => _OrderFiltersWidgetState();
}

class _OrderFiltersWidgetState extends State<OrderFiltersWidget> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late Set<OrderStatus> _selectedStatusFilters;
  late Set<DeliveryType> _selectedDeliveryTypes;
  
  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedStatusFilters = Set.from(widget.selectedStatusFilters);
    _selectedDeliveryTypes = Set.from(widget.selectedDeliveryTypes);
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Row(
            children: [
              const Text(
                'Filtrar Pedidos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Botão para redefinir filtros
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Redefinir'),
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _selectedStatusFilters.clear();
                    _selectedDeliveryTypes.clear();
                  });
                  widget.onResetFilters();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Filtro de período
          const Text(
            'Período',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  'Data inicial',
                  _startDate,
                  (date) => setState(() => _startDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  'Data final',
                  _endDate,
                  (date) => setState(() => _endDate = date),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Filtro de status
          const Text(
            'Status do Pedido',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusFilterChip(OrderStatus.pending, 'Pendente'),
              _buildStatusFilterChip(OrderStatus.awaitingPayment, 'Aguardando Pagamento'),
              _buildStatusFilterChip(OrderStatus.paid, 'Pago'),
              _buildStatusFilterChip(OrderStatus.preparing, 'Em Preparo'),
              _buildStatusFilterChip(OrderStatus.inDelivery, 'Em Rota'),
              _buildStatusFilterChip(OrderStatus.readyForPickup, 'Pronto para Retirada'),
              _buildStatusFilterChip(OrderStatus.completed, 'Concluído'),
              _buildStatusFilterChip(OrderStatus.canceled, 'Cancelado'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Filtro de tipo de entrega
          const Text(
            'Tipo de Entrega',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDeliveryTypeFilterChip(DeliveryType.delivery, 'Entrega'),
              _buildDeliveryTypeFilterChip(DeliveryType.pickup, 'Retirada'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aplicar Filtros'),
                  onPressed: () {
                    final isActive = _startDate != null ||
                                    _endDate != null ||
                                    _selectedStatusFilters.isNotEmpty ||
                                    _selectedDeliveryTypes.isNotEmpty;
                    
                    widget.onApplyFilters(
                      _startDate,
                      _endDate,
                      _selectedStatusFilters,
                      _selectedDeliveryTypes,
                      isActive,
                    );
                    
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Widget para seleção de data
  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime?) onChanged) {
    final dateString = selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(selectedDate)
        : 'Selecionar';
    
    return InkWell(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  dateString,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para filtro de status
  Widget _buildStatusFilterChip(OrderStatus status, String label) {
    final bool isSelected = _selectedStatusFilters.contains(status);
    
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      showCheckmark: false,
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedStatusFilters.add(status);
          } else {
            _selectedStatusFilters.remove(status);
          }
        });
      },
    );
  }
  
  // Widget para filtro de tipo de entrega
  Widget _buildDeliveryTypeFilterChip(DeliveryType type, String label) {
    final bool isSelected = _selectedDeliveryTypes.contains(type);
    final IconData icon = type == DeliveryType.delivery ? Icons.delivery_dining : Icons.store;
    
    return FilterChip(
      selected: isSelected,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
      ),
      label: Text(label),
      showCheckmark: false,
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDeliveryTypes.add(type);
          } else {
            _selectedDeliveryTypes.remove(type);
          }
        });
      },
    );
  }
}

// Importação de enums necessários (deve ser adaptada ao seu código)
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
