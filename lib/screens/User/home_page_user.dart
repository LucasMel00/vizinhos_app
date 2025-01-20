// lib/screens/Home/home_page.dart

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
import 'package:vizinhos_app/screens/restaurant/restaurant_detail_page.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Restaurant>> futureRestaurants;

  @override
  void initState() {
    super.initState();
    futureRestaurants = fetchRestaurants();
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    final response = await http.get(Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/list')); // Substitua pela URL correta

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((restaurant) => Restaurant.fromJson(restaurant))
          .toList();
    } else {
      throw Exception('Falha ao carregar restaurantes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.black),
          onPressed: () {
            // Navegar para a UserAccountPage
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserAccountPage()),
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Endereço de Entrega',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Instituto Federal de S...',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
            onPressed: () {
              // Ação para alterar o local
              // Você pode implementar uma página de seleção de localização
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Exibir indicador de carregamento enquanto os dados estão sendo buscados
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Exibir mensagem de erro se a requisição falhar
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Exibir mensagem se não houver dados
            return Center(child: Text('Nenhum restaurante encontrado.'));
          } else {
            // Dados foram carregados com sucesso, exibir a lista de restaurantes
            List<Restaurant> restaurantes = snapshot.data!;

            // Filtrar restaurantes por categoria
            List<Restaurant> melhoresRestaurantes = restaurantes
                .where((r) => r.categories.contains('Melhores'))
                .toList();
            List<Restaurant> ofertasRestaurantes = restaurantes
                .where((r) => r.categories.contains('Ofertas'))
                .toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de busca
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SearchPage()),
                        );
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search here..',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Categorias
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCategoryIcon(
                            context,
                            Icons.local_fire_department,
                            'Ofertas',
                            Colors.red,
                            OffersPage()), // Navega para OffersPage
                        _buildCategoryIcon(context, Icons.star, 'Melhores',
                            Colors.orange, BestPage()), // Navega para BestPage
                        _buildCategoryIcon(
                            context,
                            Icons.card_giftcard,
                            'Cupons',
                            Colors.pink,
                            CategoryPage(
                                categoryName:
                                    'Cupons')), // Mantém navegação para CategoryPage
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Seção "Melhores Restaurantes"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Melhores Restaurantes',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    child: melhoresRestaurantes.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: melhoresRestaurantes.length,
                            itemBuilder: (context, index) {
                              return _buildRestaurantCard(
                                context: context,
                                restaurant: melhoresRestaurantes[index],
                              );
                            },
                          )
                        : Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Nenhum restaurante na categoria "Melhores".',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                  ),

                  SizedBox(height: 16),

                  // Seção "Ofertas"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Ofertas',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    child: ofertasRestaurantes.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: ofertasRestaurantes.length,
                            itemBuilder: (context, index) {
                              return _buildRestaurantCard(
                                context: context,
                                restaurant: ofertasRestaurantes[index],
                              );
                            },
                          )
                        : Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Nenhum restaurante na categoria "Ofertas".',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                  ),

                  SizedBox(height: 16),

                  // Seção "Cupons" (Opcional)
                  // Caso deseje adicionar, siga o mesmo padrão acima.

                  // Lista Geral de Restaurantes (Opcional)
                  // Se desejar manter uma lista geral abaixo das seções, adicione aqui.
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // Defina o índice atual conforme a navegação
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Procurar'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Conta'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Já está na Home, você pode implementar uma ação de recarregar ou nada
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrdersPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserAccountPage()),
              );
              break;
          }
        },
      ),
    );
  }

  // Widget para os ícones das categorias
  Widget _buildCategoryIcon(BuildContext context, IconData icon, String label,
      Color color, Widget destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => destination,
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }

  // Widget para os cards de restaurantes
  Widget _buildRestaurantCard({
    required BuildContext context,
    required Restaurant restaurant,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailPage(
              restaurant: restaurant, // Passe o objeto completo
            ),
          ),
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
