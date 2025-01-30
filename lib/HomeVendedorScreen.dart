// lib/screens/vendedor/home_vendedor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

class HomeVendedorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Painel do Vendedor'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {}, // Navegar para notificações
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text('Nome do Vendedor'),
              accountEmail: Text('vendedor@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.inventory),
              title: Text('Produtos'),
              onTap: () {}, // Navegar para gestão de produtos
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text('Pedidos'),
              onTap: () {}, // Navegar para pedidos
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sair'),
              onTap: () {
                // Adicione lógica de logout
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visão Geral',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Pedidos Hoje', '15', Colors.blue),
                _buildStatCard('Vendas Mensais', 'R\$ 8.240', Colors.green),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildOrderItem('Pedido #1234', 'Em processamento'),
                  _buildOrderItem('Pedido #1235', 'Enviado'),
                  _buildOrderItem('Pedido #1236', 'Entregue'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // Adicionar novo produto
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(String orderId, String status) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(orderId),
        subtitle: Text('Status: $status'),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {}, // Mostrar detalhes do pedido
      ),
    );
  }
}
