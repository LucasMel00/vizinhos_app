import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _response = '';

  Future<void> _fetchData() async {
    final url = 'http://d1d81vvkkzn3d7.cloudfront.net/process-data';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _response = json.decode(response.body);
        });
      } else {
        setState(() {
          _response = 'Erro: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Erro: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste API Flutter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _fetchData,
              child: Text('Chamar API'),
            ),
            SizedBox(height: 20),
            Text(
              _response,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}