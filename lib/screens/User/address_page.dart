import 'package:flutter/material.dart';

class AddressPage extends StatelessWidget {
  final String address;

  AddressPage({required this.address});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seu Endereço'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          address,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
