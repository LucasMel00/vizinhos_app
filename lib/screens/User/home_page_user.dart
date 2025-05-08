import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/User/user_account_page.dart';
import 'package:vizinhos_app/screens/model/restaurant.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart';
import 'package:vizinhos_app/screens/restaurant/restaurant_detail_page.dart'; // Corrected import
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer for loading effect
import 'package:provider/provider.dart'; // Import Provider
import 'package:vizinhos_app/screens/provider/cart_provider.dart'; // Import CartProvider
import 'package:vizinhos_app/screens/cart/cart_screen.dart'; // Import CartScreen

// Define colors for consistency
const Color primaryColor = Color(0xFFFbbc2c);
const Color secondaryColor = Color(0xFF3B4351);
const Color backgroundColor = Color(0xFFF5F5F5); // Light grey background
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF333333);
const Color secondaryTextColor = Color(0xFF666666); // Slightly darker grey

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Restaurant>> futureRestaurants = Future.value([]);
  Map<String, dynamic>? userInfo;
  int _selectedIndex = 0;
  final storage = const FlutterSecureStorage();
  bool _isLoading = true;
  static const String lojaImageBaseUrl = "https://loja-profile-pictures.s3.amazonaws.com/"; // Base URL for store images

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Set loading true when starting
    });
    try {
      await fetchUserInfo();
      // Fetch restaurants after user info
      final restaurants = await fetchRestaurants();
      if (mounted) {
        setState(() {
          futureRestaurants = Future.value(restaurants); // Assign fetched data
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao carregar dados: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await _loadData(); // Reload all data on refresh
  }

  Future<void> fetchUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    String? email = authProvider.email ?? await storage.read(key: 'email');
    if (email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email não encontrado no dispositivo')),
        );
      }
      return;
    }

    final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetUserByEmail?email=$email',
    );

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            userInfo = data;
          });
        }
      } else {
        print("Erro fetchUserInfo HTTP: ${response.statusCode}");
        // Handle error display more gracefully if needed
      }
    } catch (e) {
      print("Erro fetchUserInfo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de rede ao buscar usuário: $e')),
        );
      }
    }
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? email = authProvider.email ?? await storage.read(key: 'email');

    if (email == null) {
      print("Email não disponível para fetchRestaurants");
      return []; // Return empty if no email
    }

    // Assuming GetNearStores is the correct endpoint for the list
    final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetNearStores?email=$email',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        // Ensure 'lojas' key exists and is a list
        List<dynamic> lojasJson = (jsonResponse is Map && jsonResponse.containsKey('lojas') && jsonResponse['lojas'] is List)
            ? jsonResponse['lojas']
            : [];
        return lojasJson.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        print('Erro HTTP fetchRestaurants: ${response.statusCode}');
        return []; // Return empty on HTTP error
      }
    } catch (e) {
      print('[ERRO] fetchRestaurants: $e');
      return []; // Return empty on general error
    }
  }

  void _onNavItemTapped(int index) {
    // Prevent navigation if already on the selected tab (index 0 = Home)
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    // Use Navigator.pushReplacement to avoid stacking pages unnecessarily
    // or manage state differently if you need back navigation.
    switch (index) {
      case 0: // Home - Do nothing or refresh
         _refresh(); // Example: Refresh home page
        break;
      case 1: // Search
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SearchPage()),
        );
        break;
      case 2: // Orders
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrdersPage()),
        );
        break;
      case 3: // Account
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => UserAccountPage(userInfo: userInfo)),
        );
        break;
    }
  }

  Widget _buildRestaurantCard({
    required BuildContext context,
    required Restaurant restaurant,
  }) {
    // Construct image URL if only id_Imagem (imageString) is available
    String? displayImageUrl = restaurant.imagemUrl; // Prefer the full URL if available
    if ((displayImageUrl == null || displayImageUrl.isEmpty) &&
        restaurant.imageString != null &&
        restaurant.imageString!.isNotEmpty) {
      // Remove leading slash if present before concatenating
      String imageName = restaurant.imageString!;
      if (imageName.startsWith("/")) {
        imageName = imageName.substring(1);
      }
      displayImageUrl = lojaImageBaseUrl + imageName;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // Pass only the ID to the detail page
            builder: (context) => RestaurantDetailPage(restaurantId: restaurant.idEndereco),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Slightly less rounded
        elevation: 2, // Softer elevation
        shadowColor: Colors.black.withOpacity(0.1), // Softer shadow color
        color: cardBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8), // Consistent rounding
                // Use the constructed or provided displayImageUrl
                child: (displayImageUrl != null && displayImageUrl.isNotEmpty)
                    ? Image.network(
                        displayImageUrl,
                        height: 72, // Slightly smaller image
                        width: 72,
                        fit: BoxFit.cover,
                        // More robust error handling for images
                        errorBuilder: (context, error, stackTrace) {
                          print("Error loading image: $displayImageUrl, Error: $error");
                          return _buildDefaultImage(height: 72, width: 72); // Show default on error
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                             height: 72,
                             width: 72,
                             color: Colors.grey[200],
                             child: Center(
                               child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: primaryColor, // Use primary color for indicator
                               ),
                             ),
                          );
                        },
                      )
                    : _buildDefaultImage(height: 72, width: 72), // Show default if no URL
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                          fontSize: 15, // Slightly smaller title
                          fontWeight: FontWeight.w600, // Medium weight
                          color: primaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.descricao,
                      style: const TextStyle(fontSize: 12, color: secondaryTextColor),
                      maxLines: 1, // Show less description initially
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: secondaryTextColor),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${restaurant.logradouro}, ${restaurant.numero}',
                            style: const TextStyle(fontSize: 11, color: secondaryTextColor),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                     Row(
                      children: [
                        Icon(Icons.local_shipping, size: 14, color: secondaryTextColor),
                        SizedBox(width: 4),
                        Text(
                          'Entrega: ${restaurant.tipoEntrega}',
                          style: const TextStyle(fontSize: 11, color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage({double height = 80, double width = 80}) {
    // Ensure the default asset image exists in your project
    return Image.asset(
      'assets/images/default_restaurant_image.jpg',
      height: height,
      width: width,
      fit: BoxFit.cover,
    );
  }

  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5, // Show a few skeleton items
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: Colors.white, // Placeholder color for shimmer
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 15, width: 150, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 200, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 11, width: 100, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 11, width: 80, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    // Get user address safely
    String userAddress = 'Carregando endereço...';
    if (userInfo != null && userInfo!['endereco'] != null) {
      final endereco = userInfo!['endereco'];
      userAddress = '${endereco['logradouro']}, ${endereco['numero']}';
    }

    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation from home
      child: Scaffold(
        backgroundColor: backgroundColor, // Apply background color
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: primaryColor, // Indicator color
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                title: Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        userAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                pinned: true,
                floating: true,
                snap: true,
                elevation: 2, // Subtle elevation
                forceElevated: innerBoxIsScrolled, // Show elevation when scrolled
                automaticallyImplyLeading: false,
                backgroundColor: primaryColor,
                actions: [
                  // Cart Icon Button
                  Consumer<CartProvider>(
                    builder: (ctx, cart, child) => Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
                          tooltip: 'Carrinho',
                          onPressed: () {
                            Navigator.of(context).pushNamed(CartScreen.routeName);
                          },
                        ),
                        if (cart.itemCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${cart.itemCount}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            body: _isLoading
                ? _buildSkeletonLoading() // Show shimmer skeleton while loading
                : FutureBuilder<List<Restaurant>>(
                    future: futureRestaurants,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
                        return _buildSkeletonLoading();
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Erro ao carregar lojas: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Nenhuma loja encontrada perto de você.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          ),
                        );
                      } else {
                        // Use ListView.builder for performance
                        return ListView.builder(
                          padding: EdgeInsets.only(top: 8, bottom: 80), // Adjust bottom padding for nav bar
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final store = snapshot.data![index];
                            // Add subtle animation to cards
                            return AnimatedOpacity(
                              duration: Duration(milliseconds: 300 + (index * 50)), // Staggered animation
                              opacity: 1.0, // Assuming initial opacity is 1.0
                              child: _buildRestaurantCard(
                                context: context,
                                restaurant: store,
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFbbc2c), // Same color as the app bar
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
          _buildNavIcon(Icons.home, 'Início', 0, context),
          _buildNavIcon(Icons.search, 'Buscar', 1, context),
          _buildNavIcon(Icons.list, 'Pedidos', 2, context),
          _buildNavIcon(Icons.person, 'Conta', 3, context),
              ],
            ),
          ),
        ),
      )

    );
  }

  Widget _buildNavIcon(IconData icon, String label, int index, BuildContext context) {
    bool isSelected = index == _selectedIndex;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      borderRadius: BorderRadius.circular(20), // Rounded tap area
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color.fromARGB(255, 237, 236, 233) : secondaryColor.withOpacity(0.7),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color.fromARGB(255, 21, 21, 21) : secondaryColor.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            )
          ],
        ),
      ),
    );
  }
}
