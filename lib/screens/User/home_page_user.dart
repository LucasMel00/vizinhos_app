import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer for loading effect
import 'package:vizinhos_app/screens/User/map_screen.dart';
import 'package:vizinhos_app/screens/provider/cart_provider.dart'; // Import CartProvider
import 'package:vizinhos_app/screens/cart/cart_screen.dart'; // Import CartScreen
import 'package:vizinhos_app/screens/store/store_detail_page.dart';
import 'package:vizinhos_app/services/fcm_service.dart'; // Import FCMService
import 'package:vizinhos_app/screens/provider/orders_provider.dart'; // Import OrdersProvider
import 'package:vizinhos_app/screens/provider/notification_provider.dart'; // Importar NotificationProvider
import 'package:vizinhos_app/notifications_screen.dart'; // Importar NotificationsScreen
import 'package:vizinhos_app/screens/user/user_account_page.dart' as account;
import 'package:vizinhos_app/screens/user/user_profile_page.dart';
import 'package:vizinhos_app/screens/model/restaurant.dart';
import 'package:vizinhos_app/screens/onboarding/onboarding_user_screen.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart';
import 'package:vizinhos_app/screens/search/search_page.dart' as search;
import 'package:vizinhos_app/services/auth_provider.dart';

// Define colors for consistency
const Color primaryColor = Color(0xFFFbbc2c);
const Color secondaryColor = Color(0xFF3B4351);
const Color backgroundColor = Color(0xFFF5F5F5); // Light grey background
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF333333);
const Color secondaryTextColor = Color(0xFF666666); // Slightly darker grey

class HomePage extends StatefulWidget {
  static const routeName = '/home';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Restaurant> _restaurants = [];
  Map<String, dynamic>? userInfo;
  int _selectedIndex = 0;
  final storage = const FlutterSecureStorage();
  bool _isLoading = true;
  String _selectedCategory = 'Todas';
  List<String> _categories = ['Todas'];
  static const String lojaImageBaseUrl =
      "https://loja-profile-pictures.s3.amazonaws.com/";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
        Provider.of<NotificationProvider>(context, listen: false)
            .loadNotifications();

        // Configurar listener para atualizações do token FCM
        FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
          print('Token FCM atualizado: $token');
          // Salvar o novo token no secure storage
          await storage.write(key: 'fcm_token', value: token);

