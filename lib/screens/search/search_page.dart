// screens/search/search_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vizinhos_app/screens/models/restaurant.dart';
import 'package:vizinhos_app/screens/restaurant/restaurant_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Future<List<Restaurant>> _futureRestaurants;
  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureRestaurants = _loadRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Restaurant>> _loadRestaurants() async {
    final storage = const FlutterSecureStorage();
    final email = await storage.read(key: 'email');
    if (email == null) throw Exception('Email não encontrado.');

    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetNearStores?email=$email');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final list = (data['lojas'] as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();
      setState(() {
        _allRestaurants = list;
        _filtered = list;
      });
      return list;
    } else {
      throw Exception('Falha ao buscar restaurantes');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _allRestaurants
          .where((r) => r.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Restaurantes'),
        backgroundColor: Colors.green.shade700,
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: _futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          return Column(
            children: [
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
              Expanded(
                child: _filtered.isNotEmpty
                    ? ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final r = _filtered[index];
                          final bytes = r.imageBytes;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RestaurantDetailPage(restaurant: r),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: bytes != null
                                          ? Image.memory(
                                              bytes,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              'assets/images/default_restaurant_image.jpg',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.name,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            r.descricao,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${r.logradouro}, ${r.numero}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600),
                                          ),
                                          if (r.complemento.isNotEmpty)
                                            Text(
                                              r.complemento,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Entrega: ${r.tipoEntrega}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text('Nenhum restaurante encontrado.')),
              ),
            ],
          );
        },
      ),
    );
  }
}
