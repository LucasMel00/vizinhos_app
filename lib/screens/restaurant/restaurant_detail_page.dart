import 'package:flutter/material.dart';
import 'package:vizinhos_app/screens/models/restaurant.dart';
import 'package:intl/intl.dart';

class RestaurantDetailPage extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailPage({Key? key, required this.restaurant})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Removemos o appBar do Scaffold para evitar duplicação.
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: true,
            pinned: true,
            expandedHeight:
                250, // Mantendo o expandedHeight em 200 ou ajuste conforme necessário
            backgroundColor: const Color.fromARGB(206, 241, 241, 241),
            shadowColor: Colors.black.withOpacity(0.2),
            title: Text(
              restaurant.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, size: 22),
                onPressed: () => _shareRestaurant(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRestaurantInfo(),
                  const SizedBox(height: 32),
                  _buildMenuSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildHeroHeader() {
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            // Centralizando a imagem
            child: SizedBox(
              // Definindo um tamanho máximo para a imagem
              height: 550, // Ajuste a altura desejada
              width: 750, // Ajuste a largura desejada
              child: Hero(
                tag: 'restaurant-hero-${restaurant.x}',
                child: ClipRRect(
                  // Opcional: para bordas arredondadas se desejar
                  borderRadius:
                      BorderRadius.circular(10), // Ajuste o raio se necessário
                  child: restaurant.imageUrl != null &&
                          restaurant.imageUrl!.isNotEmpty
                      ? Image.network(
                          restaurant.imageUrl!,
                          fit: BoxFit
                              .cover, // Use BoxFit.cover para preencher o SizedBox sem distorcer muito
                          errorBuilder: (_, __, ___) =>
                              _buildDefaultHeroImage(),
                        )
                      : _buildDefaultHeroImage(),
                ),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultHeroImage() {
    return Image.asset(
      'assets/images/default_restaurant_image.jpg',
      fit: BoxFit.cover,
    );
  }

  Widget _buildRestaurantInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRatingRow(),
                ],
              ),
            ),
            _buildStatusIndicator(),
          ],
        ),
        const SizedBox(height: 24),
        _buildInfoGrid(),
      ],
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 6),
              Text(
                restaurant.rating.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '',
          style: TextStyle(
            fontSize: 14,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(
        'Aberto agora',
        style: TextStyle(
          color: Colors.green.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildInfoItem(Icons.access_time_rounded, 'Horário', '11:00 - 23:00'),
        _buildInfoItem(Icons.delivery_dining_rounded, 'Entrega', 'R\$ 5,00'),
        _buildInfoItem(Icons.location_pin, 'Distância', '1.2 km'),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.green.shade800),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cardápio Popular',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        ...restaurant.menu.map((item) => _buildMenuItem(item)).toList(),
      ],
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    final priceFormatted = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(item.price);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _handleMenuItemTap(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? NetworkImage(item.imageUrl!)
                        : const AssetImage(
                                'assets/images/default_menu_item.jpg')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description ?? 'Descrição não disponível',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      priceFormatted,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.grey.shade400,
                ),
                onPressed: () => _toggleFavorite(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showOrderOptions(context),
      icon: const Icon(Icons.shopping_bag_outlined),
      label: const Text('Pedir Agora'),
      backgroundColor: Colors.green.shade800,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }

  // Métodos de interação (a serem implementados)
  void _shareRestaurant() {}
  void _handleMenuItemTap(MenuItem item) {}
  void _toggleFavorite(MenuItem item) {}
  void _showOrderOptions(BuildContext context) {}
}
