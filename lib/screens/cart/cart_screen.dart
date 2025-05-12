import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/model/cart_item.dart';
import 'package:vizinhos_app/screens/payment/payment_sucess_screen.dart';
import 'package:vizinhos_app/screens/provider/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

const Color primaryColor = Color(0xFFFbbc2c);
const Color secondaryColor = Color(0xFF3B4351);
const Color backgroundColor = Color(0xFFF5F5F5);
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF333333);
const Color secondaryTextColor = Color(0xFF666666);
const Color successColor = Color(0xFF2E7D32);

class CartScreen extends StatelessWidget {
  static const routeName = '/cart';

  const CartScreen({Key? key}) : super(key: key);

  String _formatCurrency(num? value) {
    if (value == null) return "N/A";
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return format.format(value);
  }

  // Adicione este método à classe CartScreen para debug
  void _debugPrintCartContents(List<CartItem> items) {
    debugPrint('=== DEBUG: Conteúdo do Carrinho ===');
    for (var item in items) {
      debugPrint('Produto: ${item.product.nome}');
      debugPrint('ID: ${item.product.id}');
      debugPrint('Quantidade: ${item.quantity}');
      debugPrint('Preço Unitário: ${item.product.valorVenda}');
      debugPrint('---------------------');
    }
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
          if (cart.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Limpar Carrinho',
              onPressed: () => _showClearCartDialog(context),
            ),
        ],
      ),
      body: cart.itemCount == 0
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(child: _buildCartItemsList(cart)),
                _buildTotalSection(context, cart),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart_outlined,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Seu carrinho está vazio.',
            style: TextStyle(fontSize: 18, color: secondaryTextColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione produtos para vê-los aqui.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList(CartProvider cart) {
    return ListView.builder(
      itemCount: cart.items.length,
      itemBuilder: (ctx, i) {
        final cartItem = cart.items.values.toList()[i];
        final productId = cart.items.keys.toList()[i];
        return _buildCartItemCard(ctx, cartItem, productId);
      },
    );
  }

  Widget _buildCartItemCard(
      BuildContext context, CartItem cartItem, String productId) {
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
          children: [
            _buildProductImage(productImageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.product.nome,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(cartItem.product.valorVenda),
                    style: const TextStyle(
                        fontSize: 13, color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              children: [
                _buildQuantityButton(
                  context,
                  icon: Icons.remove,
                  onPressed: () => cartProvider.removeSingleItem(productId),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${cartItem.quantity}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor),
                  ),
                ),
                _buildQuantityButton(
                  context,
                  icon: Icons.add,
                  onPressed: () => cartProvider.addItem(cartItem.product),
                ),
              ],
            ),
            IconButton(
              icon:
                  Icon(Icons.delete_outline, color: Colors.red[700], size: 20),
              onPressed: () => cartProvider.removeItem(productId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String? productImageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: productImageUrl != null && productImageUrl.isNotEmpty
          ? Image.network(
              productImageUrl,
              height: 50,
              width: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildDefaultProductImage(),
            )
          : _buildDefaultProductImage(),
    );
  }

  Widget _buildQuantityButton(BuildContext context,
      {required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.grey[200],
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
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor),
              ),
              Text(
                _formatCurrency(cart.totalAmount),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: successColor),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _confirmAndProcessPayment(context),
              child: const Text('Finalizar Pedido'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultProductImage() {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined,
            size: 24, color: Colors.grey[400]),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('Tem certeza que deseja limpar o carrinho?'),
        actions: [
          TextButton(
            child: const Text('Não'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Sim'),
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndProcessPayment(BuildContext context) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Pagamento'),
        content: Text(
            'Confirmar pagamento de ${_formatCurrency(cart.totalAmount)}?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Confirmar'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Processando pagamento...')),
        );

        final paymentResult = await _processPayment(
          context: context,
          total: cart.totalAmount,
          items: cart.itemsList,
        );

        // Verifica se temos dados do PIX (qr_code ou qr_code_base64)
        final hasPixData = paymentResult['qr_code'] != null ||
            paymentResult['qr_code_base64'] != null ||
            paymentResult['point_of_interaction'] != null;

        if (hasPixData) {
          debugPrint('Pagamento processado - QR Code gerado com sucesso');
          cart.clearCart();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                paymentData: paymentResult,
                totalAmount: cart.totalAmount,
              ),
            ),
          );
        } else {
          throw Exception(
              paymentResult['message'] ?? 'Falha ao gerar pagamento');
        }
      } catch (e) {
        debugPrint('Erro no processamento: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no pagamento: ${e.toString()}')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _processPayment({
    required BuildContext context,
    required double total,
    required List<CartItem> items,
  }) async {
    const apiUrl =
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/ProcessPixPayment';

    // Debug 1: Verificar conteúdo do carrinho
    _debugPrintCartContents(items);
    debugPrint('Total a pagar: $total');

    final storage = const FlutterSecureStorage();
    final email = await storage.read(key: 'email');

    // Debug 2: Verificar email obtido
    debugPrint('Email obtido do storage: $email');

    if (email == null) {
      debugPrint('Erro: Email não encontrado no storage');
      throw Exception('Email não encontrado.');
    }

    // Preparar payload com verificação
    final payload = {
      'email': email,
      'preco': total,
      'products': items.map((item) {
        final productData = {
          'id': item.product.id,
          'title': item.product.nome,
          'description': item.product.descricao ?? 'Sem descrição',
          'quantity': item.quantity,
          'unit_price': item.product.valorVenda,
        };

        // Debug 3: Verificar cada produto no payload
        debugPrint('Produto no payload: ${productData['title']}');
        return productData;
      }).toList(),
    };

    // Debug 4: Verificar payload completo
    debugPrint('Payload completo: ${jsonEncode(payload)}');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      // Debug 5: Verificar resposta da API
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Resposta da API: ${response.body}');

      if (response.statusCode != 200) {
        debugPrint('Erro na API - Status: ${response.statusCode}');
        throw Exception('Erro na API: ${response.statusCode}');
      }

      final responseData = json.decode(response.body);

      // Debug 6: Verificar status do pagamento
      debugPrint('Status do pagamento: ${responseData['status']}');

      return responseData;
    } catch (e) {
      debugPrint('Erro durante o processamento: $e');
      rethrow;
    }
  }
}