          // Se o usuário já estiver logado, atualizar o token no servidor
          if (userInfo != null &&
              userInfo!['usuario'] != null &&
              userInfo!['usuario']['cpf'] != null) {
            String userCpf = userInfo!['usuario']['cpf'];
            bool result = await FCMService.registerFCMToken(
              cpf: userCpf,
              fcmToken: token,
            );
            print('Resultado da atualização do token FCM: $result');
          }
        });
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await fetchUserInfo();

      // Registrar o token FCM se o usuário estiver logado e tiver CPF
      if (userInfo != null && userInfo!['cpf'] != null) {
        String userCpf = userInfo!['cpf'];
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          // Usar o FCMService para registrar o token
          bool result = await FCMService.registerFCMToken(
            cpf: userCpf,
            fcmToken: fcmToken,
          );

          // Log do resultado para depuração
          print('Resultado do registro do token FCM: $result');
        }
      }

      final restaurants = await fetchRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
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
    await _loadData();
    await Provider.of<NotificationProvider>(context, listen: false)
        .loadNotifications(); // Corrigido
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
        final cpf = data['usuario']?['cpf'];
        if (cpf != null) {
          print('CPF encontrado: $cpf');
          await storage.write(key: 'cpf', value: cpf);
          authProvider.setCpf(cpf);
        }
        if (mounted) {
          setState(() {
            userInfo = data;
          });

          // Registrar o token FCM após obter as informações do usuário
          if (data != null &&
              data['usuario'] != null &&
              data['usuario']['cpf'] != null) {
            String userCpf = data['usuario']['cpf'];
            print('CPF encontrado: $userCpf');

            // Obter o token FCM do secure storage
            String? fcmToken = await storage.read(key: 'fcm_token');

            // Se não estiver no secure storage, tenta obter do Firebase
            if (fcmToken == null) {
              fcmToken = await FirebaseMessaging.instance.getToken();
              // Salvar o token no secure storage para uso futuro
              if (fcmToken != null) {
                await storage.write(key: 'fcm_token', value: fcmToken);
              }
            }

            print('Token FCM: $fcmToken');

            if (fcmToken != null) {
              // Usar o FCMService para registrar o token
              bool result = await FCMService.registerFCMToken(
                cpf: userCpf,
                fcmToken: fcmToken,
              );

              print('Resultado do registro do token FCM: $result');
            } else {
              print('Token FCM não encontrado');
            }
          } else {
            print('CPF não encontrado na resposta: $data');
          }
        }
      } else {
        print("Erro fetchUserInfo HTTP: ${response.statusCode}");
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
      return [];
    }

    final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetNearStores?email=$email',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<dynamic> lojasJson = (jsonResponse is Map &&
                jsonResponse.containsKey('lojas') &&
                jsonResponse['lojas'] is List)
            ? jsonResponse['lojas']
            : [];
        return lojasJson.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        print('Erro HTTP fetchRestaurants: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ERRO] fetchRestaurants: $e');
      return [];
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navegar para a página correspondente
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HomePage(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => search.SearchPage(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
      case 2: // Orders
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final cpf = authProvider.cpf ?? '';
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => OrdersPage(cpf: cpf),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => account.UserAccountPage(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
      case 4: // Novo caso para o mapa
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => MapScreen(userEmail: Provider.of<AuthProvider>(context, listen: false).email ?? ''),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
    }
  }

  Widget _buildRestaurantCard({
    required BuildContext context,
    required Restaurant restaurant,
  }) {
    String? displayImageUrl = restaurant.imagemUrl;
    if ((displayImageUrl == null || displayImageUrl.isEmpty) &&
        restaurant.imageString != null &&
        restaurant.imageString!.isNotEmpty) {
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
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                RestaurantDetailPage(restaurantId: restaurant.idEndereco),
            transitionDuration: const Duration(milliseconds: 100),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        color: cardBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (displayImageUrl != null && displayImageUrl.isNotEmpty)
                    ? Image.network(
                        displayImageUrl,
                        height: 72,
                        width: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              "Error loading image: $displayImageUrl, Error: $error");
                          return _buildDefaultImage(height: 72, width: 72);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 72,
                            width: 72,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
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
                    : _buildDefaultImage(height: 72, width: 72),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.descricao,
                      style: const TextStyle(
                          fontSize: 12, color: secondaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: secondaryTextColor),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${restaurant.logradouro}, ${restaurant.numero}',
                            style: const TextStyle(
                                fontSize: 11, color: secondaryTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_shipping,
                            size: 14, color: secondaryTextColor),
                        SizedBox(width: 4),
                        Text(
                          'Entrega: ${restaurant.tipoEntrega}',
                          style: const TextStyle(
                              fontSize: 11, color: secondaryTextColor),
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
        itemCount: 5,
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
                    color: Colors.white,
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
    String userAddress = 'Carregando endereço...';
    if (userInfo != null && userInfo!['endereco'] != null) {
      final endereco = userInfo!['endereco'];
      userAddress = '${endereco['logradouro']}, ${endereco['numero']}';
    }

    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: RefreshIndicator(
            onRefresh: _refresh,
            color: primaryColor,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  automaticallyImplyLeading: false, // Hide back button
                  title: Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          userAddress,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  pinned: true,
                  floating: true,
                  snap: true,
                  elevation: 2,
                  forceElevated: innerBoxIsScrolled,
                  backgroundColor: primaryColor,
                  actions: [
                    // Notification Icon Button
                    Consumer<NotificationProvider>(
                      builder: (ctx, notificationProvider, child) => Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications_outlined,
                                color: Colors.white),
                            tooltip: 'Notificações',
                            onPressed: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      NotificationsScreen(),
                                  transitionDuration:
                                      const Duration(milliseconds: 140),
                                  transitionsBuilder:
                                      (_, animation, __, child) =>
                                          FadeTransition(
                                              opacity: animation, child: child),
                                ),
                              );
                            },
                          ),
                          if (notificationProvider.unreadNotificationsCount > 0)
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
                                  '${notificationProvider.unreadNotificationsCount}',
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
                    // Cart Icon Button
                    Consumer<CartProvider>(
                      builder: (ctx, cart, child) => Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.shopping_cart_outlined,
                                color: Colors.white),
                            tooltip: 'Carrinho',
                            onPressed: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => CartScreen(),
                                  transitionDuration:
                                      const Duration(milliseconds: 140),
                                  transitionsBuilder:
                                      (_, animation, __, child) =>
                                          FadeTransition(
                                              opacity: animation, child: child),
                                ),
                              );
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
                  ? _buildSkeletonLoading()
                  : _restaurants.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Nenhuma loja encontrada perto de você.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: _restaurants.length,
                          itemBuilder: (context, index) {
                            final store = _restaurants[index];
                            return AnimatedOpacity(
                              duration: Duration(milliseconds: 300 + (index * 50)),
                              opacity: 1.0,
                              child: _buildRestaurantCard(
                                context: context,
                                restaurant: store,
                              ),
                            );
                          },
                        ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFbbc2c),
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
                  _buildNavIcon(Icons.map, 'Mapa', 4, context), // Novo ícone de mapa
                  _buildNavIcon(Icons.list, 'Pedidos', 2, context),
                  _buildNavIcon(Icons.person, 'Conta', 3, context),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildNavIcon(
      IconData icon, String label, int index, BuildContext context) {
    bool isSelected = index == _selectedIndex;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color.fromARGB(255, 237, 236, 233)
                  : const Color.fromRGBO(59, 67, 81, 1).withOpacity(0.7),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? const Color.fromARGB(255, 21, 21, 21)
                    : secondaryColor.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            )
          ],
        ),
      ),
    );
  }
}
