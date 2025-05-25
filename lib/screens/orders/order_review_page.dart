import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../provider/order_service.dart';

class OrderReviewPage extends StatefulWidget {
  final String orderId;
  final int idEndereco;
  const OrderReviewPage(
      {Key? key, required this.orderId, required this.idEndereco})
      : super(key: key);

  @override
  _OrderReviewPageState createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage>
    with SingleTickerProviderStateMixin {
  int _rating = 5;
  // Predefined positive and negative characteristics
  final List<String> _positiveOptions = [
    'Entrega rápida',
    'Produto bem embalado',
    'Atendimento cordial',
    'Preço justo',
    'Comunicação eficiente',
    'Embalagem segura',
  ];
  final List<String> _negativeOptions = [
    'Entrega lenta',
    'Produto danificado',
    'Atendimento frio',
    'Preço alto',
    'Falta de comunicação',
    'Embalagem danificada',
  ];
  final Set<String> _selectedChars = {};
  bool _isSubmitting = false;
  late AnimationController _starController;

  final OrdersService _service = OrdersService();

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // longer for smoother effect
    );
  }

  void _submitReview() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final storage = const FlutterSecureStorage();
    final cpf = await storage.read(key: 'cpf');
    if (cpf == null || cpf.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CPF do usuário não encontrado.')),
      );
      return;
    }
    // Junta características e comentário livre
    String comentarioFinal = _selectedChars.isNotEmpty
        ? _selectedChars.join(", ") // Remove o comentário livre
        : '';
    bool success = await _service.submitOrderReview(
      cpf: cpf,
      idEndereco: widget.idEndereco,
      avaliacao: _rating,
      comentario: comentarioFinal,
      idPedido: widget.orderId, // Corrige para o nome correto do parâmetro
    );
    setState(() => _isSubmitting = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação enviada com sucesso!')),
      );
      // Atualiza a página de pedidos ao voltar
      Navigator.pop(context, true); // Passa true para indicar atualização
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao enviar avaliação.')),
      );
    }
  }

  void _animateStars(int newRating) {
    setState(() => _rating = newRating);
    _starController.reset();
    _starController.forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar Pedido'),
        backgroundColor: Color.fromARGB(255, 251, 188, 44),
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingCard(theme, colorScheme),
            const SizedBox(height: 24),
            _buildCharacteristicsCard(theme, colorScheme),
            const SizedBox(height: 32),
            _buildSubmitButton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avaliação', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Center(
              child: AnimatedBuilder(
                  animation: _starController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        final scaleAnim =
                            Tween<double>(begin: 0.5, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _starController,
                            curve: Interval(
                              index / 5,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          ),
                        );
                        return ScaleTransition(
                          scale: scaleAnim,
                          child: IconButton(
                            iconSize: 40,
                            icon: Icon(
                              Icons.star_rounded,
                              color: _rating >= starIndex
                                  ? Colors.amber
                                  : Colors.grey[300],
                            ),
                            onPressed: () => _animateStars(starIndex),
                            splashColor: Colors.amber.withOpacity(0.2),
                            highlightColor: Colors.transparent,
                          ),
                        );
                      }),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicsCard(ThemeData theme, ColorScheme colorScheme) {
    // Choose options based on rating
    final options = _rating >= 4
        ? _positiveOptions
        : _rating <= 2
            ? _negativeOptions
            : [..._positiveOptions.take(3), ..._negativeOptions.take(3)];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Características', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: options.map((option) {
                  final isSelected = _selectedChars.contains(option);
                  return AnimatedContainer(
                    key: ValueKey(option),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: ChoiceChip(
                      label: Text(option),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected)
                            _selectedChars.add(option);
                          else
                            _selectedChars.remove(option);
                        });
                      },
                      avatar:
                          isSelected ? const Icon(Icons.check, size: 18) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: colorScheme.surface,
                      selectedColor: colorScheme.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.primary
                            : theme.textTheme.bodyMedium?.color,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!_isSubmitting)
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _isSubmitting ? null : _submitReview,
          borderRadius: BorderRadius.circular(12),
          splashColor: colorScheme.primary.withOpacity(0.1),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Color.fromARGB(255, 251, 188, 44),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSubmitting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Enviar Avaliação',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
