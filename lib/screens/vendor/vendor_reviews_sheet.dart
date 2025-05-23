import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VendorReviewsSheet extends StatefulWidget {
  final String idLoja;
  const VendorReviewsSheet({Key? key, required this.idLoja}) : super(key: key);

  @override
  State<VendorReviewsSheet> createState() => _VendorReviewsSheetState();
}

class _VendorReviewsSheetState extends State<VendorReviewsSheet> {
  bool _loading = true;
  List<dynamic> _reviews = [];
  double? _mediaAvaliacoes;
  String? _storeName;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _loading = true);
    final url = 'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetReviewByStore?idLoja=${widget.idLoja}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reviews = data['avaliacoes'] ?? [];
          // Corrige: tenta pegar media_avaliacoes tanto do root quanto de loja
          final media = data['media_avaliacoes'] ?? data['loja']?['media_avaliacoes'];
          if (media is num) {
            _mediaAvaliacoes = media.toDouble();
          } else if (media != null) {
            _mediaAvaliacoes = double.tryParse(media.toString());
          } else {
            _mediaAvaliacoes = null;
          }
          _storeName = data['loja']?['nome_Loja'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar avaliações: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar avaliações: $e')),
      );
    }
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_border_rounded,
        color: Colors.amber,
        size: 22,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rate, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        _storeName ?? 'Avaliações',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Spacer(),
                      if (_mediaAvaliacoes != null)
                        Row(
                          children: [
                            Text(
                              _mediaAvaliacoes!.toStringAsFixed(2),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_reviews.isEmpty)
                    const Center(child: Text('Nenhuma avaliação encontrada.'))
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _reviews.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, idx) {
                          final review = _reviews[idx];
                          final rating = int.tryParse(review['avaliacao']?.toString() ?? '') ?? 0;
                          final comentario = review['comentario']?.toString() ?? '';
                          final cpf = review['fk_Usuario_cpf']?.toString() ?? '';
                          return ListTile(
                            leading: _buildStars(rating),
                            title: Text(comentario.isNotEmpty ? comentario : '(Sem comentário)'),
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
