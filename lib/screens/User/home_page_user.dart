import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/User/user_account_page.dart';
import 'package:vizinhos_app/screens/model/restaurant.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart';
import 'package:vizinhos_app/screens/restaurant/restaurant_detail_page.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Remova o 'late' e inicialize com um valor vazio seguro
  Future<List<Restaurant>> futureRestaurants = Future.value([]);
  Map<String, dynamic>? userInfo;
  int _selectedIndex = 0;
  final storage = const FlutterSecureStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Use WidgetsBinding para garantir que o context esteja disponível
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      await fetchUserInfo();

      if (mounted) {
        setState(() {
          futureRestaurants = fetchRestaurants();
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

    setState(() {
      _isLoading = true;
    });

    await _loadData();
  }

  Future<void> fetchUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    // Tenta obter o email
    String? email = authProvider.email;
    if (email == null) {
      email = await storage.read(key: 'email');
      if (email == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Email não encontrado no dispositivo')),
          );
        }
        return;
      }
    }

    final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetUserByEmail?email=$email',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            userInfo = data;
          });
        }
      } else {
        if (response.body.isNotEmpty) {
          try {
            final errorBody = json.decode(response.body);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Erro ao carregar dados: ${errorBody['error'] ?? "Erro desconhecido"}')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao processar resposta: $e')),
              );
            }
          }
        }
      }
    } catch (e) {
      print("Erro fetchUserInfo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de rede: $e')),
        );
      }
    }
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String? email = authProvider.email;

      if (email == null) {
        email = await storage.read(key: 'email');
        if (email == null) {
          return [];
        }
      }

      final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetNearStores?email=$email',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<dynamic> lojasJson = jsonResponse['lojas'] ?? [];
        return lojasJson.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        print('Erro HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ERRO] fetchRestaurants: $e');
      return []; // Retorna lista vazia em caso de erro
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SearchPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrdersPage()),
        );
        break;
      case 3:
        Navigator.push(
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
    final imageBytes = restaurant.imageBytes;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailPage(restaurant: restaurant),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        color: const Color.fromARGB(
            255, 255, 255, 255), // Creme suave que complementa o amarelo

        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultImage(),
                      )
                    : _buildDefaultImage(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.descricao,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${restaurant.logradouro}, ${restaurant.numero}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Entrega: ${restaurant.tipoEntrega}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildDefaultImage() {
    return Image.asset(
      'assets/images/default_restaurant_image.jpg',
      height: 80,
      width: 80,
      fit: BoxFit.cover,
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(12),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 16, width: 120, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 80, color: Colors.grey[300]),
                      const SizedBox(height: 8),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 100,
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xFFFbbc2c),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xFFFbbc2c),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60, left: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              userInfo?['endereco'] != null
                                  ? '${userInfo!['endereco']['logradouro']}, ${userInfo!['endereco']['numero']}'
                                  : 'Carregando endereço...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.white),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Funcionalidade de mapa não disponível')),
                              );
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
                  return Center(
                    child: Text('Erro: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma loja encontrada.'),
                  );
                } else {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: snapshot.data!
                        .map((store) => _buildRestaurantCard(
                              context: context,
                              restaurant: store,
                            ))
                        .toList(),
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
              color: const Color(0xFFFbbc2c), // Mesma cor do app bar
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
                _buildNavIcon(Icons.home, 0, context),
                _buildNavIcon(Icons.search, 1, context),
                _buildNavIcon(Icons.list, 2, context),
                _buildNavIcon(Icons.person, 3, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, BuildContext context) {
    bool isSelected = index == _selectedIndex;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          icon,
          size: 24,
          color: isSelected
              ? Colors.white
              : const Color(0xFF3B4351), // Branco para selecionado
        ),
      ),
    );
  }
}
