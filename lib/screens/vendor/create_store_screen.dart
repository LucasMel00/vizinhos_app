import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
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
  final _descriptionController = TextEditingController();
  final List<String> _selectedCategories = [];
  bool _isLoading = false;
  File? _selectedImage;
  String? _imageBase64;
  String? _imageType;

  final List<String> _availableCategories = [
    'Pratos Caseiros',
    'Massas & Risotos',
    'Sopas & Caldos',
    'Salgados & Pães',
    'Doces & Sobremesas',
    'Bebidas Artesanais',
    'Saladas & Veganos'
  ];

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage:
              _selectedImage != null ? FileImage(_selectedImage!) : null,
          child: _selectedImage == null
              ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
              : null,
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          icon: Icon(Icons.photo_library),
          label: Text('Selecionar da Galeria (opcional)'),
          onPressed: _pickImage,
        ),
        if (_selectedImage != null)
          TextButton(
            child: Text('Remover imagem', style: TextStyle(color: Colors.red)),
            onPressed: () => setState(() {
              _selectedImage = null;
              _imageBase64 = null;
              _imageType = null;
            }),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        final bytes = file.bytes!;
        final base64Image = base64Encode(bytes);

        setState(() {
          _selectedImage = File(file.path!);
          _imageBase64 = base64Image;
          _imageType = _getMimeType(file.extension!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  Widget _buildStoreNameField() {
    return TextFormField(
      controller: _storeNameController,
      decoration: InputDecoration(
        labelText: 'Nome da Loja',
        prefixIcon: Icon(Icons.store),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, insira o nome da loja';
        }
        if (value.trim().length < 4) {
          return 'O nome deve ter pelo menos 4 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Descrição Curta',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
        hintText: 'Descreva sua loja em poucas palavras...',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Informe uma descrição';
        if (value.length > 150) return 'Máximo de 150 caracteres';
        return null;
      },
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione as Categorias:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _availableCategories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) =>
                  _handleCategorySelection(selected, category),
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              avatar: isSelected
                  ? Icon(Icons.check,
                      size: 18, color: Theme.of(context).primaryColor)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione pelo menos 1 categoria',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(String effectiveUserId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _submitForm(effectiveUserId),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoading ? SizedBox.shrink() : Icon(Icons.storefront_outlined),
        label: _isLoading
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text(
                'Criar Loja',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  void _handleCategorySelection(bool selected, String category) {
    setState(() {
      if (selected) {
        _selectedCategories.add(category);
      } else {
        _selectedCategories.remove(category);
      }
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Como Funciona?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Escolha um nome claro para sua loja\n'
                '2. Sua loja utilizará o endereço cadastrado em sua conta\n'
                '3. Selecione as categorias que melhor representam seus produtos\n'
                '4. Após a criação, sua loja estará visível para a comunidade'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm(String effectiveUserId) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos uma categoria'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (effectiveUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de autenticação'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sellerService = SellerService(
        apiUrl:
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/createVizinho',
        authProvider: authProvider,
      );

      await sellerService.createSellerProfile(
        userId: effectiveUserId,
        storeName: _storeNameController.text.trim(),
        categories: _selectedCategories,
        description: _descriptionController.text.trim(),
        fotoPerfil: _imageBase64,
        fotoPerfilType: _imageType,
      );

      // Atualiza os dados do usuário
      authProvider.refreshUserData();

      // Exibe uma animação de sucesso
      await _showSuccessAnimation();

      // Fecha a tela e retorna true para indicar sucesso
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessAnimation() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(
              'Loja criada com sucesso!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Sua loja já está disponível para a comunidade',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String effectiveUserId = widget.userId.isNotEmpty
        ? widget.userId
        : (authProvider.userInfo['sub'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Loja'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImagePicker(),
              const SizedBox(height: 20),
              _buildStoreNameField(),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildCategorySection(),
              const SizedBox(height: 30),
              _buildSubmitButton(effectiveUserId),
            ],
          ),
        ),
      ),
    );
  }
}
