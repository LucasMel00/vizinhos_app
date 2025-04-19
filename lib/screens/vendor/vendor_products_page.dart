import 'package:flutter/material.dart';
import 'package:vizinhos_app/screens/vendor/vendor_create_product_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_edit_product_page.dart';

final primaryColor = const Color(0xFFFbbc2c);

class Product {
  final String name;
  final String description;
  final int quantity;
  final double price;
  final bool available;
  final String category;

  Product({
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    required this.available,
    required this.category,
  });
}

class VendorProductsPage extends StatelessWidget {
  final List<Product> products = [
    Product(
      name: 'Bolo',
      description: 'Bolo caseiro de chocolate com cobertura...',
      quantity: 20,
      price: 15.0,
      available: true,
      category: 'Doce',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Produtos',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: primaryColor,
            height: 2,
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0.5,
            color: Color(0xFFF9F5ED), // Creme suave que complementa o amarelo
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Imagem placeholder
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.image, color: Colors.grey[400]),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              p.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: primaryColor, size: 20),
                        onPressed: () {
                          // Navegar para a tela de edição do produto
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProductScreen(),
                            ),
                          );
                        },
                        tooltip: 'Editar',
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Quantidade em estoque: ${p.quantity}',
                        style: TextStyle(fontSize: 13),
                      ),
                      Spacer(),
                      Text(
                        'R\$${p.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Disponível no catálogo',
                        style: TextStyle(fontSize: 13),
                      ),
                      Spacer(),
                      Switch(
                        value: p.available,
                        onChanged: (_) {},
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      p.category,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Navegar para a tela de adição de produto
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateProductScreen(),
            ),
          );
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
