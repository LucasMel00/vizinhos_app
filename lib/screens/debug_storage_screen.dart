import 'package:flutter/material.dart';
import 'package:vizinhos_app/services/secure_storage.dart';

class SecureStorageDebugScreen extends StatefulWidget {
  const SecureStorageDebugScreen({Key? key}) : super(key: key);

  @override
  _SecureStorageDebugScreenState createState() =>
      _SecureStorageDebugScreenState();
}

class _SecureStorageDebugScreenState extends State<SecureStorageDebugScreen> {
  final SecureStorage secureStorage = SecureStorage();
  Map<String, String>? allValues;

  @override
  void initState() {
    super.initState();
    _loadAllValues();
  }

  Future<void> _loadAllValues() async {
    final values = await secureStorage.readAllValues();
    setState(() {
      allValues = values;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Debug Secure Storage")),
      body: allValues == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: allValues!.length,
              itemBuilder: (context, index) {
                String key = allValues!.keys.elementAt(index);
                String value = allValues![key]!;
                return ListTile(
                  title: Text(key),
                  subtitle: Text(value),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAllValues,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
