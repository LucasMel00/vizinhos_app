import 'package:flutter/material.dart';
import 'package:vizinhos_app/services/service_seller.dart';

class CreateStoreScreen extends StatefulWidget {
  final String userId;
  final String authToken;

  const CreateStoreScreen({
    Key? key,
    required this.userId,
    required this.authToken,
  }) : super(key: key);

  @override
  _CreateStoreScreenState createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final List<String> _selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Criar Loja')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _storeNameController,
                decoration: InputDecoration(labelText: 'Nome da Loja'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira o nome da loja';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text('Categorias:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: ['eletrônicos', 'informática', 'roupas', 'alimentos']
                    .map((category) {
                  return FilterChip(
                    label: Text(category),
                    selected: _selectedCategories.contains(category),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Criar Loja'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedCategories.isNotEmpty) {
      try {
        final sellerService = SellerService(
          apiUrl: 'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com',
          authToken: widget.authToken,
        );

        await sellerService.createSellerProfile(
          userId: widget.userId,
          storeName: _storeNameController.text,
          categories: _selectedCategories,
        );

        // Retorna sucesso
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar loja: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos corretamente')),
      );
    }
  }
}
