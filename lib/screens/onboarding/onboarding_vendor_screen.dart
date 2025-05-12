import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorOnboardingScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  const VendorOnboardingScreen({Key? key, this.onContinue}) : super(key: key);

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  bool _dontShowAgain = false;

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dontShowVendorOnboarding', _dontShowAgain);
  }

  void _finish() async {
    await _savePreference();
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFbbc2c);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bem-vindo à sua Loja'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.store_mall_directory, size: 80, color: primaryColor),
              const SizedBox(height: 24),
              Text(
                'Gerencie sua Loja',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Aqui você pode cadastrar e editar produtos, controlar estoque, visualizar pedidos recebidos e atualizar as informações da sua loja.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildFeature(
                icon: Icons.add_box_outlined,
                title: 'Cadastrar Produtos',
                description:
                    'Adicione novos produtos com nome, descrição, preço, categoria, foto, validade, quantidade e características.',
                color: primaryColor,
              ),
              const SizedBox(height: 18),
              _buildFeature(
                icon: Icons.edit_outlined,
                title: 'Editar Produtos',
                description:
                    'Altere informações, estoque, imagem, preço ou características de produtos já cadastrados.',
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 18),
              _buildFeature(
                icon: Icons.inventory_2_outlined,
                title: 'Gerenciar Estoque',
                description:
                    'Atualize a quantidade disponível de cada produto e controle lotes e validade.',
                color: Colors.teal,
              ),
              const SizedBox(height: 18),
              _buildFeature(
                icon: Icons.receipt_long,
                title: 'Ver Pedidos',
                description:
                    'Acompanhe todos os pedidos feitos pelos clientes, atualize status e veja detalhes de cada venda.',
                color: Colors.blue,
              ),
              const SizedBox(height: 18),
              _buildFeature(
                icon: Icons.storefront_outlined,
                title: 'Editar Informações da Loja',
                description:
                    'Atualize nome, descrição, foto, endereço e tipo de entrega da sua loja.',
                color: Colors.purple,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    onChanged: (v) =>
                        setState(() => _dontShowAgain = v ?? false),
                  ),
                  const Expanded(
                    child: Text('Não mostrar novamente',
                        style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Começar',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900]),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
