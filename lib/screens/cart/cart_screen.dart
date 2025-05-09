import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/model/cart_item.dart';
import 'package:vizinhos_app/screens/provider/cart_provider.dart';
import 'package:vizinhos_app/screens/model/cart_item.dart';
import 'package:intl/intl.dart';

import '../model/cart_item.dart';

// Define colors (matching other screens)
const Color primaryColor = Color(0xFFFbbc2c);
const Color secondaryColor = Color(0xFF3B4351);
const Color backgroundColor = Color(0xFFF5F5F5);
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF333333);
const Color secondaryTextColor = Color(0xFF666666);
const Color successColor = Color(0xFF2E7D32);

class CartScreen extends StatelessWidget {
  static const routeName = '/cart'; // Define route name for navigation

  const CartScreen({Key? key}) : super(key: key);

  String _formatCurrency(num? value) {
    if (value == null) return "N/A";
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Meu Carrinho'),
        backgroundColor: primaryColor,
        elevation: 1,
        actions: [
          // Optional: Clear cart button
          if (cart.itemCount > 0)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined),
              tooltip: 'Limpar Carrinho',
              onPressed: () {
                // Show confirmation dialog before clearing
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Confirmar'),
                    content: Text('Tem certeza que deseja limpar o carrinho?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Não'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Sim'),
                        onPressed: () {
                          Provider.of<CartProvider>(context, listen: false).clearCart();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cart.itemCount == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'Seu carrinho está vazio.',
                    style: TextStyle(fontSize: 18, color: secondaryTextColor),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Adicione produtos para vê-los aqui.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : Column(
              children: <Widget>[
                // List of Cart Items
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      // Use values.toList() to access items by index
                      final cartItem = cart.items.values.toList()[i];
                      final productId = cart.items.keys.toList()[i];
                      return _buildCartItemCard(context, cartItem as CartItem, productId);
                    },
                  ),
                ),
                // Total Amount and Checkout Button Area
                _buildTotalSection(context, cart),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem cartItem, String productId) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final productImageUrl = cartItem.product.imagemUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: productImageUrl != null && productImageUrl.isNotEmpty
                  ? Image.network(
                      productImageUrl,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultProductImage(height: 50, width: 50),
                    )
                  : _buildDefaultProductImage(height: 50, width: 50),
            ),
            const SizedBox(width: 12),
            // Product Name and Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    cartItem.product.nome,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(cartItem.product.valorVenda),
                    style: const TextStyle(fontSize: 13, color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Quantity Controls
            Row(
              children: <Widget>[
                _buildQuantityButton(
                  context,
                  icon: Icons.remove,
                  onPressed: () => cartProvider.removeSingleItem(productId),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${cartItem.quantity}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                ),
                _buildQuantityButton(
                  context,
                  icon: Icons.add,
                  // Disable add button if max quantity reached (using provider logic)
                  onPressed: () => cartProvider.addItem(cartItem.product),
                ),
              ],
            ),
            // Remove Item Button
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[700], size: 20),
              tooltip: 'Remover Item',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed: () => cartProvider.removeItem(productId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(BuildContext context, {required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.grey[200], // Button background
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(icon, size: 16, color: secondaryTextColor),
        ),
      ),
    );
  }

  Widget _buildTotalSection(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 5,
            offset: const Offset(0, -2), // Shadow on top
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
              Text(
                _formatCurrency(cart.totalAmount),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: successColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Finalizar Pedido'),
              onPressed: () {
                // Placeholder for checkout action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade de checkout ainda não implementada.')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for default product image (similar to detail page)
  Widget _buildDefaultProductImage({double height = 50, double width = 50}) {
     return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, size: 24, color: Colors.grey[400]),
      ),
    );
  }
}

