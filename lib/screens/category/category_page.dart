import 'package:flutter/material.dart';

class CategoryPage extends StatelessWidget {
  final String categoryName;

  CategoryPage({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    // Aqui você pode buscar e exibir os itens da categoria
    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryName'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Exemplo de lista de itens da categoria
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Substitua pelo número real de itens
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.fastfood, color: Colors.green),
                    title: Text('Item ${index + 1} da $categoryName'),
                    subtitle: Text('Descrição do item'),
                    onTap: () {
                      // Navegar para detalhes do item, se aplicável
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
