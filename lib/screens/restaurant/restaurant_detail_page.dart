// screens/restaurant/restaurant_detail_page.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:vizinhos_app/screens/model/restaurant.dart';

class RestaurantDetailPage extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailPage({Key? key, required this.restaurant})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bytes = restaurant.imageBytes;
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        backgroundColor: const Color(0xFFFbbc2c),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bytes != null
                ? Image.memory(bytes,
                    width: double.infinity, height: 200, fit: BoxFit.cover)
                : Image.asset('assets/images/default_restaurant_image.jpg',
                    width: double.infinity, height: 200, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(restaurant.descricao,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              '${restaurant.logradouro}, ${restaurant.numero}'))
                    ],
                  ),
                  if (restaurant.complemento.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.home_work),
                        const SizedBox(width: 8),
                        Expanded(child: Text(restaurant.complemento)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping),
                      const SizedBox(width: 8),
                      Text('Entrega: ${restaurant.tipoEntrega}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.mail),
                      const SizedBox(width: 8),
                      Text('CEP: ${restaurant.cep}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
