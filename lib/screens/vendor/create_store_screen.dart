import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/services/service_seller.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

class CreateStoreScreen extends StatefulWidget {
  final String userId;

  const CreateStoreScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _CreateStoreScreenState createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final List<String> _selectedCategories = [];
  bool _isLoading = false;

  // Lista de categorias disponíveis (ajuste conforme necessário)
  final List<String> _availableCategories = [
    'eletrônicos',
    'informática',
    'roupas',
    'alimentos'
  ];

  @override
  void dispose() {
    _storeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se widget.userId estiver vazio, tenta obter do AuthProvider (campo "sub")
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String effectiveUserId = widget.userId.isNotEmpty
        ? widget.userId
        : (authProvider.userInfo['sub'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Loja'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Loja',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o nome da loja';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Categorias:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                children: _availableCategories.map((category) {
                  final bool isSelected =
                      _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
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
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _submitForm(effectiveUserId),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Criar Loja'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm(String effectiveUserId) async {
    // Validação do formulário e verificação se ao menos uma categoria foi selecionada
    if (!_formKey.currentState!.validate() || _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Preencha todos os campos e selecione pelo menos uma categoria'),
        ),
      );
      return;
    }

    if (effectiveUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID do usuário não informado'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtém o token atualizado do AuthProvider (mesmo que não seja enviado no payload)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Cria a instância do serviço, passando a URL do Lambda e o AuthProvider
      final sellerService = SellerService(
        apiUrl:
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/createVizinho',
        authProvider: authProvider,
      );

      await sellerService.createSellerProfile(
        userId: effectiveUserId,
        storeName: _storeNameController.text.trim(),
        categories: _selectedCategories,
      );

      // Se a criação ocorrer com sucesso, retorna para a tela anterior
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar loja: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
