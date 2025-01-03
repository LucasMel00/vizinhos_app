// search_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vizinhos_app/models/restaurant.dart';
import 'package:vizinhos_app/screens/restaurant/restaurant_detail_page.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Future<List<Restaurant>> futureRestaurants;
  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  TextEditingController _searchController = TextEditingController();

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
    final response = await http
        .get(Uri.parse('https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/list'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      List<Restaurant> restaurantes = jsonResponse
          .map((restaurant) => Restaurant.fromJson(restaurant))
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
          title: Text('Buscar Restaurantes'),
          backgroundColor: Colors.green,
        ),
        body: FutureBuilder<List<Restaurant>>(
          future: futureRestaurants,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Indicador de carregamento
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // Mensagem de erro
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Mensagem se não houver dados
              return Center(child: Text('Nenhum restaurante encontrado.'));
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
                        prefixIcon: Icon(Icons.search),
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
                              Restaurant restaurante = _filteredRestaurants[index];
                              return _buildRestaurantCard(restaurante);
                            },
                          )
                        : Center(child: Text('Nenhum resultado encontrado.')),
                  ),
                ],
              );
            }
          },
        ));
  }

  // Widget para os cards de restaurantes
  Widget _buildRestaurantCard(Restaurant restaurant) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RestaurantDetailPage(
                  restaurant: restaurant,
                )),
      );
    },
    child: Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do Restaurante
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                restaurant.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: Icon(Icons.image, color: Colors.grey),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
              ),
            ),
            // Informações do Restaurante
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    restaurant.address,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      SizedBox(width: 4),
                      Text(
                        restaurant.rating.toString(),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
}