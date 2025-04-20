import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/User/user_adress_editor_page.dart';
import 'package:vizinhos_app/screens/User/user_profile_editor_page.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const UserProfilePage({Key? key, this.userInfo}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String? email = authProvider.email ?? await storage.read(key: 'email');

      if (email == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final response = await http.get(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetUserByEmail?email=$email'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            userData = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  void _navigateToEditPage() {
    _showEditOptions();
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Editar Perfil'),
              onTap: () {
                Navigator.pop(context);
                _navigateToProfileEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Editar Endereço'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddressEdit();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfileEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileEditorPage(
          userData: userData,
          onSave: (updatedUser) {
            setState(() {
              userData!['usuario'] = updatedUser['usuario'];
            });
          },
        ),
      ),
    );
  }

  void _navigateToAddressEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserAddressEditorPage(
          userData: userData,
          onSave: (updatedEndereco) {
            setState(() {
              userData!['endereco'] = updatedEndereco['endereco'];
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFbbc2c);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPage,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, size: 50, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            userData?['usuario']?['nome'] ?? 'Nome não informado',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userData?['usuario']?['email'] ?? 'Email não informado',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              icon: Icons.phone,
              title: 'Telefone',
              value: userData?['usuario']?['telefone'] ?? 'Não informado',
            ),
            const Divider(height: 24),
            _buildInfoItem(
              icon: Icons.location_on,
              title: 'Endereço',
              value: userData?['endereco'] != null
                  ? '${userData!['endereco']['logradouro']}, ${userData!['endereco']['numero']}'
                  : 'Não informado',
            ),
            if (userData?['endereco']?['complemento'] != null &&
                userData!['endereco']['complemento'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Complemento: ${userData!['endereco']['complemento']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            const Divider(height: 24),
            _buildInfoItem(
              icon: Icons.location_city,
              title: 'CEP',
              value: userData?['endereco']?['cep'] ?? 'Não informado',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: const Color(0xFF5F4A14)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5F4A14),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
