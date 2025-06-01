import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// --- Real OrdersService Implementation (integrado do código do usuário) ---
class OrdersService {
  final String baseUrl = 'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com';

  // getOrdersByUser e updateOrderStatus não são diretamente usados nesta página,
  // mas mantidos aqui para referência se o serviço for compartilhado.

  // Future<OrdersResponse> getOrdersByUser(String cpf) async { ... }
  // Future<bool> updateOrderStatus(String idPedido) async { ... }

  /// Envia avaliação para a API CreateReview (adaptado para receber média e comentário concatenado)
  Future<bool> submitOrderReview({
    required String cpf,
    required int idEndereco,
    required int avaliacao, // Agora recebe a média arredondada
    required String idPedido,
    required String comentario // Agora recebe as categorias concatenadas
  }) async {
    try {
      final url = Uri.parse('$baseUrl/CreateReview');
      final body = jsonEncode({
        "fk_Usuario_cpf": cpf,
        "fk_id_Endereco": idEndereco,
        "avaliacao": avaliacao, // Envia a média
        "comentario": comentario, // Envia o comentário concatenado
        "id_Pedido": idPedido,
      });
      print('CreateReview -> POST $url');
      print('Request body: $body');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      print('Response -> statusCode: ${response.statusCode}, body: ${response.body}');
      // Considera 200 ou 201 como sucesso conforme o código original do serviço
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Erro ao enviar avaliação: $e');
      return false;
    }
  }
}
// --- Fim OrdersService ---

class OrderReviewCategoriesPage extends StatefulWidget {
  final String orderId;
  final int idEndereco;

  const OrderReviewCategoriesPage({
    Key? key,
    required this.orderId,
    required this.idEndereco,
  }) : super(key: key);

  @override
  _OrderReviewCategoriesPageState createState() =>
      _OrderReviewCategoriesPageState();
}

class _OrderReviewCategoriesPageState extends State<OrderReviewCategoriesPage> {
  // Usa a implementação real do OrdersService
  final OrdersService _service = OrdersService();
  bool _isSubmitting = false;

  // Define categories
  final List<String> _categories = [
    'Qualidade do Produto',
    'Entrega',
    'Atendimento ao Cliente',
    'Custo-Benefício',
    'Experiência de Compra',
  ];

  // Armazena as avaliações para cada categoria
  late Map<String, int> _categoryRatings;

  @override
  void initState() {
    super.initState();
    // Inicializa as avaliações (0 indica não avaliado)
    _categoryRatings = {for (var category in _categories) category: 0};
  }

  // Função para obter o comentário descritivo baseado na nota (1-5)
  String _getCommentForRating(int rating) {
    switch (rating) {
      case 1: return 'Muito Ruim';
      case 2: return 'Ruim';
      case 3: return 'Regular';
      case 4: return 'Bom';
      case 5: return 'Muito Bom';
      default: return 'Avalie esta categoria'; // Mensagem padrão
    }
  }

  // Função para submeter a avaliação
  void _submitReview() async {
    // Verifica se todas as categorias foram avaliadas
    if (_categoryRatings.containsValue(0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, avalie todas as categorias.')),
      );
      return;
    }

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

    // --- Lógica de Cálculo da Média e Concatenação do Comentário ---
    double sum = 0;
    List<String> commentsList = [];
    _categoryRatings.forEach((category, rating) {
      sum += rating;
      commentsList.add('$category [$rating]');
    });

    int averageRating = (sum / _categories.length).round();
    String concatenatedComment = commentsList.join(', '); // Junta com vírgula e espaço
    // --- Fim da Lógica ---

    // Chama o serviço real com os dados processados
    bool success = await _service.submitOrderReview(
      cpf: cpf,
      idEndereco: widget.idEndereco,
      avaliacao: averageRating, // Envia a média arredondada
      comentario: concatenatedComment, // Envia o comentário concatenado
      idPedido: widget.orderId,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação enviada com sucesso!')),
      );
      Navigator.pop(context, true); // Indica sucesso/atualização necessária
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao enviar avaliação.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar Pedido'),
        backgroundColor: const Color.fromARGB(255, 251, 188, 44),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cria um card para cada categoria
            ..._categories.map((category) => _buildCategoryRatingCard(category, theme, colorScheme)).toList(),
            const SizedBox(height: 32),
            _buildSubmitButton(colorScheme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Widget para construir o card de avaliação de uma categoria
  Widget _buildCategoryRatingCard(String category, ThemeData theme, ColorScheme colorScheme) {
    int currentRating = _categoryRatings[category] ?? 0;
    String currentComment = _getCommentForRating(currentRating);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  iconSize: 36,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    currentRating >= starIndex ? Icons.star_rounded : Icons.star_border_rounded,
                    color: currentRating >= starIndex ? Colors.amber : Colors.grey[400],
                  ),
                  onPressed: () {
                    setState(() {
                      _categoryRatings[category] = starIndex;
                    });
                  },
                  splashRadius: 24,
                  splashColor: Colors.amber.withOpacity(0.2),
                  highlightColor: Colors.transparent,
                );
              }),
            ),
            const SizedBox(height: 8),
            // Exibe o comentário automático (Muito Bom, Bom, etc.)
            Center(
              child: Text(
                currentComment,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: currentRating > 0 ? Colors.black87 : Colors.grey,
                  fontStyle: currentRating > 0 ? FontStyle.normal : FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para o botão de envio
  Widget _buildSubmitButton(ColorScheme colorScheme) {
    // Reutiliza o estilo do botão do código original
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!_isSubmitting)
            BoxShadow(
              color: const Color.fromARGB(255, 251, 188, 44).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submitReview,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color.fromARGB(255, 251, 188, 44),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _isSubmitting
                  ? const SizedBox(
                      key: ValueKey('loader'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      key: ValueKey('text'),
                      'Enviar Avaliação',
                      style: TextStyle(
                        color: Colors.white,
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

