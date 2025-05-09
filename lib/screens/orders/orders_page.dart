import 'package:flutter/material.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart';

class OrdersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Lista de pedidos de exemplo
    final List<Map<String, dynamic>> orders = [
      {
        'id': '001',
        'restaurant': 'Seu Zé',
        'status': 'Entregue',
        'date': '10/04/2024',
        'total': 'R\$ 45.90',
      },
      {
        'id': '002',
        'restaurant': 'Padaria Central',
        'status': 'Em andamento',
        'date': '12/04/2024',
        'total': 'R\$ 25.50',
      },
      // Adicione mais pedidos conforme necessário
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
             Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: orders.isEmpty
            ? Center(
                child: Text(
                  'Você ainda não fez nenhum pedido.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.receipt_long, color: Colors.green),
                      title: Text('Pedido #${order['id']} - ${order['restaurant']}'),
                      subtitle: Text(
                          '${order['status']} • ${order['date']}'),
                      trailing: Text(
                        order['total'],
                        style: TextStyle(
                            color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        // Navegar para detalhes do pedido, se aplicável
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
