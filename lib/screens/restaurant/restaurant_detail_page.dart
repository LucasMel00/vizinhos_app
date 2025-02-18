import 'package:flutter/material.dart';
import 'package:vizinhos_app/screens/models/restaurant.dart';

class RestaurantDetailPage extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailPage({Key? key, required this.restaurant})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar com cor de destaque e título centralizado
      appBar: AppBar(
        title: Text(restaurant.name),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildRestaurantImage(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do restaurante
                  Text(
                    restaurant.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  // Avaliação do restaurante
                  _buildRating(),
                  SizedBox(height: 16),
                  SizedBox(height: 16),
                  // Menu do restaurante com enumeração e itens expansíveis
                  _buildMenu(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exibe a imagem do restaurante, com tratamento para loading e erro
  Widget _buildRestaurantImage() {
    return Image.network(
      restaurant.imageUrl ?? '',
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Exibe uma imagem padrão em caso de erro
        return Image.asset(
          'assets/images/default_restaurant_image.jpg',
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    (loadingProgress.expectedTotalBytes ?? 1)
                : null,
          ),
        );
      },
    );
  }

  /// Exibe a avaliação do restaurante de forma simples e elegante
  Widget _buildRating() {
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber, size: 20),
        SizedBox(width: 4),
        Text(
          restaurant.rating.toString(),
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  /// Exibe o endereço do restaurante com destaque para o título

  /// Exibe o menu do restaurante utilizando ExpansionTiles para cada item
  Widget _buildMenu() {
    // Se não houver itens no menu, exibe uma mensagem padrão
    if (restaurant.menu.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Nenhum item disponível no menu.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        // Utiliza um ListView.builder interno para exibir os itens com enumeração
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: restaurant.menu.length,
          itemBuilder: (context, index) {
            final menuItem = restaurant.menu[index];
            return Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                // Exibe o número do item em um CircleAvatar
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade200,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  menuItem.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  'R\$ ${menuItem.price.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      // Se houver uma descrição para o item, exibe-a; caso contrário, informa que não há descrição.
                      menuItem.description ?? 'Sem descrição disponível.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
