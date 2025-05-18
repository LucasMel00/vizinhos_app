import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/model/cart_item.dart';
import 'package:vizinhos_app/screens/payment/payment_sucess_screen.dart';
import 'package:vizinhos_app/screens/provider/cart_provider.dart';
// Adicione o import do AuthProvider quando estiver disponível
// import 'package:vizinhos_app/screens/provider/auth_provider.dart';
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

  // Método para obter o tipo de entrega da loja
  Future<String> _getDeliveryType(int storeId) async {
    // Aqui você deve implementar a lógica para obter o tipo de entrega da loja
    // Isso pode ser feito através de uma chamada à API ou de dados já carregados
    
    // Por enquanto, retornamos um valor padrão
    return 'Retirada';
    
    // Exemplo de implementação futura:
    // try {
    //   final response = await http.get(
    //     Uri.parse('https://sua-api.com/stores/$storeId'),
    //     headers: {'Content-Type': 'application/json'},
    //   );
    //
    //   if (response.statusCode == 200) {
    //     final storeData = json.decode(response.body);
    //     return storeData['delivery_type'] ?? 'Retirada';
    //   }
    // } catch (e) {
    //   debugPrint('Erro ao obter tipo de entrega: $e');
    // }
    // return 'Retirada';
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

        // Obter dados do usuário
        final storage = const FlutterSecureStorage();
        final email = await storage.read(key: 'email') ?? '';
        
        // Tentar obter CPF do AuthProvider quando estiver disponível
        String? cpf;
        
        // Comentado até que o AuthProvider esteja disponível
        // try {
        //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
        //   cpf = authProvider.user?.cpf;
        // } catch (e) {
        //   debugPrint('AuthProvider não disponível: $e');
        // }
        
        // Se não conseguir do AuthProvider, tenta do storage
        if (cpf == null || cpf.isEmpty) {
          cpf = await storage.read(key: 'cpf');
        }
        
        if (email.isEmpty) {
          throw Exception('Email não encontrado. Faça login novamente.');
        }

        // Obter o ID da loja a partir do carrinho
        final storeId = int.tryParse(cart.currentStoreId ?? '0') ?? 0;
        if (storeId <= 0) {
          throw Exception('ID da loja inválido.');
        }
        
        // Obter o tipo de entrega da loja
        final deliveryType = await _getDeliveryType(storeId);

        // Preparar dados do pedido usando o método do provider
        final orderData = cart.prepareOrderData(
          tipoEntrega: deliveryType,
          idLoja: storeId,
          userCpf: cpf,
        );

        // Processar pagamento com a nova API
        final orderResponse = await _processOrderAndPayment(
          orderData: orderData,
          email: email,
        );

        // Verificar se temos dados do PIX
        final hasPixData = orderResponse['pagamento']?['qr_code'] != null ||
            orderResponse['pagamento']?['qr_code_base64'] != null;

        if (hasPixData) {
          debugPrint('Pedido e pagamento processados com sucesso');
          cart.clearCart();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                orderData: orderResponse,
                totalAmount: cart.totalAmount,
              ),
            ),
          );
        } else {
          throw Exception(
              orderResponse['message'] ?? 'Falha ao gerar pagamento');
        }
      } catch (e) {
        debugPrint('Erro no processamento: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no pagamento: ${e.toString()}')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _processOrderAndPayment({
    required Map<String, dynamic> orderData,
    required String email,
  }) async {
    const apiUrl =
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/CreateOrder';

    // Debug: Verificar payload
    debugPrint('Payload do pedido: ${jsonEncode(orderData)}');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      // Debug: Verificar resposta da API
      debugPrint('Request da  API: ${response.request}');
            debugPrint('Status code: ${response.statusCode}');
      debugPrint('Resposta da API: ${response.body}');

      if (response.statusCode != 200) {
        debugPrint('Erro na API - Status: ${response.statusCode}');
        throw Exception('Erro na API: ${response.statusCode}');
      }

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      debugPrint('Erro durante o processamento: $e');
      rethrow;
    }
  }
}
