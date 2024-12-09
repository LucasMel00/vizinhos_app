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
      name: json['name'],
      itemId: json['itemId'],
      price: (json['price'] as num).toDouble(),
    );
  }
}

class Restaurant {
  final String restaurantId;
  final String name;
  final String address;
  final List<String> categories;
  final String imageUrl;
  final double rating;
  final List<MenuItem> menu;

  Restaurant({
    required this.restaurantId,
    required this.name,
    required this.address,
    required this.categories,
    required this.imageUrl,
    required this.rating,
    required this.menu,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    var menuList = json['menu'] as List;
    List<MenuItem> menuItems =
        menuList.map((item) => MenuItem.fromJson(item)).toList();

    return Restaurant(
      restaurantId: json['restaurantId'],
      name: json['name'],
      address: json['address'],
      categories: List<String>.from(json['categories']),
      imageUrl: json['imageUrl'],
      rating: (json['rating'] as num).toDouble(),
      menu: menuItems,
    );
  }
}
