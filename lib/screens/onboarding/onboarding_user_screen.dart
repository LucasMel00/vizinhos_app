import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileOnboardingScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  const UserProfileOnboardingScreen({Key? key, this.onContinue})
      : super(key: key);

  @override
  State<UserProfileOnboardingScreen> createState() =>
      _UserProfileOnboardingScreenState();
}

class _UserProfileOnboardingScreenState
    extends State<UserProfileOnboardingScreen> {
  bool _dontShowAgain = false;

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dontShowUserProfileOnboarding', _dontShowAgain);
  }

  void _finish() async {
    await _savePreference();
    if (widget.onContinue != null)
      widget.onContinue!();
    else
      Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFbbc2c);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Seu Perfil'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 80, color: primaryColor),
              const SizedBox(height: 24),
              Text(
                'Veja e Edite Suas Informações',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'No seu perfil você pode visualizar e atualizar seus dados pessoais, endereço, foto e preferências.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildFeature(
                icon: Icons.edit_outlined,
                title: 'Editar Dados',
                description:
                    'Toque no botão de edição para alterar nome, email, telefone ou endereço.',
                color: primaryColor,
              ),
              const SizedBox(height: 18),
              _buildFeature(
                icon: Icons.location_on_outlined,
                title: 'Atualizar Endereço',
                description:
                    'Mantenha seu endereço sempre atualizado para facilitar entregas e serviços.',
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 18),
              _buildFeature(
                icon: Icons.save_outlined,
                title: 'Salve as Alterações',
                description:
                    'Após editar, lembre-se de salvar para manter seus dados atualizados.',
                color: Colors.blue,
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
                    'Entendi',
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
        Icon(icon, color: color, size: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
