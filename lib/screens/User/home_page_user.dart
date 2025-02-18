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
  late Future<List<Restaurant>> futureRestaurants = Future.value([]);
  Map<String, dynamic>? userInfo;
  double? currentLat;
  double? currentLon;
  int _selectedIndex = 0;

  // Variável para o filtro por categoria (inicialmente "All")
  String _selectedFilterCategory = "All";

  @override
  void initState() {
    super.initState();
    futureRestaurants = Future.value([]);
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
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $accessToken'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userInfo = data;
        });
        String? street = userInfo?['Address'] != null ? userInfo!['Address']['Street'] : null;
        String? number = userInfo?['Address'] != null ? userInfo!['Address']['Numero'] : null;
        if (street != null && street.isNotEmpty) {
          // Concatena a rua com o número, se disponível
          String fullAddress = street;
          if (number != null && number.isNotEmpty) {
            fullAddress += ', $number';
          }
          List<Location> locations = await locationFromAddress(fullAddress);
          if (locations.isNotEmpty) {
            setState(() {
              currentLat = locations.first.latitude;
              currentLon = locations.first.longitude;
            });
          }
        }
      } else {
        final errorBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: ${errorBody['error']}')),
        );
      }
    } catch (e) {
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
        break;
      case 1:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SearchPage(
                      currentLat: currentLat,
                      currentLon: currentLon,
                    )));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersPage()));
        break;
      case 3:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => UserAccountPage(userInfo: userInfo)));
        break;
    }
  }

  // Widget para exibir o filtro de categorias utilizando chips
  Widget _buildCategoryFilter(List<String> categories) {
    return Container(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return ChoiceChip(
            label: Text(category),
            selected: _selectedFilterCategory == category,
            onSelected: (bool selected) {
              setState(() {
                _selectedFilterCategory = category;
              });
            },
            selectedColor: Colors.green.withOpacity(0.8),
            backgroundColor: Colors.grey[200],
            labelStyle: TextStyle(
              color: _selectedFilterCategory == category ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 100,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.green,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Colors.green,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60, left: 16),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              userInfo?['Address'] != null
                                  ? '${userInfo!['Address']['Street']}'
                                  : 'Carregando endereço...',
                              style: TextStyle(color: Colors.white, fontSize: 16),
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
              ),
            ],
            body: FutureBuilder<List<Restaurant>>(
              future: futureRestaurants,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonLoading();
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Nenhum restaurante encontrado.'));
                } else {
                  List<Restaurant> restaurantes = snapshot.data!;

                  // Extrai todas as categorias dos restaurantes
                  final Set<String> categorySet = {};
                  for (var r in restaurantes) {
                    categorySet.addAll(r.categories);
                  }
                  final List<String> filterCategories = ["All", ...categorySet];

                  // Filtra os restaurantes conforme a categoria selecionada
                  List<Restaurant> filteredRestaurants = _selectedFilterCategory == "All"
                      ? restaurantes
                      : restaurantes.where((r) => r.categories.contains(_selectedFilterCategory)).toList();

                  return SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barra de busca
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SearchPage(
                                          currentLat: currentLat,
                                          currentLon: currentLon,
                                        ))),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
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
                        // Categorias (ícones)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCategoryIcon(context, Icons.local_fire_department, 'Ofertas', Colors.red, OffersPage()),
                              _buildCategoryIcon(context, Icons.star, 'Melhores', Colors.orange, BestPage()),
                              _buildCategoryIcon(context, Icons.card_giftcard, 'Cupons', Colors.pink, CategoryPage(categoryName: 'Cupons')),
                            ],
                          ),
                        ),
                        // Filtro por categoria com UI aprimorada (Choice Chips)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: _buildCategoryFilter(filterCategories),
                        ),
                        // Título para restaurantes próximos
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('Restaurantes Próximos',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                        SizedBox(height: 8),
                        // Lista de restaurantes filtrados
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            return _buildRestaurantCard(
                                context: context,
                                restaurant: filteredRestaurants[index]);
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
      ),
    );
  }

  Widget _buildCategoryIcon(
      BuildContext context, IconData icon, String label, Color color, Widget destination) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, size: 32, color: color),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard({required BuildContext context, required Restaurant restaurant}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    RestaurantDetailPage(restaurant: restaurant)));
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
                    Text(restaurant.categories.join(', '),
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

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Container(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 120, color: Colors.grey[300]),
                      SizedBox(height: 8),
                      Container(height: 12, width: 80, color: Colors.grey[300]),
                      SizedBox(height: 8),
                      Container(height: 12, width: 60, color: Colors.grey[300]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
