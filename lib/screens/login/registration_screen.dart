import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:vizinhos_app/screens/login/login_email_screen.dart';
import 'package:vizinhos_app/screens/terms_screen.dart'; // Crie este arquivo

class RegistrationScreen extends StatefulWidget {
  final String email;

  const RegistrationScreen({required this.email});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Controladores
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cepController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController addressComplementController =
      TextEditingController();
  final TextEditingController addressNumberController = TextEditingController();

  // Máscaras
  final cpfMaskFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final cepMaskFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+55 (##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    initialText: '+55 ',
  );

  // Estado
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool isLoading = false;
  bool isSeller = false;
  bool acceptedTerms = false;
  late BuildContext _scaffoldContext;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (!acceptedTerms) {
      _showTermsWarning();
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'password': passwordController.text.trim(),
          'name': fullNameController.text.trim(),
          'cpf': cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          'phone_number':
              phoneNumberController.text.replaceAll(RegExp(r'[^0-9+]'), ''),
          'address': addressController.text.trim(),
          'address_number': addressNumberController.text.trim(),
          'complement': addressComplementController.text.trim(),
          'cep': cepController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'is_seller': isSeller.toString(),
          'accepted_terms': acceptedTerms.toString(),
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginEmailScreen(email: widget.email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonDecode(response.body)['error'])),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  void _showTermsWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Atenção!', style: TextStyle(color: Colors.red[800])),
        content: Text(
            'Você precisa aceitar nossos termos e políticas para se registrar.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(_scaffoldContext).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Infelizmente você precisa aceitar nossas políticas para continuar'),
                    backgroundColor: Colors.red[800],
                  ),
                );
              });
            },
            child: Text('ENTENDI', style: TextStyle(color: Colors.green[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
          3,
          (index) => Container(
                width: 12,
                height: 12,
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _currentPage >= index
                      ? Colors.green[800]!
                      : Colors.grey[300]!,
                  shape: BoxShape.circle,
                ),
              )),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    List<TextInputFormatter>? formatters,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green[800]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[800]!, width: 2),
        ),
      ),
    );
  }

  Widget _personalInfoPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informações Pessoais',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800])),
          SizedBox(height: 32),
          _buildTextField(
            controller: fullNameController,
            label: 'Nome Completo',
            icon: Icons.person_outline,
          ),
          SizedBox(height: 24),
          _buildTextField(
            controller: cpfController,
            label: 'CPF',
            icon: Icons.assignment_ind_outlined,
            formatters: [cpfMaskFormatter],
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _addressPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Endereço',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800])),
          SizedBox(height: 32),
          _buildTextField(
            controller: cepController,
            label: 'CEP',
            icon: Icons.location_on_outlined,
            formatters: [cepMaskFormatter],
            keyboardType: TextInputType.number,
            suffixIcon: IconButton(
              icon: Icon(Icons.search, color: Colors.green[800]),
              onPressed: () async {
                final cep =
                    cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
                if (cep.length == 8) {
                  final response = await http
                      .get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    setState(() {
                      addressController.text = data['logradouro'] ?? '';
                      cityController.text = data['localidade'] ?? '';
                      stateController.text = data['uf'] ?? '';
                    });
                  }
                }
              },
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  controller: addressController,
                  label: 'Endereço',
                  icon: Icons.home_outlined,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: addressNumberController,
                  label: 'Número',
                  icon: Icons.numbers_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildTextField(
            controller: addressComplementController,
            label: 'Complemento',
            icon: Icons.notes_outlined,
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: cityController,
                  label: 'Cidade',
                  icon: Icons.location_city_outlined,
                  readOnly: true,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: stateController,
                  label: 'Estado',
                  icon: Icons.flag_outlined,
                  readOnly: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactInfoPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contato e Senha',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800])),
          SizedBox(height: 32),
          _buildTextField(
            controller: phoneNumberController,
            label: 'Telefone',
            icon: Icons.phone_android_outlined,
            formatters: [phoneMaskFormatter],
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 24),
          _buildTextField(
            controller: passwordController,
            label: 'Senha',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Checkbox(
                value: acceptedTerms,
                activeColor: Colors.green[800],
                onChanged: (value) => setState(() => acceptedTerms = value!),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => TermsScreen())),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[800], fontSize: 14),
                      children: [
                        TextSpan(text: 'Li e aceito os '),
                        TextSpan(
                          text: 'Termos de Uso',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' e '),
                        TextSpan(
                          text: 'Política de Privacidade',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          InkWell(
            onTap: () => setState(() => isSeller = !isSeller),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSeller ? Colors.green[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSeller ? Colors.green[800]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSeller
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSeller ? Colors.green[800] : Colors.grey,
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Quero me cadastrar como vendedor',
                    style: TextStyle(
                        color: Colors.grey[800], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        _scaffoldContext = context;
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.green[800]),
              onPressed: () => _currentPage > 0
                  ? _navigateToPage(_currentPage - 1)
                  : Navigator.pop(context),
            ),
            title: Text(
              ['Informações Pessoais', 'Endereço', 'Contato'][_currentPage],
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: Column(
            children: [
              SizedBox(height: 16),
              _buildProgressIndicator(),
              SizedBox(height: 24),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _personalInfoPage(),
                    _addressPage(),
                    _contactInfoPage(),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.green[800]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _navigateToPage(_currentPage - 1),
                          child: Text(
                            'VOLTAR',
                            style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (_currentPage > 0) SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _currentPage < 2
                            ? _navigateToPage(_currentPage + 1)
                            : registerUser(),
                        child: Text(
                          _currentPage == 2
                              ? 'FINALIZAR CADASTRO'
                              : 'CONTINUAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: isLoading
              ? Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green[800],
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : null,
        );
      },
    );
  }
}
