import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/User/user_account_page.dart';
import 'package:vizinhos_app/screens/models/restaurant.dart';
import 'package:vizinhos_app/screens/Offers/offers_page.dart';
import 'package:vizinhos_app/screens/best/best_page.dart';
import 'package:vizinhos_app/screens/category/category_page.dart';
import 'package:vizinhos_app/screens/orders/orders_page.dart';
import 'package:vizinhos_app/screens/restaurant/restaurant_detail_page.dart';
import 'package:vizinhos_app/screens/search/search_page.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Restaurant>> futureRestaurants;
  Map<String, dynamic>? userInfo;

  @override
  void initState() {
    super.initState();
    futureRestaurants = fetchRestaurants();
    fetchUserInfo();
  }

  // Função que realiza o refresh dos dados do usuário e da lista de restaurantes
  Future<void> _refresh() async {
    await fetchUserInfo();
    setState(() {
      futureRestaurants = fetchRestaurants();
    });
  }

  Future<void> fetchUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      print("❌ Usuário não autenticado");
      return;
    }

    final accessToken = authProvider.accessToken;
    if (accessToken == null) {
      print("❌ Access Token não disponível");
      return;
    }
    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/user');

    try {
      print(
          "🔑 Token usado: ${accessToken.substring(0, 1071)}..."); // Log parcial do token

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      print("🔄 Resposta da API: ${response.statusCode}");
      print("📄 Corpo da resposta: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userInfo = data;
        });
      } else {
        final errorBody = json.decode(response.body);
        print("❌ Erro ${response.statusCode}: ${errorBody['error']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao carregar dados: ${errorBody['error']}')),
        );
      }
    } on http.ClientException catch (e) {
      print("❌ Erro de rede: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de rede: $e')),
      );
    } on FormatException catch (e) {
      print("❌ Erro ao decodificar JSON: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar dados')),
      );
    } catch (e) {
      print("❌ Erro inesperado: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    }
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    final response = await http.get(Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/list'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((restaurant) => Restaurant.fromJson(restaurant))
          .toList();
    } else {
      throw Exception('Falha ao carregar restaurantes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.black),
          onPressed: () {
            if (userInfo != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserAccountPage(userInfo: userInfo),
                ),
              );
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Endereço de Entrega',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    userInfo?['Address'] != null
                        ? '${userInfo!['Address']['Street']}'
                        : 'Carregando endereço...',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      // Envolvemos o FutureBuilder com um RefreshIndicator para permitir o pull-to-refresh
      body: RefreshIndicator(
        onRefresh: _refresh,
        // Utilizamos um FutureBuilder que, em cada estado, retorna um widget scrollável (ListView ou SingleChildScrollView)
        child: FutureBuilder<List<Restaurant>>(
          future: futureRestaurants,
          builder: (context, snapshot) {
            // Caso os dados estejam sendo carregados, exibimos um indicador de progresso
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height - kToolbarHeight,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              // Em caso de erro, exibimos uma mensagem
              return ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height - kToolbarHeight,
                    child: Center(child: Text('Erro: ${snapshot.error}')),
                  ),
                ],
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Caso não haja restaurantes, exibimos uma mensagem informando
              return ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height - kToolbarHeight,
                    child:
                        Center(child: Text('Nenhum restaurante encontrado.')),
                  ),
                ],
              );
            } else {
              List<Restaurant> restaurantes = snapshot.data!;
              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de busca
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SearchPage()),
                          );
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search here..',
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Ícones de categorias
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCategoryIcon(
                              context,
                              Icons.local_fire_department,
                              'Ofertas',
                              Colors.red,
                              OffersPage()),
                          _buildCategoryIcon(context, Icons.star, 'Melhores',
                              Colors.orange, BestPage()),
                          _buildCategoryIcon(
                              context,
                              Icons.card_giftcard,
                              'Cupons',
                              Colors.pink,
                              CategoryPage(categoryName: 'Cupons')),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Título da seção
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Todos os Restaurantes',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Lista de restaurantes
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: restaurantes.length,
                      itemBuilder: (context, index) {
                        return _buildRestaurantCard(
                          context: context,
                          restaurant: restaurantes[index],
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Procurar'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Conta'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Navega para a tela inicial, removendo as demais da pilha
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
                (route) => false,
              );
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrdersPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UserAccountPage(userInfo: userInfo)),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context, IconData icon, String label,
      Color color, Widget destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => destination,
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard({
    required BuildContext context,
    required Restaurant restaurant,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailPage(
              restaurant: restaurant,
            ),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          width: double.infinity,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: restaurant.imageUrl != null &&
                        restaurant.imageUrl!.isNotEmpty
                    ? Image.network(
                        restaurant.imageUrl!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultImage();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildImageLoader();
                        },
                      )
                    : _buildDefaultImage(),
              ),
              SizedBox(width: 16),
              // Informações do restaurante
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        restaurant.address,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            restaurant.rating.toString(),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildDefaultImage() {
  return Image.asset(
    'assets/images/default_restaurant_image.jpg',
    height: 80,
    width: 80,
    fit: BoxFit.cover,
  );
}

Widget _buildImageLoader() {
  return Container(
    height: 80,
    width: 80,
    alignment: Alignment.center,
    child: CircularProgressIndicator(),
  );
}
