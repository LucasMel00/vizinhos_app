import 'package:flutter/material.dart';

class VendorAccountPage extends StatelessWidget {
  final Map<String, dynamic> userInfo;

  const VendorAccountPage({Key? key, required this.userInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sellerProfile = userInfo['sellerProfile'] ?? {};
    final categorias = List<String>.from(sellerProfile['categorias'] ?? []);
    final primaryColor = Color(0xFF2ECC71); // Verde mais vibrante
    final accentColor = Color(0xFF27AE60); // Verde mais escuro para detalhes

    return Scaffold(
      appBar: AppBar(
        title: Text(sellerProfile['nomeLoja'] ?? 'Painel do Vendedor',
            style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 5,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context, primaryColor, accentColor, categorias),
      body: _buildBody(context, sellerProfile, primaryColor, accentColor),
    );
  }

  Widget _buildDrawer(BuildContext context, Color primaryColor,
      Color accentColor, List<String> categorias) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20),
              ),
            ),
            child: UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              accountName: Text(userInfo['Name'] ?? '',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              accountEmail:
                  Text(userInfo['Email'] ?? '', style: TextStyle(fontSize: 14)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.store, size: 40, color: primaryColor),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: accentColor),
            title: Text('Dashboard',
                style: TextStyle(color: Colors.grey[800], fontSize: 16)),
            onTap: () {},
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Icon(Icons.category, color: accentColor),
              title: Text('Categorias',
                  style: TextStyle(
                      color: accentColor, fontWeight: FontWeight.bold)),
              subtitle: Text(categorias.join(', '),
                  style: TextStyle(color: Colors.grey[600])),
            ),
          ),
          // ... outros itens do drawer
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> sellerProfile,
      Color primaryColor, Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.storefront, color: accentColor, size: 30),
                SizedBox(width: 15),
                Text('Informações da Loja',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: accentColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(height: 25),
          _buildInfoCard(
            context: context,
            title: 'Nome da Loja',
            value: sellerProfile['nomeLoja'] ?? '',
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
          _buildInfoCard(
            context: context,
            title: 'Categorias',
            value: (sellerProfile['categorias'] as List?)?.join(', ') ?? '',
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
          // ... outros cards
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String value,
    required Color primaryColor,
    required Color accentColor,
  }) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(height: 8),
            Text(value,
                style: TextStyle(color: Colors.grey[800], fontSize: 15)),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(Icons.edit, color: accentColor, size: 18),
                label: Text('Editar', style: TextStyle(color: accentColor)),
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: accentColor.withOpacity(0.1),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
