import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final List<Map<String, dynamic>> storeLocations; // Example: [{'id': '1', 'latitude': -23.66, 'longitude': -46.76, 'name': 'Loja A'}, ...]

  const MapScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.storeLocations,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();

    // Add markers for stores first (with a lower zIndex)
    for (var store in widget.storeLocations) {
      final double storeLat = store['latitude'];
      final double storeLon = store['longitude'];
      final String storeName = store['name'] ?? 'Loja';
      _markers.add(
        Marker(
          markerId: MarkerId(store['id'] ?? storeName),
          position: LatLng(storeLat, storeLon),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: storeName),
          zIndex: 1,
        ),
      );
    }

    // Marker for the user residence (red) with a higher zIndex
    _markers.add(
      Marker(
        markerId: const MarkerId("userLocation"),
        position: LatLng(widget.latitude, widget.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Você está aqui"),
        zIndex: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Minha Localização")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: 14,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }
}
