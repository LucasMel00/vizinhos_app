import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

class VendorReviewsDetailedSheet extends StatefulWidget {
  final String idLoja;
  const VendorReviewsDetailedSheet({Key? key, required this.idLoja}) : super(key: key);

  @override
  State<VendorReviewsDetailedSheet> createState() => _VendorReviewsDetailedSheetState();
}

class _VendorReviewsDetailedSheetState extends State<VendorReviewsDetailedSheet> {
  bool _loading = true;
  List<dynamic> _reviews = [];
  double? _mediaAvaliacoesGeral;
  String? _storeName;

  // Define as categorias esperadas para garantir a ordem e nomes corretos
  final List<String> _expectedCategories = [
    'Qualidade do Produto',
    'Entrega',
    'Atendimento ao Cliente',
    'Custo-Benefício',
    'Experiência de Compra',
  ];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return; // Check if the widget is still in the tree
    setState(() => _loading = true);
    final url = 'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetReviewByStore?idLoja=${widget.idLoja}';
    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reviews = data['avaliacoes'] ?? [];
          final media = data['media_avaliacoes'] ?? data['loja']?['media_avaliacoes'];
          if (media is num) {
            _mediaAvaliacoesGeral = media.toDouble();
          } else if (media != null) {
            _mediaAvaliacoesGeral = double.tryParse(media.toString());
          } else {
            _mediaAvaliacoesGeral = null;
          }
          _storeName = data['loja']?['nome_Loja'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao buscar avaliações: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar avaliações: $e')),
        );
      }
    }
  }

  // Função para construir estrelas para uma dada avaliação
  Widget _buildStars(int rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_border_rounded,
        color: Colors.amber,
        size: size,
      )),
    );
  }

  // Função para parsear o comentário e extrair as avaliações por categoria
  Map<String, int> _parseCategoryRatings(String comment) {
    if (comment.isEmpty) return {};

    Map<String, int> ratings = {};
    // Regex para encontrar "Nome Categoria [Nota]"
    final RegExp regex = RegExp(r'([^,[]+) *\[(\d)\]');
    final matches = regex.allMatches(comment);

    for (final match in matches) {
      if (match.groupCount == 2) {
        final categoryName = match.group(1)?.trim();
        final ratingValue = int.tryParse(match.group(2) ?? '');
        if (categoryName != null && categoryName.isNotEmpty && ratingValue != null) {
          // Encontra a categoria esperada correspondente (case-insensitive)
          final expectedCategory = _expectedCategories.firstWhereOrNull(
            (c) => c.toLowerCase() == categoryName.toLowerCase()
          );
          if (expectedCategory != null) {
             ratings[expectedCategory] = ratingValue;
          }
        }
      }
    }
    return ratings;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : Column(
                mainAxisSize: MainAxisSize.min, // Para BottomSheet
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho com nome da loja e média geral
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  const Divider(),
                  // Lista de avaliações
                  _buildReviewsList(theme),
                ],
              ),
      ),
    );
  }

  // Widget para o cabeçalho
  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.storefront_outlined, color: theme.colorScheme.primary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _storeName ?? 'Avaliações da Loja',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        if (_mediaAvaliacoesGeral != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _mediaAvaliacoesGeral!.toStringAsFixed(1),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              _buildStars(_mediaAvaliacoesGeral!.round(), size: 18),
            ],
          ),
      ],
    );
  }

  // Widget para a lista de avaliações
  Widget _buildReviewsList(ThemeData theme) {
    if (_reviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: Text('Nenhuma avaliação encontrada para esta loja.', textAlign: TextAlign.center),
        ),
      );
    }

    return Flexible( // Permite que a lista ocupe o espaço restante
      child: ListView.separated(
        shrinkWrap: true, // Essencial para Column/BottomSheet
        itemCount: _reviews.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final review = _reviews[idx];
          // Pega a avaliação média enviada pelo cliente
          final overallRating = int.tryParse(review['avaliacao']?.toString() ?? '') ?? 0;
          final comentario = review['comentario']?.toString() ?? '';
          // Parseia o comentário para obter as notas por categoria
          final categoryRatings = _parseCategoryRatings(comentario);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ExpansionTile(
              title: Row(
                children: [
                  Text('Pedido: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(review['id_Pedido']?.substring(0, 6) ?? 'N/A', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Text('(${overallRating.toString()}/5)', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  _buildStars(overallRating, size: 16),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Avaliação Geral do Pedido: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          _buildStars(overallRating, size: 18),
                          const Spacer(),
                          Text('(${overallRating.toString()}/5)', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Data e Hora do Pedido: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            review['data_hora_criacao'] != null
                                ? DateTime.parse(review['data_hora_criacao']).toLocal().toString().substring(0, 16)
                                : 'N/A',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (categoryRatings.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _expectedCategories.map((category) {
                              final rating = categoryRatings[category];
                              if (rating == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '$category:',
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: _buildStars(rating, size: 16),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Text(
                            comentario.isNotEmpty ? 'Comentário: "$comentario"' : '(Sem detalhes por categoria ou comentário adicional)',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

