import 'package:flutter/material.dart';

class VendorAccountPage extends StatelessWidget {
  final Map<String, dynamic> userInfo;

  const VendorAccountPage({Key? key, required this.userInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Faz o cast para Map<String, dynamic> caso sellerProfile exista
    final sellerProfileRaw = userInfo['sellerProfile'];
    final sellerProfile = sellerProfileRaw is Map
        ? (sellerProfileRaw as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    // Tenta obter o nome da loja utilizando as chaves 'storeName', 'nomeLoja' ou 'name'
    final storeName = sellerProfile['storeName'] ??
        sellerProfile['nomeLoja'] ??
        sellerProfile['name'] ??
        'Painel do Vendedor';

    // Recupera as categorias utilizando 'categories' ou 'categorias'
    final categorias = List<String>.from(
      sellerProfile['categories'] ?? sellerProfile['categorias'] ?? [],
    );
    final primaryColor = const Color(0xFF2ECC71);
    final accentColor = const Color(0xFF27AE60);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          storeName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 5,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            onPressed: () => _navigateToProducts(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context, primaryColor, accentColor, categorias),
      body: _buildBody(context, sellerProfile, primaryColor, accentColor),
    );
  }

  void _navigateToProducts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductsPage()),
    );
  }

  Widget _buildDrawer(
      BuildContext context, Color primaryColor, Color accentColor, List<String> categorias) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(20),
              ),
            ),
            child: UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              accountName: Text(
                userInfo['Name'] ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                userInfo['Email'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.store, size: 40, color: primaryColor),
              ),
            ),
          ),
          _drawerItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () {},
            accentColor: accentColor,
          ),
          _drawerItem(
            icon: Icons.shopping_bag,
            label: 'Produtos',
            onTap: () => _navigateToProducts(context),
            accentColor: accentColor,
          ),
          _drawerItem(
            icon: Icons.receipt,
            label: 'Pedidos',
            onTap: () {},
            accentColor: accentColor,
          ),
          const Divider(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Icon(Icons.category, color: accentColor),
              title: const Text(
                'Categorias',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                categorias.join(', '),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          _drawerItem(
            icon: Icons.settings,
            label: 'Configurações',
            onTap: () {},
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: accentColor),
      title: Text(
        label,
        style: TextStyle(color: Colors.grey[800], fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBody(
      BuildContext context, Map<String, dynamic> sellerProfile, Color primaryColor, Color accentColor) {
    final storeName = sellerProfile['storeName'] ??
        sellerProfile['nomeLoja'] ??
        sellerProfile['name'] ??
        '';
    final categories = (sellerProfile['categories'] as List?) ??
        sellerProfile['categorias'] ??
        [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Informações da Loja', Icons.storefront, accentColor),
          const SizedBox(height: 20),
          _infoCard(
            title: 'Nome da Loja',
            value: storeName,
            accentColor: accentColor,
            onEdit: () {},
          ),
          _infoCard(
            title: 'Categorias',
            value: categories.join(', '),
            accentColor: accentColor,
            onEdit: () {},
          ),
          const SizedBox(height: 30),
          _sectionHeader('Ações Rápidas', Icons.flash_on, accentColor),
          const SizedBox(height: 15),
          _actionButtons(primaryColor, context),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required Color accentColor,
    required VoidCallback onEdit,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: accentColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: accentColor),
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: Colors.grey[800], fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons(Color primaryColor, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'Adicionar Produto',
            icon: Icons.add,
            color: primaryColor,
            onPressed: () => _navigateToAddProduct(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            label: 'Gerenciar Estoque',
            icon: Icons.inventory,
            color: primaryColor,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    // Implementar navegação para adicionar produto
  }
}

class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Produtos'),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.shopping_bag),
          title: Text('Produto ${index + 1}'),
          subtitle: const Text('R\$ 99,99'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {},
      ),
    );
  }
}
