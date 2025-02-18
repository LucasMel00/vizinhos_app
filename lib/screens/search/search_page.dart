// search_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vizinhos_app/screens/models/restaurant.dart';
import 'package:vizinhos_app/screens/restaurant/restaurant_detail_page.dart';

class SearchPage extends StatefulWidget {
  final double? currentLat;
  final double? currentLon;

  const SearchPage({Key? key, this.currentLat, this.currentLon})
      : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Future<List<Restaurant>> futureRestaurants;
  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureRestaurants = fetchRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    if (widget.currentLat == null || widget.currentLon == null) {
      throw Exception('Coordenadas do usuário não disponíveis.');
    }
    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/list?x=${widget.currentLat}&y=${widget.currentLon}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      List<dynamic> restaurantsJson = jsonResponse['restaurants'];
      List<Restaurant> restaurantes = restaurantsJson
          .map((json) => Restaurant.fromJson(json))
          .toList();
      setState(() {
        _allRestaurants = restaurantes;
        _filteredRestaurants = restaurantes;
      });
      return restaurantes;
    } else {
      throw Exception('Falha ao carregar restaurantes');
    }
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        return restaurant.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Restaurantes'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Indicador de carregamento
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Mensagem de erro
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Mensagem se não houver dados
            return const Center(child: Text('Nenhum restaurante encontrado.'));
          } else {
            return Column(
              children: [
                // Barra de busca
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar restaurantes...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // Lista de resultados
                Expanded(
                  child: _filteredRestaurants.isNotEmpty
                      ? ListView.builder(
                          itemCount: _filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            Restaurant restaurant = _filteredRestaurants[index];
                            return _buildRestaurantCard(restaurant);
                          },
                        )
                      : const Center(child: Text('Nenhum resultado encontrado.')),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // Card do restaurante com tamanho reduzido e distância
  Widget _buildRestaurantCard(Restaurant restaurant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RestaurantDetailPage(restaurant: restaurant),
          ),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Imagem do restaurante
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: restaurant.imageUrl != null &&
                        restaurant.imageUrl!.isNotEmpty
                    ? Image.network(
                        restaurant.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultImage(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildImageLoader();
                        },
                      )
                    : _buildDefaultImage(),
              ),
              const SizedBox(width: 8),
              // Informações do restaurante
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
                      restaurant.categories.join(', '),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.rating.toString(),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (restaurant.distance != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on,
                              color: Colors.blue, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant.distance!.toStringAsFixed(0)} m',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
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
}

// Widget para exibir a imagem padrão (80x80)
Widget _buildDefaultImage() {
    return Image.asset(
      'assets/images/default_restaurant_image.jpg',
      height: 80,
      width: 80,
      fit: BoxFit.cover,
    );
  }

// Widget para exibir o indicador de carregamento da imagem (80x80)
Widget _buildImageLoader() {
  return Container(
    width: 80,
    height: 80,
    alignment: Alignment.center,
    child: const CircularProgressIndicator(),
  );
}
