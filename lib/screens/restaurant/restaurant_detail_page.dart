// screens/restaurant/restaurant_detail_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/model/restaurant.dart';
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/model/characteristic.dart';
import 'package:vizinhos_app/screens/model/lote.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer

// Define colors for consistency (matching home_page_user.dart)
const Color primaryColor = Color(0xFFFbbc2c);
const Color secondaryColor = Color(0xFF3B4351);
const Color backgroundColor = Color(0xFFF5F5F5); // Light grey background
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF333333);
const Color secondaryTextColor = Color(0xFF666666); // Slightly darker grey
const Color successColor = Color(0xFF2E7D32); // Green for price

class RestaurantDetailPage extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailPage({Key? key, required this.restaurantId})
      : super(key: key);

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
      // Simulate network delay for testing loading state
      // await Future.delayed(Duration(seconds: 2)); 
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return Restaurant.fromJson(jsonResponse);
      } else {
        print('Erro HTTP ao buscar detalhes da loja: ${response.statusCode}');
        throw Exception('Falha ao carregar detalhes da loja (HTTP ${response.statusCode})');
      }
    } catch (e) {
      print('[ERRO] _fetchRestaurantDetails: $e');
      throw Exception('Falha ao carregar detalhes da loja: $e');
    }
  }

  String _formatCurrency(num? value) {
    if (value == null) return "N/A"; // Handle null value
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return format.format(value);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Apply background color
      body: FutureBuilder<Restaurant>(
        future: futureRestaurant,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(); // Show shimmer loading state
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          } else if (snapshot.hasData) {
            final restaurant = snapshot.data!;
            final storeImageUrl = restaurant.imagemUrl;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  // title: Text(restaurant.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  backgroundColor: primaryColor,
                  expandedHeight: 220.0, // Slightly taller header
                  floating: false,
                  pinned: true,
                  elevation: 2,
                  iconTheme: IconThemeData(color: Colors.white), // Back button color
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      restaurant.name,
                      style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w600),
                    ),
                    centerTitle: true, // Center title when collapsed
                    // titlePadding: EdgeInsetsDirectional.only(start: 72, bottom: 16), // Removed padding for true centering
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
                        // Add a subtle gradient overlay for better title visibility
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(0.0, 0.6),
                              end: Alignment(0.0, 0.0),
                              colors: <Color>[
                                Color(0x60000000), // Semi-transparent black at bottom
                                Color(0x00000000), // Transparent at top
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
                    // Restaurant Details Section
                    Container(
                      color: cardBackgroundColor, // White background for details section
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(restaurant.descricao,
                              style: const TextStyle(fontSize: 15, color: secondaryTextColor)),
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
                    // Divider moved outside the white container
                    // const Divider(height: 1, thickness: 1, color: Colors.grey[300]),
                    SizedBox(height: 12), // Space between sections

                    // Products Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Produtos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryTextColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filter active products
                    Builder(builder: (context) {
                      final availableProducts = restaurant.produtos.where((p) => p.disponivel ?? true).toList(); // Filter available products (disponivel == true or null)                      // Display Products List or 'No products' message
                      return availableProducts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 40.0), // More vertical padding
                              child: Center(
                                  child: Text('Nenhum produto disponível nesta loja.', style: TextStyle(color: secondaryTextColor))),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero, // Remove default padding
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: availableProducts.length,
                              itemBuilder: (context, index) {
                                final product = availableProducts[index];
                                // Add animation to product cards
                                return AnimatedOpacity(
                                  duration: Duration(milliseconds: 300 + (index * 50)), // Staggered fade-in
                                  opacity: 1.0, // Assuming initial opacity is 1.0
                                  child: _buildProductCard(context, product),
                                );
                              },
                            );
                    }),
                    const SizedBox(height: 20), // Add some space at the bottom
                  ]),
                ),
              ],
            );
          } else {
            // Should not happen if future is initialized correctly
            return _buildErrorState(Exception("Nenhuma informação da loja encontrada."));
          }
        },
      ),
    );
  }

  // Loading State Widget with Shimmer
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.grey[400], // Placeholder color
              expandedHeight: 220.0,
              pinned: true,
              automaticallyImplyLeading: false, // Hide back button during load
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
                // Skeleton for product cards
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

  // Error State Widget
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

  // Helper widget for info rows
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Increased vertical padding
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor), // Use primary color for icons
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: secondaryTextColor))),
        ],
      ),
    );
  }

  // Helper widget for default store image
  Widget _buildDefaultStoreImage() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(Icons.storefront, size: 80, color: Colors.grey[500]),
      ),
    );
    // return Image.asset(
    //   "assets/images/default_restaurant_image.jpg", // Ensure this asset exists
    //   width: double.infinity,
    //   height: 200,
    //   fit: BoxFit.cover,
    // );
  }

  // Helper widget for default product image
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
    // return Image.asset(
    //   "assets/images/default_product_image.png", // Create or use a default product image
    //   height: height,
    //   width: width,
    //   fit: BoxFit.cover,
    // );
  }

  // Widget to build each product card
  Widget _buildProductCard(BuildContext context, Product product) {
    final productImageUrl = product.imagemUrl;

    // Directly format the currency using the updated function
    final String formattedPrice = _formatCurrency(product.valorVenda);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1.5, // Softer elevation
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Slightly less rounded
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: productImageUrl != null && productImageUrl.isNotEmpty
                      ? Image.network(
                          productImageUrl,
                          height: 64, // Smaller product image
                          width: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print("Error loading product image: $productImageUrl, Error: $error");
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
                // Product Name, Price, Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryTextColor)),
                      const SizedBox(height: 4),
                      Text(formattedPrice, style: TextStyle(fontSize: 14, color: successColor, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(product.descricao, style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                    ],
                  ),
                ),
              ],
            ),
            // Characteristics - Improved styling
            if (product.caracteristicas != null && product.caracteristicas!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: product.caracteristicas!
                      .map((char) => Chip(
                            label: Text(char.descricao, style: const TextStyle(fontSize: 10, color: secondaryTextColor)),
                            padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity(horizontal: 0.0, vertical: -4), // Compact chip
                            backgroundColor: backgroundColor, // Use light background color
                            side: BorderSide(color: Colors.grey[300]!), // Subtle border
                          ))
                      .toList(),
                ),
              ),
            // Lote Info - Corrected display
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
                        print("Error decoding lote JSON: $e");
                        lote = null;
                      }
                    } else if (product.lote is Lote) {
                      lote = product.lote as Lote?;
                    } else if (product.lote is Map<String, dynamic>) {
                       lote = Lote.fromJson(product.lote as Map<String, dynamic>);
                    }

                    if (lote != null) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Disponível: ${lote.quantidade}", // Simpler text
                          style: TextStyle(fontSize: 11, color: secondaryTextColor, fontWeight: FontWeight.w500)
                        ),
                      );
                      // return Column(
                      //   crossAxisAlignment: CrossAxisAlignment.start,
                      //   children: [
                      //     Text("Lote:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTextColor)),
                      //     Text("  Quantidade: ${lote.quantidade}", style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                      //   ],
                      // );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Skeleton for Product Card
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
                color: Colors.white, // Shimmer base
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
