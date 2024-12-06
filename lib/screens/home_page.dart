import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.black),
          onPressed: () {
            // Ação ao clicar no ícone do perfil
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Endereço de Entrega',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
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
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de busca
            Padding(
              padding: const EdgeInsets.all(16.0),
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
            // Categorias
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCategoryIcon(Icons.local_fire_department, 'Ofertas', Colors.red),
                  _buildCategoryIcon(Icons.star, 'Melhores', Colors.orange),
                  _buildCategoryIcon(Icons.card_giftcard, 'Cupons', Colors.pink),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Lista de produtos/restaurantes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: List.generate(5, (index) {
                  return _buildRestaurantCard(
                    name: 'Seu Zé',
                    price: 'R\$ 20.99',
                    deliveryTime: '25-35 min',
                    rating: 4.9,
                    imageUrl: 'https://i.imgur.com/dintSDW.jpeg',
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      // Barra de navegação inferior
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Procurar'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Conta'),
        ],
        onTap: (index) {
          // Ação ao clicar nos itens do menu inferior
        },
      ),
    );
  }

  // Widget para os ícones das categorias
  Widget _buildCategoryIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.black)),
      ],
    );
  }

  // Widget para os cards de restaurantes
  Widget _buildRestaurantCard({
  required String name,
  required String price,
  required String deliveryTime,
  required double rating,
  required String imageUrl,
}) {
  return Card(
    margin: EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            height: 80, // Altura máxima da imagem
            width: 80, // Largura máxima da imagem
            fit: BoxFit.cover, // Ajusta a imagem ao contêiner sem distorção
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('$price • $deliveryTime', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text(rating.toString(), style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}
