import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/User/user_account_page.dart';
import 'package:vizinhos_app/screens/models/restaurant.dart';
import 'package:vizinhos_app/screens/Offers/offers_page.dart';
import 'package:vizinhos_app/screens/best/best_page.dart';
import 'package:vizinhos_app/screens/category/category_page.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart';
import 'package:vizinhos_app/screens/restaurant/restaurantMapScreen.dart';
import 'package:vizinhos_app/screens/restaurant/restaurant_detail_page.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:geocoding/geocoding.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Inicializa com um Future que retorna uma lista vazia para evitar LateInitializationError.
  late Future<List<Restaurant>> futureRestaurants = Future.value([]);
  Map<String, dynamic>? userInfo;

  // Coordenadas obtidas a partir do endereço do usuário
  double? currentLat;
  double? currentLon;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    futureRestaurants = Future.value([]);
    // Busca informações do usuário e converte o endereço para coordenadas.
    fetchUserInfo().then((_) {
      setState(() {
        futureRestaurants = fetchRestaurants();
      });
    });
  }

  Future<void> _refresh() async {
    await fetchUserInfo();
    setState(() {
      futureRestaurants = fetchRestaurants();
    });
  }

  Future<void> fetchUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;
    final accessToken = authProvider.accessToken;
    if (accessToken == null) return;

    final url = Uri.parse('https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/user');

    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $accessToken'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userInfo = data;
        });
        // Acesse o endereço salvo; ajuste a chave conforme sua estrutura de dados.
        String? street = userInfo?['Address'] != null
            ? userInfo!['Address']['Street']
            : null;
        print("Endereço recuperado: $street");
        if (street != null && street.isNotEmpty) {
          try {
            List<Location> locations = await locationFromAddress(street);
            if (locations.isNotEmpty) {
              setState(() {
                currentLat = locations.first.latitude;
                currentLon = locations.first.longitude;
              });
              print("Coordenadas obtidas: $currentLat, $currentLon");
            } else {
              print("Nenhuma localização encontrada para: $street");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Nenhuma localização encontrada para: $street")),
              );
            }
          } catch (geocodeError) {
            print("Erro na geocodificação do endereço: $geocodeError");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erro na geocodificação: $geocodeError")),
            );
          }
        } else {
          print("Endereço do usuário não encontrado ou vazio.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Endereço do usuário não disponível.")),
          );
        }
      } else {
        final errorBody = json.decode(response.body);
        print("Erro ao carregar dados: ${errorBody['error']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: ${errorBody['error']}')),
        );
      }
    } catch (e) {
      print("Erro: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    if (currentLat == null || currentLon == null) {
      throw Exception('Coordenadas do usuário não disponíveis.');
    }
    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/list?x=$currentLat&y=$currentLon');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      List<dynamic> restaurantsJson = jsonResponse['restaurants'];
      return restaurantsJson.map((json) => Restaurant.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar restaurantes');
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Já estamos na HomePage.
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersPage()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => UserAccountPage(userInfo: userInfo)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O design usa o verde como cor principal.
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 80,
              backgroundColor: Colors.green,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.green, // Fundo sólido verde
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50, left: 16),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            userInfo?['Address'] != null
                                ? '${userInfo!['Address']['Street']}'
                                : 'Carregando endereço...',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.map, color: Colors.white),
                          onPressed: () {
                            if (currentLat != null && currentLon != null) {
                              futureRestaurants.then((restaurants) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RestaurantMapScreen(
                                      userLatitude: currentLat!,
                                      userLongitude: currentLon!,
                                      restaurants: restaurants,
                                    ),
                                  ),
                                );
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Localização não disponível.")),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ],
          body: FutureBuilder<List<Restaurant>>(
            future: futureRestaurants,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height - kToolbarHeight,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height - kToolbarHeight,
                      child: Center(child: Text('Erro: ${snapshot.error}')),
                    ),
                  ],
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height - kToolbarHeight,
                      child: Center(child: Text('Nenhum restaurante encontrado.')),
                    ),
                  ],
                );
              } else {
                List<Restaurant> restaurantes = snapshot.data!;
                return SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra de busca estilizada
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage())),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Text("Buscar restaurantes...", style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Categorias
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCategoryIcon(context, Icons.local_fire_department, 'Ofertas', Colors.red, OffersPage()),
                            _buildCategoryIcon(context, Icons.star, 'Melhores', Colors.orange, BestPage()),
                            _buildCategoryIcon(context, Icons.card_giftcard, 'Cupons', Colors.pink, CategoryPage(categoryName: 'Cupons')),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Título da seção
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Restaurantes Próximos',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      SizedBox(height: 8),
                      // Lista de restaurantes
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: restaurantes.length,
                        itemBuilder: (context, index) {
                          return _buildRestaurantCard(context: context, restaurant: restaurantes[index]);
                        },
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Procurar'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Conta'),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context, IconData icon, String label, Color color, Widget destination) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, size: 28, color: color),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard({required BuildContext context, required Restaurant restaurant}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailPage(restaurant: restaurant)));
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Container(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty
                    ? Image.network(
                        restaurant.imageUrl!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildImageLoader();
                        },
                      )
                    : _buildDefaultImage(),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4),
                    Text(restaurant.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(restaurant.rating.toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    if (restaurant.distance != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue, size: 14),
                          SizedBox(width: 4),
                          Text('${restaurant.distance!.toStringAsFixed(0)} m',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Image.asset(
      'assets/images/default_restaurant_image.jpg',
      height: 80,
      width: 80,
      fit: BoxFit.cover,
    );
  }

  Widget _buildImageLoader() {
    return Container(
      height: 80,
      width: 80,
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  }
}
