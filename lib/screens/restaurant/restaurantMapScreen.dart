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

  @override
  void initState() {
    super.initState();

    // Marcador para a localização do usuário (em azul)
    _markers.add(Marker(
      markerId: const MarkerId('userLocation'),
      position: LatLng(widget.userLatitude, widget.userLongitude),
      infoWindow: const InfoWindow(title: "Você está aqui"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));

    // Marcadores para os restaurantes (em vermelho) com callback para navegar à página de detalhes
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
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final CameraPosition initialCameraPosition = CameraPosition(
      target: LatLng(widget.userLatitude, widget.userLongitude),
      zoom: 14,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de Restaurantes")),
      body: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
      ),
    );
  }
}
