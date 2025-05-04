import 'package:vizinhos_app/screens/model/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => (product.valorVenda ?? 0) * quantity;
}

