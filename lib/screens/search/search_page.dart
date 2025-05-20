import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/user/home_page_user.dart';
import 'package:vizinhos_app/screens/user/user_account_page.dart';
import 'package:vizinhos_app/screens/model/restaurant.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart';
import 'package:vizinhos_app/screens/restaurant/store_detail_page.dart';
import 'package:vizinhos_app/services/app_theme.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Future<List<Restaurant>> _futureRestaurants;
  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

  final String lojaImageBaseUrl =
      "https://loja-profile-pictures.s3.amazonaws.com/";

  // Filtros e ordenação
  String _selectedTipoEntrega = 'Todos';
  String _selectedOrder = 'A-Z';
  final List<String> _tiposEntrega = ['Todos', 'Delivery', 'Retirada', 'Ambos'];
  final List<String> _orderOptions = ['A-Z', 'Z-A'];

  int _selectedIndex = 1; // Search is selected by default

  @override
  void initState() {
    super.initState();
    _futureRestaurants = _loadRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Restaurant>> _loadRestaurants() async {
    final storage = const FlutterSecureStorage();
    final email = await storage.read(key: 'email');
    if (email == null) throw Exception('Email não encontrado.');

    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetNearStores?email=$email');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final list = (data['lojas'] as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();
      setState(() {
        _allRestaurants = list;
        _filtered = list;
      });
      return list;
    } else {
      throw Exception('Falha ao buscar lojas');
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    List<Restaurant> filtered = _allRestaurants
        .where((r) => r.name.toLowerCase().contains(query))
        .toList();
    if (_selectedTipoEntrega != 'Todos') {
      filtered = filtered
          .where((r) => r.tipoEntrega
              .toLowerCase()
              .contains(_selectedTipoEntrega.toLowerCase()))
          .toList();
    }
    if (_selectedOrder == 'A-Z') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_selectedOrder == 'Z-A') {
      filtered.sort((a, b) => b.name.compareTo(a.name));
    }
    setState(() {
      _filtered = filtered;
    });
  }

  void _goToHomePage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
      (route) => false,
    );
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navegar para a página correspondente
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HomePage(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SearchPage(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
      case 2: // Orders
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final cpf = authProvider.cpf ?? '';
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => OrdersPage(cpf: cpf),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => UserAccountPage(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        break;
    }
  }

  Widget _buildNavIcon(
      IconData icon, String label, int index, BuildContext context) {
    bool isSelected = index == _selectedIndex;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color.fromARGB(255, 237, 236, 233)
                  : const Color.fromRGBO(59, 67, 81, 1).withOpacity(0.7),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? const Color.fromARGB(255, 21, 21, 21)
                    : const Color.fromRGBO(59, 67, 81, 1).withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._tiposEntrega.map((tipo) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(tipo),
                  selected: _selectedTipoEntrega == tipo,
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  onSelected: (selected) {
                    setState(() {
                      _selectedTipoEntrega = tipo;
                    });
                    _applyFilters();
                  },
                  labelStyle: TextStyle(
                    color: _selectedTipoEntrega == tipo
                        ? AppTheme.primaryColor
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedOrder,
            underline: Container(),
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
            items: _orderOptions
                .map((order) => DropdownMenuItem(
                      value: order,
                      child: Text(order),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedOrder = value;
                });
                _applyFilters();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant r) {
    String? displayImageUrl = r.imagemUrl;
    if ((displayImageUrl == null || displayImageUrl.isEmpty) &&
        r.imageString != null &&
        r.imageString!.isNotEmpty) {
      String imageName = r.imageString!;
      if (imageName.startsWith("/")) {
        imageName = imageName.substring(1);
      }
      displayImageUrl = lojaImageBaseUrl + imageName;
    }
    final isValidImage = displayImageUrl != null &&
        displayImageUrl.trim().toLowerCase().startsWith('https://');
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailPage(restaurantId: r.idEndereco),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 5,
        shadowColor: AppTheme.primaryColor.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isValidImage
                    ? Image.network(
                        displayImageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          'assets/images/default_restaurant_image.jpg',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/default_restaurant_image.jpg',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.name,
                            style: AppTheme.cardTitleStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            r.tipoEntrega,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.descricao,
                      style: AppTheme.secondaryTextStyle.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${r.logradouro}, ${r.numero}',
                            style: AppTheme.secondaryTextStyle
                                .copyWith(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (r.complemento.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          r.complemento,
                          style: AppTheme.secondaryTextStyle
                              .copyWith(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Entrega: ${r.tipoEntrega}',
                          style: AppTheme.secondaryTextStyle
                              .copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading:
              false, // Hide back button when navigating via navbar
          title: const Text('Buscar Lojas'),
          centerTitle: true,

          backgroundColor: AppTheme.primaryColor,
        ),
        body: FutureBuilder<List<Restaurant>>(
          future: _futureRestaurants,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erro: ${snapshot.error}',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar lojas...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildFilterChips(),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isNotEmpty
                      ? ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) =>
                              _buildRestaurantCard(_filtered[index]),
                        )
                      : Center(
                          child: Text(
                            'Nenhum restaurante encontrado.',
                            style: AppTheme.secondaryTextStyle.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFbbc2c),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavIcon(Icons.home, 'Início', 0, context),
                _buildNavIcon(Icons.search, 'Buscar', 1, context),
                _buildNavIcon(Icons.list, 'Pedidos', 2, context),
                _buildNavIcon(Icons.person, 'Conta', 3, context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
