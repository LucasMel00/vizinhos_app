import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vizinhos_app/screens/model/restaurant.dart'; // Importe seu modelo Restaurant

// Coloque a função geocodeAddress aqui ou em um arquivo de utilitários
Future<LatLng?> geocodeAddress(String address) async {
  const String apiKey = 'AIzaSyAYUEqd6cq8cTjj6GZxYze32HPjL2xnAfc'; // <<< COLOQUE SUA CHAVE AQUI
  final String encodedAddress = Uri.encodeComponent(address);
  final String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      } else {
        print('Erro de Geocoding para "$address": ${data['status']}');
        return null;
      }
    } else {
      print('Erro na chamada HTTP Geocoding: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Exceção ao geocodificar "$address": $e');
    return null;
  }
}

class MapScreen extends StatefulWidget {
  final String userEmail;

  const MapScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  LatLng? _userLocation;
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Buscar informações do usuário e geocodificar
      final userInfo = await _fetchUserInfo(widget.userEmail);
      if (userInfo != null && userInfo['endereco'] != null) {
        final endereco = userInfo['endereco'];
        String userAddress = '${endereco['logradouro']}, ${endereco['numero']}, ${endereco['cep']}, São Paulo, SP, Brasil';
        _userLocation = await geocodeAddress(userAddress);
        if (_userLocation != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId("userLocation"),
              position: _userLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Usuário em Azul
              infoWindow: const InfoWindow(title: "Você está aqui (Endereço Cadastrado)"),
              zIndex: 2, // Maior zIndex para ficar em cima
            ),
          );
        } else {
           print("Não foi possível geocodificar o endereço do usuário.");
        }
      } else {
         print("Endereço do usuário não encontrado.");
      }

      // 2. Buscar lojas e geocodificar
      final restaurants = await _fetchRestaurants(widget.userEmail);
      for (var restaurant in restaurants) {
        String storeAddress = '${restaurant.logradouro}, ${restaurant.numero}, ${restaurant.cep}, São Paulo, SP, Brasil';
        LatLng? storeCoords = await geocodeAddress(storeAddress);

        if (storeCoords != null) {
          _markers.add(
            Marker(
              markerId: MarkerId(restaurant.idEndereco),
              position: storeCoords,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Lojas em Vermelho
              infoWindow: InfoWindow(title: restaurant.name),
              zIndex: 1,
            ),
          );
        } else {
          print("Não foi possível geocodificar a loja: ${restaurant.name}");
        }
      }

      // 3. Atualizar estado
       if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_userLocation == null && _markers.length <= 1) { // <=1 porque pode ter o do usuário falhado
            _errorMessage = "Não foi possível carregar as localizações. Verifique sua conexão e tente novamente.";
        }
      });

    } catch (e) {
       if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Ocorreu um erro: ${e.toString()}";
      });
      print("Erro ao carregar dados do mapa: $e");
    }
  }

  // Função para buscar usuário (adaptada da HomePage)
  Future<Map<String, dynamic>?> _fetchUserInfo(String email) async {
     final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetUserByEmail?email=$email',
    );
     try {
       final response = await http.get(url);
       if(response.statusCode == 200) {
         return json.decode(response.body);
       }
     } catch(e) {
       print("Erro fetchUserInfo MapScreen: $e");
     }
     return null;
  }

  // Função para buscar restaurantes (adaptada da HomePage)
  Future<List<Restaurant>> _fetchRestaurants(String email) async {
      final url = Uri.parse(
      'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetNearStores?email=$email',
    );
     try {
       final response = await http.get(url);
       if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          List<dynamic> lojasJson = (jsonResponse is Map &&
                  jsonResponse.containsKey('lojas') &&
                  jsonResponse['lojas'] is List)
              ? jsonResponse['lojas']
              : [];
          return lojasJson.map((json) => Restaurant.fromJson(json)).toList();
        }
     } catch (e) {
       print('[ERRO] fetchRestaurants MapScreen: $e');
     }
      return [];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lojas no Mapa"),
        backgroundColor: const Color(0xFFFbbc2c), // Use sua cor primária
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFbbc2c)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(_errorMessage!, textAlign: TextAlign.center),
                  ),
                )
              : _userLocation == null // Se não conseguiu nem a localização do usuário, mostra erro
                  ? const Center(child: Text("Não foi possível obter a localização inicial."))
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _userLocation!, // Centraliza no usuário
                        zoom: 13, // Zoom inicial
                      ),
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      myLocationButtonEnabled: true, // Mostra botão para localização atual (requer geolocator)
                      myLocationEnabled: true, // Mostra ponto azul (requer geolocator e permissões)
                    ),
    );
  }
}