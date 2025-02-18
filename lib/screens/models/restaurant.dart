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
      name: json['name'] ?? 'Item sem nome',
      itemId: json['itemId'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  get description => null;
}

class Restaurant {
  final String restaurantId;
  final String name;
  final List<String> categories;
  final double rating;
  final String? imageUrl;
  final List<MenuItem> menu;
  final double? distance;
  final double? x; // latitude (ou use 'latitude')
  final double? y; // longitude (ou use 'longitude')

  Restaurant({
    required this.restaurantId,
    required this.name,
    required this.categories,
    required this.rating,
    this.imageUrl,
    required this.menu,
    this.distance,
    this.x,
    this.y,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      restaurantId: json['restaurantId'] ?? '',
      name: json['name'] ?? 'Nome não disponível',
      categories: List<String>.from(json['categories'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
      menu: (json['menu'] as List<dynamic>?)
              ?.map((item) => MenuItem.fromJson(item))
              .toList() ??
          [],
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : null,
      x: json['x'] != null ? double.tryParse(json['x'].toString()) : null,
      y: json['y'] != null ? double.tryParse(json['y'].toString()) : null,
    );
  }
}
