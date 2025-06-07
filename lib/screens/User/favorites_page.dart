import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/provider/favorites_provider.dart';
import 'package:vizinhos_app/screens/store/store_detail_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<String>> _futureNearIds;
  final _storage = const FlutterSecureStorage();
  static const String _nearStoresUrl =
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetNearStores';
  static const String lojaImageBaseUrl =
      "https://loja-profile-pictures.s3.amazonaws.com/";

  @override
  void initState() {
    super.initState();
    _futureNearIds = _fetchNearStoreIds();
  }

  Future<List<String>> _fetchNearStoreIds() async {
    final email = await _storage.read(key: 'email');
    if (email == null) return [];
    final url = Uri.parse('$_nearStoresUrl?email=$email');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final lojas = data['lojas'] as List?;
      if (lojas != null) {
        return lojas
            .map((j) => (j as Map<String, dynamic>)['id_Endereco'] as String)
            .toList();
      }
    }
    return [];
  }

  // Função para buscar a nota da loja pela API GetReviewByStore
  Future<double> _fetchStoreRating(String idLoja) async {
    try {
      final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetReviewByStore?idLoja=$idLoja',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final media = data['media_avaliacoes'] ?? data['loja']?['media_avaliacoes'];
        // Se não houver avaliações ou média for zero, retorna 5.0
        if (media == null || (media is num && media <= 0)) {
          return 5.0;
        }
        if (media is num) {
          return media.toDouble();
        }
        return double.tryParse(media.toString()) ?? 5.0;
        
      }
    } catch (_) {}
    return 5.0;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFbbc2c);
    const primaryTextColor = Color(0xFF333333);
    const secondaryTextColor = Color(0xFF666666);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seus Vizinhos Favoritos'),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _futureNearIds,
        builder: (ctx, snapshotNear) {
          if (snapshotNear.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final nearIds = snapshotNear.data ?? [];
          return Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              final allFavorites = favoritesProvider.favoriteStores;
              // só lojas próximas
              final favoriteStores =
                  allFavorites.where((s) => nearIds.contains(s.idEndereco)).toList();

              if (favoriteStores.isEmpty) {
                return _buildEmptyState(context);
              }

              return Column(
                children: [
                  // Header com contador
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[50],
                    child: Row(
                      children: [
                        Icon(Icons.favorite, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          '${favoriteStores.length} ' 
                          '${favoriteStores.length == 1 ? 'loja favorita' : 'lojas favoritas'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista de favoritos
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favoriteStores.length,
                      itemBuilder: (context, index) {
                        final store = favoriteStores[index];
                        // lógica de imagem: usa imagem da API ou base S3
                        String? imageUrl = store.imagemUrl;
                        if (imageUrl == null || imageUrl.isEmpty) {
                          if (store.imageString != null && store.imageString!.isNotEmpty) {
                            var img = store.imageString!;
                            if (img.startsWith('/')) img = img.substring(1);
                            imageUrl = lojaImageBaseUrl + img;
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RestaurantDetailPage(
                                          restaurantId: store.idEndereco),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: [
                                // Imagem da loja
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                    image: imageUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: imageUrl == null
                                      ? _buildEmptyState(context)
                                      : null,
                                ),
                                // Informações da loja
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              store.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTextColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // Avaliação dinâmica via API
                                          FutureBuilder<double>(
                                            future: _fetchStoreRating(store.idEndereco),
                                            builder: (context, snapshot) {
                                              final rating = snapshot.hasData ? snapshot.data! : 5.0;
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      rating.toStringAsFixed(2),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.amber[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        store.descricao,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: secondaryTextColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_shipping,
                                            size: 16,
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            store.tipoEntrega,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${store.logradouro}, ${store.numero}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    const primaryColor = Color(0xFFFbbc2c);
    const primaryTextColor = Color(0xFF333333);
    const secondaryTextColor = Color(0xFF666666);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 80,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma loja favorita',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Você ainda não favoritou nenhuma loja.\nNavegue pelas lojas e toque no ❤️ para adicioná-las aos seus favoritos!',
              style: TextStyle(
                fontSize: 16,
                color: secondaryTextColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.search),
              label: const Text('Explorar Lojas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
