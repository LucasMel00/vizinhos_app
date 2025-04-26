import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:vizinhos_app/screens/model/restaurant.dart';
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
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  bool _isSatelliteView = false;

  @override
  void initState() {
    super.initState();
    _addUserMarker();
    _addRestaurantMarkers();
  }

  void _addUserMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('userLocation'),
        position: LatLng(widget.userLatitude, widget.userLongitude),
        infoWindow: const InfoWindow(title: 'Você está aqui'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  void _addRestaurantMarkers() {
    for (var restaurant in widget.restaurants) {
      final address =
          '${restaurant.logradouro}, ${restaurant.numero}, CEP ${restaurant.cep}';
      locationFromAddress(address).then((locations) {
        if (locations.isNotEmpty) {
          final loc = locations.first;
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(restaurant.idEndereco),
                position: LatLng(loc.latitude, loc.longitude),
                infoWindow: InfoWindow(
                  title: restaurant.name,
                  snippet: restaurant.tipoEntrega,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RestaurantDetailPage(restaurant: restaurant),
                    ),
                  );
                },
              ),
            );
          });
        }
      }).catchError((e) {
        // Falha ao geocodificar o endereço
        print('Erro geocoding ${restaurant.idEndereco}: \$e');
      });
    }
  }

  void _toggleMapType() {
    setState(() {
      _isSatelliteView = !_isSatelliteView;
    });
  }

  void _centerMapOnUser() {
    _mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(widget.userLatitude, widget.userLongitude),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCameraPosition = CameraPosition(
      target: LatLng(widget.userLatitude, widget.userLongitude),
      zoom: 14,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Restaurantes'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: Icon(_isSatelliteView ? Icons.map : Icons.satellite),
            onPressed: _toggleMapType,
            tooltip: _isSatelliteView ? 'Modo Mapa' : 'Modo Satélite',
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        mapType: _isSatelliteView ? MapType.satellite : MapType.normal,
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'center',
            onPressed: _centerMapOnUser,
            backgroundColor: Colors.green.shade700,
            child: const Icon(Icons.my_location),
            tooltip: 'Centralizar no usuário',
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'toggle',
            onPressed: _toggleMapType,
            backgroundColor: Colors.green.shade700,
            child: Icon(_isSatelliteView ? Icons.map : Icons.satellite),
            tooltip: _isSatelliteView ? 'Modo Mapa' : 'Modo Satélite',
          ),
        ],
      ),
    );
  }
}
