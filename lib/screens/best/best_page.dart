// screens/Offers/offers_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vizinhos_app/screens/model/restaurant.dart';
import 'package:vizinhos_app/screens/restaurant/store_detail_page.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({Key? key}) : super(key: key);

  @override
  _OffersPageState createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  late Future<List<Restaurant>> _futureRestaurants;

  @override
  void initState() {
    super.initState();
    _futureRestaurants = _loadRestaurants();
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
      return (data['lojas'] as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();
    } else {
      throw Exception('Falha ao buscar ofertas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas'),
        backgroundColor: Colors.red.shade700,
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: _futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final list = snapshot.data!;
          return list.isNotEmpty
              ? ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final r = list[index];
                    final bytes = r.imageBytes;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailPage(restaurantId: r.idEndereco,),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(r.descricao),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                          RestaurantDetailPage(restaurantId: r.idEndereco,),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : const Center(child: Text('Nenhuma oferta disponível.'));
        },
      ),
    );
  }
}
