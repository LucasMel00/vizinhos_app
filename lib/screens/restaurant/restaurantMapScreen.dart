import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vizinhos_app/screens/models/restaurant.dart';
import 'package:vizinhos_app/screens/restaurant/restaurant_detail_page.dart';

class RestaurantMapScreen extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;
  final List<Restaurant> restaurants;

  const RestaurantMapScreen({
    Key? key,
    required this.userLatitude,
    required this.userLongitude,
    required this.restaurants,
  }) : super(key: key);

  @override
  _RestaurantMapScreenState createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  bool _isSatelliteView = false;

  @override
  void initState() {
    super.initState();

    // Marcador para a localização do usuário (em verde)
    _markers.add(Marker(
      markerId: const MarkerId('userLocation'),
      position: LatLng(widget.userLatitude, widget.userLongitude),
      infoWindow: const InfoWindow(title: "Você está aqui"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));

    // Marcadores para os restaurantes (em verde escuro) com callback para navegar à página de detalhes
    for (var restaurant in widget.restaurants) {
      if (restaurant.x != null && restaurant.y != null) {
        _markers.add(Marker(
          markerId: MarkerId(restaurant.restaurantId),
          position: LatLng(restaurant.x!, restaurant.y!),
          infoWindow: InfoWindow(
            title: restaurant.name,
            snippet: restaurant.distance != null
                ? '${restaurant.distance!.toStringAsFixed(0)} m'
                : '',
          ),
          onTap: () {
            // Quando o marcador for clicado, navega para a página de detalhes do restaurante
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantDetailPage(restaurant: restaurant),
              ),
            );
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
      }
    }
  }

  void _toggleMapType() {
    setState(() {
      _isSatelliteView = !_isSatelliteView;
    });
  }

  void _centerMapOnUser() {
    mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(widget.userLatitude, widget.userLongitude),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CameraPosition initialCameraPosition = CameraPosition(
      target: LatLng(widget.userLatitude, widget.userLongitude),
      zoom: 14,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de Restaurantes"),
        backgroundColor: Colors.green, // Tema verde
        actions: [
          IconButton(
            icon: Icon(_isSatelliteView ? Icons.map : Icons.satellite),
            onPressed: _toggleMapType,
            tooltip: _isSatelliteView ? "Modo Mapa" : "Modo Satélite",
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        markers: _markers,
        mapType: _isSatelliteView ? MapType.satellite : MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _centerMapOnUser,
            backgroundColor: Colors.green, // Tema verde
            child: Icon(Icons.my_location, color: Colors.white),
            tooltip: "Centralizar no usuário",
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _toggleMapType,
            backgroundColor: Colors.green, // Tema verde
            child: Icon(
              _isSatelliteView ? Icons.map : Icons.satellite,
              color: Colors.white,
            ),
            tooltip: _isSatelliteView ? "Modo Mapa" : "Modo Satélite",
          ),
        ],
      ),
    );
  }
}