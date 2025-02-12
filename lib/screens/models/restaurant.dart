// models/restaurant.dart

class MenuItem {
  final String name;
  final String itemId;
  final double price;

  MenuItem({
    required this.name,
    required this.itemId,
    required this.price,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['name'] ?? 'Item sem nome', // Trata nome nulo
      itemId: json['itemId'] ?? '', // Trata itemId nulo
      price: (json['price'] as num?)?.toDouble() ?? 0.0, // Trata preço nulo
    );
  }

  get description => null;
}

class Restaurant {
  final String restaurantId;
  final String name;
  final String address;
  final List<String> categories;
  final double rating;
  final String? imageUrl; // Campo opcional
  final List<MenuItem> menu; // Lista de itens do menu

  Restaurant({
    required this.restaurantId,
    required this.name,
    required this.address,
    required this.categories,
    required this.rating,
    this.imageUrl, // Pode ser nulo
    required this.menu, // Lista de itens do menu
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      restaurantId: json['restaurantId'] ?? '', // Trata restaurantId nulo
      name: json['name'] ?? 'Nome não disponível', // Trata nome nulo
      address:
          json['address'] ?? 'Endereço não disponível', // Trata endereço nulo
      categories:
          List<String>.from(json['categories'] ?? []), // Trata categorias nulas
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0, // Trata rating nulo
      imageUrl: json['imageUrl'], // Permite nulo
      menu: (json['menu'] as List<dynamic>?)
              ?.map((item) => MenuItem.fromJson(item))
              .toList() ??
          [], // Inicializa o menu como uma lista vazia se for nulo
    );
  }
}
