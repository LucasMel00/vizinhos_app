// screens/restaurant/restaurant_detail_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/cart/cart_screen.dart';
import 'package:vizinhos_app/screens/model/restaurant.dart';
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/model/lote.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/provider/cart_provider.dart';
import 'package:vizinhos_app/screens/provider/favorites_provider.dart';

// Individual review class is no longer needed since we display all reviews directly

// Paleta de cores consistente e acessível
const Color primaryColor = Color(0xFFFbbc2c);
const Color secondaryColor = Color(0xFF3B4351);
const Color backgroundColor = Color(0xFFF5F5F5);
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF333333);
const Color secondaryTextColor = Color(0xFF666666);
const Color successColor = Color(0xFF2E7D32);
const Color accentColor =
    Color(0xFFFF6B6B); // Nova cor de destaque para promoções

class RestaurantDetailPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailPage({Key? key, required this.restaurantId})
      : super(key: key);

  @override
  _RestaurantDetailPageState createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage>
    with SingleTickerProviderStateMixin {
  Future<Restaurant>? futureRestaurant;

  // Filtros
  bool _showPromotionsOnly = false;
  Set<String> _selectedCharacteristics = {};
  Set<String> _availableCharacteristics = {};

  // Animação para filtros
  AnimationController? _animationController;
  Animation<double>? _animation;
  bool _isFilterExpanded = false;

  // Controlador de pesquisa
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    futureRestaurant = _fetchRestaurantDetails(widget.restaurantId);

    // Configuração da animação
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Método para navegar para a tela do carrinho
  void _navigateToCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartScreen()),
    );
  }

  Future<Restaurant> _fetchRestaurantDetails(String idLoja) async {
    final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetStoreInfo?id_loja=$idLoja',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final restaurant = Restaurant.fromJson(jsonResponse);

        // Extrair todas as características disponíveis
        _extractAvailableCharacteristics(restaurant.produtos);

        return restaurant;
      } else {
        throw Exception(
            'Falha ao carregar detalhes da loja (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Falha ao carregar detalhes da loja: $e');
    }
  }

  // Extrair todas as características únicas dos produtos
  void _extractAvailableCharacteristics(List<Product> products) {
    Set<String> characteristics = {};

    for (var product in products) {
      if (product.caracteristicas != null) {
        for (var characteristic in product.caracteristicas!) {
          characteristics.add(characteristic.descricao);
        }
      }
    }

    setState(() {
      _availableCharacteristics = characteristics;
    });
  }

  String _formatCurrency(num? value) {
    if (value == null) return "N/A";
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return format.format(value);
  }

  // Alternar exibição do painel de filtros
  void _toggleFilterPanel() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
      if (_isFilterExpanded) {
        _animationController!.forward();
      } else {
        _animationController!.reverse();
      }
    });
  }

  // Limpar todos os filtros
  void _clearFilters() {
    setState(() {
      _showPromotionsOnly = false;
      _selectedCharacteristics.clear();
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // Verificar se um produto atende aos critérios de filtro
  bool _productMatchesFilters(Product product) {
    // Verificar filtro de promoção
    if (_showPromotionsOnly && !product.flagOferta) {
      return false;
    }

    // Verificar filtro de características
    if (_selectedCharacteristics.isNotEmpty) {
      bool hasSelectedCharacteristic = false;

      if (product.caracteristicas != null) {
        for (var characteristic in product.caracteristicas!) {
          if (_selectedCharacteristics.contains(characteristic.descricao)) {
            hasSelectedCharacteristic = true;
            break;
          }
        }
      }

      if (!hasSelectedCharacteristic) {
        return false;
      }
    }

    // Verificar filtro de pesquisa
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final name = product.nome.toLowerCase();
      final description = product.descricao.toLowerCase();

      if (!name.contains(query) && !description.contains(query)) {
        return false;
      }
    }

    return true;
  }

  // Método para exibir o popup com informações da loja
  void _showStoreInfoDialog(Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com título e botão de fechar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Informações da Loja',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: secondaryTextColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(),
                // Conteúdo do popup
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome da loja + avaliação (visual melhorada)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 0.2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black.withOpacity(0.08),
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 12),
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: FutureBuilder<double>(
                              future: _fetchStoreRating(restaurant.idEndereco),
                              builder: (context, snapshot) {
                                final rating =
                                    snapshot.hasData ? snapshot.data! : 5.0;
                                return InkWell(
                                  onTap: () => _showStoreReviewsModal(
                                      restaurant.idEndereco),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 18,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 4.0,
                                              color: Colors.black
                                                  .withOpacity(0.15),
                                              offset: Offset(0, 1),
                                            ),
                                          ]),                                      SizedBox(width: 4),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[900],
                                          shadows: [
                                            Shadow(
                                              blurRadius: 4.0,
                                              color: Colors.black
                                                  .withOpacity(0.10),
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                                  
                      SizedBox(height: 12),

                      // Descrição da loja
                      Text(
                        'Sobre a loja:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        restaurant.descricao,
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Endereço completo
                      Text(
                        'Endereço:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${restaurant.logradouro}, ${restaurant.numero}${restaurant.complemento.isNotEmpty ? ', ${restaurant.complemento}' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        'CEP: ${restaurant.cep}',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                      // Adiciona telefone da loja
                      if (restaurant.telefone != null &&
                          restaurant.telefone!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 16, color: primaryColor),
                            SizedBox(width: 6),
                            Text(
                              restaurant.telefone ?? '',
                              style: TextStyle(
                                  fontSize: 14, color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 16),

                      // Informações de entrega
                      Text(
                        'Entrega:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        restaurant.tipoEntrega,
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),

                      // Adicione mais informações conforme necessário
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                // Botão de fechar na parte inferior
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Fechar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Função para buscar a nota da loja pela API GetReviewByStore
  Future<double> _fetchStoreRating(String idLoja) async {
    try {
      final url = Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetReviewByStore?idLoja=$idLoja');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final media =
            data['media_avaliacoes'] ?? data['loja']?['media_avaliacoes'];
        final avaliacoes = data['avaliacoes'] ?? data['loja']?['avaliacoes'];
        if (media == null ||
            media == 0 ||
            (avaliacoes is List && avaliacoes.isEmpty)) {
          return 5.0;
        }
        if (media is num) {
          return media.toDouble();
        } else {
          return double.tryParse(media.toString()) ?? 5.0;
        }
      }
      return 5.0;
    } catch (_) {
      return 5.0;
    }
  }
  // Função para buscar avaliações da loja pela API
  Future<List<Map<String, dynamic>>> _fetchStoreReviews(String idLoja) async {
    try {
      final url = Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetReviewByStore?idLoja=$idLoja');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final avaliacoes = data['avaliacoes'] ?? data['loja']?['avaliacoes'];
        if (avaliacoes is List && avaliacoes.isNotEmpty) {
          return List<Map<String, dynamic>>.from(avaliacoes);
        }
      }
      return [];
    } catch (_) {
      return [];    }  }

  // Modal para exibir avaliações da loja
  void _showStoreReviewsModal(String idLoja) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchStoreReviews(idLoja),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final reviews = snapshot.data ?? [];
            
            // Ordenar avaliações por data (mais recente primeiro)
            reviews.sort((a, b) {
              final dateA = a['data_hora_criacao'] ?? a['data'] ?? '';
              final dateB = b['data_hora_criacao'] ?? b['data'] ?? '';
              try {
                final parsedA = DateTime.parse(dateA);
                final parsedB = DateTime.parse(dateB);
                return parsedB.compareTo(parsedA); // Ordem decrescente (mais recente primeiro)
              } catch (e) {
                return 0; // Se não conseguir fazer parse, mantém ordem atual
              }
            });
            
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Avaliações da Loja',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  if (reviews.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${reviews.length} avaliação${reviews.length == 1 ? '' : 'ões'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  Divider(),
                  if (reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          'Ainda não há nenhuma avaliação para esta loja.',
                          style: TextStyle(
                              fontSize: 16, color: secondaryTextColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => Divider(height: 24),                        itemBuilder: (context, idx) {
                          final review = reviews[idx];
                          final usuario = review['usuario'] ?? 'Usuário Anônimo';
                          final avaliacaoRaw = review['avaliacao'] ?? 5;
                          double nota;
                          if (avaliacaoRaw is num) {
                            nota = avaliacaoRaw.toDouble();
                          } else {
                            nota = double.tryParse(avaliacaoRaw.toString()) ?? 5.0;
                          }
                          final dataStr = review['data_hora_criacao'] ?? review['data'] ?? '';
                          
                          String dataFormatada = 'Data não informada';
                          if (dataStr.isNotEmpty) {
                            try {
                              final dataObj = DateTime.parse(dataStr);
                              dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(dataObj);
                            } catch (e) {
                              // Se não conseguir fazer parse da data, tenta extrair apenas a data
                              if (dataStr.contains('T')) {
                                final datePart = dataStr.split('T')[0];
                                try {
                                  final dateObj = DateTime.parse(datePart);
                                  dataFormatada = DateFormat('dd/MM/yyyy').format(dateObj);
                                } catch (e) {
                                  dataFormatada = datePart;
                                }
                              } else {
                                dataFormatada = dataStr;
                              }
                            }
                          }
                          
                          return Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.amber[700],
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12),                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            usuario,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 4),                                          Row(
                                            children: [
                                              ...List.generate(5, (starIndex) {
                                                double starValue = starIndex + 1.0;
                                                if (nota >= starValue) {
                                                  // Estrela cheia
                                                  return Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 18,
                                                  );
                                                } else if (nota >= starValue - 0.5) {
                                                  // Meia estrela
                                                  return Icon(
                                                    Icons.star_half,
                                                    color: Colors.amber,
                                                    size: 18,
                                                  );
                                                } else {
                                                  // Estrela vazia
                                                  return Icon(
                                                    Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 18,
                                                  );
                                                }
                                              }),
                                              SizedBox(width: 8),
                                              Text(
                                                '${nota.toStringAsFixed(1)}/5',
                                                style: TextStyle(
                                                  color: Colors.amber[900],
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.grey[500],
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      dataFormatada,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<Restaurant>(
        future: futureRestaurant,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          } else if (snapshot.hasData) {
            final restaurant = snapshot.data!;
            final storeImageUrl = restaurant.imagemUrl;            // Filtrar produtos disponíveis
            final availableProducts =
                restaurant.produtos.where((p) => p.disponivel == true).toList();

            // Aplicar filtros adicionais
            final filteredProducts =
                availableProducts.where(_productMatchesFilters).toList();

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: primaryColor,
                      expandedHeight: 220.0,
                      floating: false,
                      pinned: true,
                      elevation: 2,
                      iconTheme: IconThemeData(color: Colors.white),
                      // Aumentar espaçamento entre botão voltar e título
                      leadingWidth: 56, // Aumentado para dar mais espaço
                      actions: [
                        // Botão de favorito na AppBar
                        
                        // Botão do carrinho na AppBar
                        Consumer<CartProvider>(
                          builder: (ctx, cart, child) {
                            final itemCount = cart.itemCount;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.shopping_cart),
                                  onPressed: itemCount > 0
                                      ? () => _navigateToCart(context)
                                      : null,
                                ),
                                if (itemCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '$itemCount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        SizedBox(width: 8),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        // Ajustar o padding do título para afastar do botão voltar
                        titlePadding: EdgeInsetsDirectional.only(
                            start:
                                56.0, // Aumentado para afastar do botão voltar
                            bottom: 16.0),
                        title: Align(
                          alignment: Alignment.bottomLeft,
                          child: Stack(
                            children: [
                              // Título da loja com avaliação ao lado
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      restaurant.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 4.0,
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  FutureBuilder<double>(
                                    future: _fetchStoreRating(
                                        restaurant.idEndereco),
                                    builder: (context, snapshot) {
                                      final rating = snapshot.hasData
                                          ? snapshot.data!
                                          : 5.0;
                                      return InkWell(
                                        onTap: () => _showStoreReviewsModal(
                                            restaurant.idEndereco),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              color: Colors.amber,
                                              size: 18,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 4.0,
                                                  color: Colors.black
                                                      .withOpacity(0.15),
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              rating.toStringAsFixed(2),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Imagem de fundo da loja
                            storeImageUrl != null && storeImageUrl.isNotEmpty
                                ? Image.network(
                                    storeImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildDefaultStoreImage();
                                    },
                                  )
                                : _buildDefaultStoreImage(),
                            // Gradiente para melhorar a legibilidade do texto
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  stops: [0.6, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título da seção com ícone de informações
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Informações da Loja',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Ícone de informações clicável
                                    InkWell(
                                      onTap: () => _showStoreInfoDialog(restaurant),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.info_outline,
                                          size: 18,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Ícone de favorito
                                    Consumer<FavoritesProvider>(
                                      builder: (ctx, favs, child) {
                                        final isFav = favs.isFavorite(restaurant.idEndereco);
                                        return GestureDetector(
                                          onTap: () => favs.toggleFavorite(restaurant),
                                          child: Icon(
                                            isFav ? Icons.favorite : Icons.favorite_border,
                                            size: 20,
                                            color: isFav ? Colors.red : primaryColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              restaurant.descricao,
                              style: const TextStyle(
                                  fontSize: 15, color: secondaryTextColor),
                            ),
                            const SizedBox(height: 16),
                            if (restaurant.telefone != null &&
                                restaurant.telefone!.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.phone,
                                      size: 16, color: primaryColor),
                                  SizedBox(width: 6),
                                  Text(
                                    restaurant.telefone ?? '',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: secondaryTextColor),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                            ],
                            _buildInfoRow(Icons.local_shipping_outlined,
                                'Entrega: ${restaurant.tipoEntrega}'),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Barra de pesquisa e filtros
                          _buildSearchAndFilterBar(availableProducts),

                          // Painel de filtros expansível
                          SizeTransition(
                            sizeFactor: _animation!,
                            child: _buildFilterPanel(),
                          ),

                          // Contador de produtos e indicador de filtros ativos
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Produtos (${filteredProducts.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                                if (_showPromotionsOnly ||
                                    _selectedCharacteristics.isNotEmpty ||
                                    _searchQuery.isNotEmpty)
                                  TextButton.icon(
                                    icon: Icon(Icons.filter_list_off, size: 16),
                                    label: Text('Limpar filtros'),
                                    onPressed: _clearFilters,
                                    style: TextButton.styleFrom(
                                      foregroundColor: secondaryColor,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 0),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Lista de produtos filtrados
                          filteredProducts.isEmpty
                              ? _buildEmptyProductsMessage()
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
                                    return AnimatedOpacity(
                                      duration: Duration(
                                          milliseconds: 300 + (index * 50)),
                                      opacity: 1.0,
                                      child:
                                          _buildProductCard(context, product),
                                    );
                                  },
                                ),

                          // Espaço extra após a lista de produtos para permitir rolagem adicional
                          SizedBox(
                              height:
                                  120), // Aumentado para dar mais espaço para rolagem
                        ],
                      ),
                    ),
                  ],
                ),

                // Botão flutuante do carrinho - Posicionado mais acima para evitar sobreposição
                Consumer<CartProvider>(
                  builder: (ctx, cart, child) {
                    final itemCount = cart.itemCount;
                    final totalAmount = cart.totalAmount;

                    if (itemCount <= 0) return SizedBox.shrink();

                    return Positioned(
                      bottom:
                          24, // Aumentado para ficar mais distante do final da tela
                      left: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _navigateToCart(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14), // Aumentado para dar mais espaço
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$itemCount',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ver carrinho',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                _formatCurrency(totalAmount),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          } else {
            return _buildErrorState(
                Exception("Nenhuma informação da loja encontrada."));
          }
        },
      ),
    );
  }

  // Widget para mensagem de nenhum produto encontrado
  Widget _buildEmptyProductsMessage() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Nenhum produto encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Tente ajustar seus filtros ou critérios de busca',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Limpar filtros'),
            onPressed: _clearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Barra de pesquisa e botão de filtro
  Widget _buildSearchAndFilterBar(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar produtos...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isFilterExpanded ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.filter_list,
                    color: _isFilterExpanded ? Colors.white : primaryColor,
                  ),
                  if (_showPromotionsOnly ||
                      _selectedCharacteristics.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _toggleFilterPanel,
            ),
          ),
        ],
      ),
    );
  }

  // Painel de filtros expansível
  Widget _buildFilterPanel() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título do painel de filtros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text('Limpar todos'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          Divider(),

          // Filtro de promoções
          SwitchListTile(
            title: Text(
              'Apenas promoções',
              style: TextStyle(
                fontSize: 14,
                color: primaryTextColor,
              ),
            ),
            value: _showPromotionsOnly,
            onChanged: (value) {
              setState(() {
                _showPromotionsOnly = value;
              });
            },
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity(horizontal: -4, vertical: -4),
          ),

          // Filtro de características
          if (_availableCharacteristics.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Características',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _availableCharacteristics.map((characteristic) {
                final isSelected =
                    _selectedCharacteristics.contains(characteristic);
                return FilterChip(
                  label: Text(
                    characteristic,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? primaryColor : secondaryTextColor,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCharacteristics.add(characteristic);
                      } else {
                        _selectedCharacteristics.remove(characteristic);
                      }
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: primaryColor.withOpacity(0.1),
                  checkmarkColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.grey[300]!,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity(horizontal: -2, vertical: -2),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Estado de carregamento
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.5),
          highlightColor: Colors.white,
          child: Container(
            width: 200,
            height: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem de capa
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Descrição
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 16,
                        width: MediaQuery.of(context).size.width * 0.7,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Informações
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 16,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (context, index) =>
                          _buildProductCardSkeleton(),
                    ),
                  ])
            ),
          ],
        ),
      ),
    );
  }

          
  // Estado de erro
  Widget _buildErrorState(Object? error) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Erro"),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 50),
              SizedBox(height: 16),
              Text(
                "Ocorreu um erro ao carregar os detalhes da loja.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: primaryTextColor),
              ),
              SizedBox(height: 8),
              Text(
                "$error",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text("Tentar Novamente"),
                onPressed: () {
                  setState(() {
                    futureRestaurant =
                        _fetchRestaurantDetails(widget.restaurantId);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Linha de informação com ícone
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 14, color: secondaryTextColor))),
        ],
      ),
    );
  }

  // Imagem padrão da loja
  Widget _buildDefaultStoreImage() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(Icons.storefront, size: 80, color: Colors.grey[500]),
      ),
    );
  }

  // Imagem padrão do produto
  Widget _buildDefaultProductImage({double height = 64, double width = 64}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined,
            size: 30, color: Colors.grey[400]),
      ),
    );
  }
  // Card de produto com botão de adicionar ao carrinho
  Widget _buildProductCard(BuildContext context, Product product) {
    final productImageUrl = product.imagemUrl;
    final String formattedPrice = _formatCurrency(product.valorVenda);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem do produto
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: productImageUrl != null &&
                              productImageUrl.isNotEmpty
                          ? Image.network(
                              productImageUrl,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultProductImage(
                                    height: 80, width: 80);
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      strokeWidth: 2,
                                      color: primaryColor,
                                    ),
                                  ),
                                );
                              },
                            )
                          : _buildDefaultProductImage(height: 80, width: 80),
                    ),
                    if (product.flagOferta)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            'OFERTA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Nome, preço, descrição
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.nome,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(formattedPrice,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: product.flagOferta
                                      ? accentColor
                                      : successColor,
                                  fontWeight: FontWeight.w600)),
                          if (product.flagOferta)
                            Row(
                              children: [
                                SizedBox(width: 6),
                                Icon(
                                  Icons.local_offer,
                                  size: 14,
                                  color: accentColor,
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(product.descricao,
                          style: TextStyle(
                              fontSize: 12, color: secondaryTextColor)),
                    ],
                  ),
                ),
              ],
            ),

            // Características
            if (product.caracteristicas != null &&
                product.caracteristicas!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: product.caracteristicas!
                      .map((char) => Chip(
                            label: Text(char.descricao,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: _selectedCharacteristics
                                            .contains(char.descricao)
                                        ? primaryColor
                                        : secondaryTextColor)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.0, vertical: 0),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity:
                                VisualDensity(horizontal: 0.0, vertical: -4),
                            backgroundColor: _selectedCharacteristics
                                    .contains(char.descricao)
                                ? primaryColor.withOpacity(0.1)
                                : backgroundColor,
                            side: BorderSide(
                              color: _selectedCharacteristics
                                      .contains(char.descricao)
                                  ? primaryColor
                                  : Colors.grey[300]!,
                            ),
                          ))
                      .toList(),
                ),
              ),

            // Indicador de Promoção
            if (product.flagOferta)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer, size: 16, color: accentColor),
                      SizedBox(width: 4),
                      Text(
                        "Está em promoção",
                        style: TextStyle(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Lote
            if (product.lote != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Builder(
                  builder: (context) {
                    Lote? lote;
                    if (product.lote is String) {
                      try {
                        lote = Lote.fromJson(json.decode(product.lote!));
                      } catch (e) {
                        lote = null;
                      }
                    } else if (product.lote is Lote) {
                      lote = product.lote as Lote?;
                    } else if (product.lote is Map<String, dynamic>) {
                      lote =
                          Lote.fromJson(product.lote as Map<String, dynamic>);
                    }
                    if (lote != null) {
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 14, color: secondaryTextColor),
                            SizedBox(width: 4),
                            Text(
                              "Disponível: ${lote.quantidade}",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            // Botão de adicionar ao carrinho - Aumentado o espaçamento antes do botão
            const SizedBox(height: 16), // Aumentado para dar mais espaço
            _AddToCartButton(
              product: product,
              onProductAdded: () {},
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton do card de produto
  Widget _buildProductCardSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 120, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 180, color: Colors.white),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        height: 24,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        height: 24,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para o botão de adicionar ao carrinho com a nova lógica
class _AddToCartButton extends StatefulWidget {
  final Product product;
  final VoidCallback onProductAdded;

  const _AddToCartButton({
    Key? key,
    required this.product,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  _AddToCartButtonState createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final int quantity = cartProvider.items[widget.product.id]?.quantity ?? 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quantity > 0 ? primaryColor : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Botão de remover (apenas se já tiver itens no carrinho)
          if (quantity > 0)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  cartProvider.removeSingleItem(widget.product.id);
                },
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),

          // Contador (apenas se já tiver itens no carrinho)
          if (quantity > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$quantity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
            ),

          // Botão de adicionar com a nova lógica
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Use a nova lógica de verificação
                  final result = cartProvider.checkItemStore(widget.product);

                  switch (result) {
                    case AddItemResult.success:
                      // Adiciona o produto normalmente
                      cartProvider.addItem(widget.product);
                      widget.onProductAdded();

                      break;

                    case AddItemResult.differentStore:
                      // Mostra diálogo de confirmação
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Produtos de lojas diferentes'),
                          content: Text(
                              'Você já tem produtos de outra loja no carrinho. '
                              'O que deseja fazer?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                              child: Text(
                                'Manter carrinho atual',
                                style: TextStyle(color: primaryColor),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Limpa o carrinho e adiciona o novo produto
                                cartProvider
                                    .addItemFromDifferentStore(widget.product);
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Carrinho atualizado com o novo produto')),
                                );
                                widget.onProductAdded();
                              },
                              child: Text(
                                'Limpar e adicionar novo produto',
                                style: TextStyle(color: primaryColor),
                              ),
                            ),
                          ],
                        ),
                      );
                      break;

                    case AddItemResult.unavailable:
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Produto indisponível')),
                      );
                      break;
                  }
                },
                borderRadius: quantity > 0
                    ? BorderRadius.only(
                        topRight: Radius.circular(11),
                        bottomRight: Radius.circular(11),
                      )
                    : BorderRadius.circular(11),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: quantity > 0 ? Colors.transparent : primaryColor,
                    borderRadius: quantity > 0
                        ? BorderRadius.only(
                            topRight: Radius.circular(11),
                            bottomRight: Radius.circular(11),
                          )
                        : BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: quantity > 0
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Adicionar',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Adicionar ao carrinho',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
