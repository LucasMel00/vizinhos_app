// screens/Offers/offers_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vizinhos_app/screens/models/restaurant.dart';
import 'package:vizinhos_app/screens/restaurant/restaurant_detail_page.dart';

class OffersPage extends StatefulWidget {
  @override
  _OffersPageState createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  late Future<List<Restaurant>> futureOffers;

  @override
  void initState() {
    super.initState();
    futureOffers = fetchOffers();
  }

  Future<List<Restaurant>> fetchOffers() async {
    final response = await http.get(Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/list'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      List<Restaurant> allRestaurants = jsonResponse
          .map((restaurant) => Restaurant.fromJson(restaurant))
          .toList();

      // Filtrar restaurantes que contêm "Ofertas" em suas categorias
      return allRestaurants
          .where((restaurant) => restaurant.categories.contains('Ofertas'))
          .toList();
    } else {
      throw Exception('Falha ao carregar ofertas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ofertas'),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: futureOffers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Indicador de carregamento
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Mensagem de erro
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Mensagem se não houver dados
            return Center(child: Text('Nenhuma oferta encontrada.'));
          } else {
            List<Restaurant> offers = snapshot.data!;
            return ListView.builder(
              itemCount: offers.length,
              itemBuilder: (context, index) {
                return _buildRestaurantCard(offers[index]);
              },
            );
          }
        },
      ),
    );
  }

  // Método para construir o card do restaurante
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
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Imagem do restaurante
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                restaurant.imageUrl,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 80,
                    width: 80,
                    color: Colors.grey[200],
                    child: Icon(Icons.image, color: Colors.grey),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 80,
                    width: 80,
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
            SizedBox(width: 16),
            // Informações do restaurante
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                        '${restaurant.menu.isNotEmpty ? 'R\$ ${restaurant.menu[0].price.toStringAsFixed(2)}' : 'R\$ 0.00'} • 25-35 min',
                        style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          restaurant.rating.toString(),
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
