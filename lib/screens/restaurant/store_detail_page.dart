// screens/restaurant/restaurant_detail_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/model/cart_item.dart';
import 'package:vizinhos_app/screens/model/restaurant.dart';
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/model/characteristic.dart';
import 'package:vizinhos_app/screens/model/lote.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/provider/cart_provider.dart';

// Paleta de cores consistente e acessível
const Color primaryColor = Color(0xFFFbbc2c);
const Color secondaryColor = Color(0xFF3B4351);
const Color backgroundColor = Color(0xFFF5F5F5);
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF333333);
const Color secondaryTextColor = Color(0xFF666666);
const Color successColor = Color(0xFF2E7D32);

class RestaurantDetailPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailPage({Key? key, required this.restaurantId}) : super(key: key);

  @override
  _RestaurantDetailPageState createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  Future<Restaurant>? futureRestaurant;

  @override
  void initState() {
    super.initState();
    futureRestaurant = _fetchRestaurantDetails(widget.restaurantId);
  }

  Future<Restaurant> _fetchRestaurantDetails(String idLoja) async {
    final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetStoreInfo?id_loja=$idLoja',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return Restaurant.fromJson(jsonResponse);
      } else {
        throw Exception('Falha ao carregar detalhes da loja (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Falha ao carregar detalhes da loja: $e');
    }
  }

  String _formatCurrency(num? value) {
    if (value == null) return "N/A";
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return format.format(value);
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
            final storeImageUrl = restaurant.imagemUrl;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: primaryColor,
                  expandedHeight: 220.0,
                  floating: false,
                  pinned: true,
                  elevation: 2,
                  iconTheme: IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsetsDirectional.only(start: 16.0, bottom: 16.0),
                    title: Align(
                      alignment: Alignment.bottomLeft,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                              child: Container(),
                            ),
                          ),
                          Text(
                            restaurant.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    centerTitle: true,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        storeImageUrl != null && storeImageUrl.isNotEmpty
                            ? Image.network(
                                storeImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultStoreImage(),
                              )
                            : _buildDefaultStoreImage(),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(0.0, 0.6),
                              end: Alignment(0.0, 0.0),
                              colors: <Color>[
                                Color(0x60000000),
                                Color(0x00000000),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    // Detalhes da loja
                    Container(
                      color: cardBackgroundColor,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.descricao,
                            style: const TextStyle(fontSize: 15, color: secondaryTextColor),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.location_on_outlined,
                              '${restaurant.logradouro}, ${restaurant.numero}'),
                          if (restaurant.complemento.isNotEmpty)
                            _buildInfoRow(Icons.home_work_outlined, restaurant.complemento),
                          _buildInfoRow(
                              Icons.local_shipping_outlined, 'Entrega: ${restaurant.tipoEntrega}'),
                          _buildInfoRow(Icons.mail_outline_rounded, 'CEP: ${restaurant.cep}'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    // Seção de produtos
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Produtos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(builder: (context) {
                      final availableProducts = restaurant.produtos
                          .where((p) => p.disponivel ?? true)
                          .toList();
                      return availableProducts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 40.0),
                              child: Center(
                                  child: Text(
                                'Nenhum produto disponível nesta loja.',
                                style: TextStyle(color: secondaryTextColor),
                              )),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: availableProducts.length,
                              itemBuilder: (context, index) {
                                final product = availableProducts[index];
                                return AnimatedOpacity(
                                  duration: Duration(milliseconds: 300 + (index * 50)),
                                  opacity: 1.0,
                                  child: _buildProductCard(context, product),
                                );
                              },
                            );
                    }),
                    const SizedBox(height: 20),
                  ]),
                ),
              ],
            );
          } else {
            return _buildErrorState(Exception("Nenhuma informação da loja encontrada."));
          }
        },
      ),
    );
  }

  // Estado de carregamento com shimmer
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.grey[400],
              expandedHeight: 220.0,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(color: Colors.grey[400]),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  color: cardBackgroundColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 15, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 15, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 16),
                      Container(height: 14, width: 200, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 150, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 180, color: Colors.white),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(height: 18, width: 100, color: Colors.white),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildProductCardSkeleton(),
                ),
              ]),
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
                    futureRestaurant = _fetchRestaurantDetails(widget.restaurantId);
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
                  style: const TextStyle(fontSize: 14, color: secondaryTextColor))),
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
        child: Icon(Icons.image_not_supported_outlined, size: 30, color: Colors.grey[400]),
      ),
    );
  }

  // Card de produto com botão de adicionar ao carrinho
  Widget _buildProductCard(BuildContext context, Product product) {
    final cartProvider = Provider.of<CartProvider>(context);
    final productImageUrl = product.imagemUrl;
    final String formattedPrice = _formatCurrency(product.valorVenda);
    final int inCart = cartProvider.items[product.id]?.quantity ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: productImageUrl != null && productImageUrl.isNotEmpty
                      ? Image.network(
                          productImageUrl,
                          height: 64,
                          width: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultProductImage(height: 64, width: 64);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 64,
                              width: 64,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              ),
                            );
                          },
                        )
                      : _buildDefaultProductImage(height: 64, width: 64),
                ),
                const SizedBox(width: 12),
                // Nome, preço, descrição
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.nome,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: primaryTextColor)),
                      const SizedBox(height: 4),
                      Text(formattedPrice,
                          style: TextStyle(
                              fontSize: 14, color: successColor, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(product.descricao,
                          style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                    ],
                  ),
                ),
              ],
            ),
            // Características
            if (product.caracteristicas != null && product.caracteristicas!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: product.caracteristicas!
                      .map((char) => Chip(
                            label: Text(char.descricao,
                                style: const TextStyle(fontSize: 10, color: secondaryTextColor)),
                            padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity(horizontal: 0.0, vertical: -4),
                            backgroundColor: backgroundColor,
                            side: BorderSide(color: Colors.grey[300]!),
                          ))
                      .toList(),
                ),
              ),
            // Lote
            if (product.id_lote != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Builder(
                  builder: (context) {
                    Lote? lote;
                    if (product.id_lote is String) {
                      try {
                        lote = Lote.fromJson(json.decode(product.id_lote!));
                      } catch (e) {
                        lote = null;
                      }
                    } else if (product.id_lote is Lote) {
                      lote = product.id_lote as Lote?;
                    } else if (product.id_lote is Map<String, dynamic>) {
                      lote = Lote.fromJson(product.id_lote as Map<String, dynamic>);
                    }
                    if (lote != null) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Disponível: ${lote.quantidade}",
                          style: TextStyle(fontSize: 11, color: secondaryTextColor, fontWeight: FontWeight.w500),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            // Botão de adicionar ao carrinho
            const SizedBox(height: 12),
            _AddToCartButton(product: product),
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 15, width: 120, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 180, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Botão de adicionar ao carrinho
class _AddToCartButton extends StatefulWidget {
  final Product product;
  const _AddToCartButton({Key? key, required this.product}) : super(key: key);

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  bool _loading = false;
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final availableToAdd = cartProvider.getAvailableToAdd(widget.product, cartProvider.items);
    final inCart = cartProvider.items[widget.product.id]?.quantity ?? 0;

    // Determine o texto do botão baseado no estado atual
    String buttonText;
    if (availableToAdd <= 0 && inCart == 0) {
      buttonText = "Esgotado";
    } else if (availableToAdd <= 0) {
      buttonText = "Máx. no carrinho";
    } else if (_added) {
      buttonText = "Adicionado!";
    } else if (inCart > 0) {
      buttonText = "Add mais ($inCart no carrinho)";
    } else {
      buttonText = "Adicionar ao carrinho";
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : (_added
                ? Icon(Icons.check, color: Colors.white)
                : Icon(Icons.add_shopping_cart, color: Colors.white)),
        label: Text(
          buttonText,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: availableToAdd <= 0 ? Colors.grey : primaryColor,
          foregroundColor: Colors.white,
          minimumSize: Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: (availableToAdd <= 0 || _loading || _added)
            ? null
            : () async {
                setState(() {
                  _loading = true;
                });
                await Future.delayed(Duration(milliseconds: 300));
                cartProvider.addItem(widget.product);
                setState(() {
                  _loading = false;
                  _added = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.product.nome} adicionado ao carrinho!'),
                    duration: Duration(seconds: 1),
                  ),
                );
                await Future.delayed(Duration(milliseconds: 800));
                if (mounted) {
                  setState(() {
                    _added = false;
                  });
                }
              },
      ),
    );
  }
}
