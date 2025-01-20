import 'package:flutter/material.dart';

class CountryCodePopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Image.asset('assets/flag.png', width: 24, height: 24),
            title: Text("Brasil"),
            trailing: Text("+55"),
          );
        },
      ),
    );
  }
}
