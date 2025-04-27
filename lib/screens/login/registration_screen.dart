import 'dart:convert';
import 'dart:io'; // Necessário para arquivos (se for o caso) - Embora não usado diretamente para File, ImagePicker usa
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:vizinhos_app/screens/login/login_email_screen.dart';
import 'package:vizinhos_app/screens/terms_screen.dart';
import 'package:image_picker/image_picker.dart'; // Para seleção de imagens

class RegistrationScreen extends StatefulWidget {
  final String email;

  const RegistrationScreen({super.key, required this.email}); // Use super.key

  @override
  State<RegistrationScreen> createState() =>
      _RegistrationScreenState(); // Use State<RegistrationScreen>
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Controladores dos campos básicos
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cepController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController addressNumberController = TextEditingController();
  final TextEditingController addressComplementController =
      TextEditingController();

  // Controladores para dados do vendedor
  final TextEditingController sellerNameController = TextEditingController();
  final TextEditingController sellerDescriptionController =
      TextEditingController();
  // Este controlador armazenará o valor da imagem em base64.
  final TextEditingController sellerImageController = TextEditingController();
  final TextEditingController sellerDeliveryTypeController =
      TextEditingController();

  // Máscaras para CPF, CEP e Telefone
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
    // initialText: '+55 ', // Consider removing if causing issues or making optional
  );

  // Estado e navegação entre páginas
  int _currentPage = 0;
  late final PageController _pageController;
  bool isLoading = false;
  bool isSeller = false;
  bool acceptedTerms = false;
  // Usaremos um GlobalKey para o Scaffold para garantir acesso ao context correto para Snackbars
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Ou use um BuildContext armazenado como você fez, mas GlobalKey é mais robusto.
  // late BuildContext _scaffoldContext; // Você estava usando isso, o que é ok se usado corretamente via Builder

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Pré-preenche o telefone se necessário
    // phoneNumberController.text = '+55 '; // Se usar initialText no formatter, não precisa disso
  }

  @override
  void dispose() {
    // Dispose de TODOS os controllers
    _pageController.dispose();
    fullNameController.dispose();
    cpfController.dispose();
    phoneNumberController.dispose();
    passwordController.dispose();
    cepController.dispose();
    addressController.dispose();
    addressNumberController.dispose();
    addressComplementController.dispose();
    sellerNameController.dispose();
    sellerDescriptionController.dispose();
    sellerImageController.dispose();
    sellerDeliveryTypeController.dispose();
    super.dispose();
  }

// Versão corrigida da função _pickImage()
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        isLoading = true;
      });

      try {
        // Obter a extensão do arquivo
        final String extension = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
          throw Exception(
              'Formato de imagem não suportado. Use JPG, PNG, GIF ou WebP.');
        }

        // Normalizar extensão (jpg/jpeg)
        final String normalizedExtension =
            extension == 'jpeg' ? 'jpg' : extension;

        // Ler os bytes da imagem
        final bytes = await pickedFile.readAsBytes();

        // Converter para base64
        final String base64Image = base64Encode(bytes);

        // Preparar o payload para a API
        final Map<String, dynamic> payload = {
          'image': base64Image,
          'file_extension': normalizedExtension
        };

        // Enviar para a API SaveStoreImage
        final response = await http.post(
          Uri.parse(
              'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/SaveStoreImage'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        // Depuração: imprimir a resposta completa
        print('Resposta da API SaveStoreImage: ${response.body}');

        // Verificar resposta
        if (response.statusCode == 200) {
          try {
            // Decodificar a resposta JSON
            final Map<String, dynamic> responseData = jsonDecode(response.body);

            // Extrair o nome do arquivo
            final String fileName = responseData['file_name'];

            // Depuração: imprimir o valor extraído
            print('Nome do arquivo extraído: $fileName');

            // Armazenar apenas o nome do arquivo como string
            setState(() {
              sellerImageController.text = fileName;
              isLoading = false;
            });

            // Feedback para o usuário
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Imagem enviada com sucesso!")),
            );
          } catch (jsonError) {
            print('Erro ao decodificar JSON: $jsonError');
            print('Conteúdo da resposta: ${response.body}');
            throw Exception('Erro ao processar resposta da API: $jsonError');
          }
        } else {
          throw Exception('Falha ao enviar imagem: ${response.body}');
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao processar imagem: ${e.toString()}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma imagem selecionada.")),
      );
    }
  }

// Versão corrigida da parte do método registerUser() que lida com o ID da imagem
// Dentro do método registerUser(), substitua o bloco if (isSeller) por:

  // Método de validação dos campos obrigatórios ANTES DA SUBMISSÃO FINAL
  bool _validateFinalSubmissionFields() {
    // Valida Nome
    if (fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("O campo 'Nome Completo' é obrigatório"),
            backgroundColor: Colors.red),
      );
      _navigateToPage(0); // Leva o usuário de volta para a página do erro
      return false;
    }
    // Valida CPF (exemplo básico - considere validação mais robusta)
    if (cpfController.text.replaceAll(RegExp(r'[^0-9]'), '').length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("O campo 'CPF' é inválido"),
            backgroundColor: Colors.red),
      );
      _navigateToPage(0);
      return false;
    }
    // Valida Telefone (exemplo básico)
    if (phoneNumberController.text.replaceAll(RegExp(r'[^0-9]'), '').length <
        10) {
      // Ajuste a validação conforme necessário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("O campo 'Telefone' é inválido"),
            backgroundColor: Colors.red),
      );
      _navigateToPage(2); // Página de contato
      return false;
    }
    // Valida Senha (exemplo básico)
    if (passwordController.text.trim().length < 6) {
      // Exemplo: mínimo 6 caracteres
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("A senha deve ter pelo menos 6 caracteres"),
            backgroundColor: Colors.red),
      );
      _navigateToPage(2);
      return false;
    }
    // Valida CEP/Endereço se necessário
    if (cepController.text.replaceAll(RegExp(r'[^0-9]'), '').length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("O campo 'CEP' é inválido"),
            backgroundColor: Colors.red),
      );
      _navigateToPage(1); // Página de endereço
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("O campo 'Logradouro' é obrigatório"),
            backgroundColor: Colors.red),
      );
      _navigateToPage(1);
      return false;
    }
    if (addressNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("O campo 'Número' é obrigatório"),
            backgroundColor: Colors.red),
      );
      _navigateToPage(1);
      return false;
    }

    // Validações para Vendedor (se aplicável)
    if (isSeller) {
      if (sellerNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("O campo 'Nome da Loja' é obrigatório para vendedores"),
              backgroundColor: Colors.red),
        );
        _navigateToPage(3); // Página de vendedor
        return false;
      }
      // Adicione outras validações de vendedor aqui (descrição, imagem, tipo entrega)
      // if (sellerImageController.text.trim().isEmpty) { ... }
    }

    // Valida aceite dos termos
    if (!acceptedTerms) {
      _showTermsWarning(); // Mostra o dialog específico para termos
      return false;
    }

    return true; // Todos os campos obrigatórios validados
  }

  // Método para registrar o usuário
  Future<void> registerUser() async {
    // 1. Validação COMPLETA antes de prosseguir
    if (!_validateFinalSubmissionFields()) {
      return; // Interrompe se a validação falhar
    }

    // 2. Iniciar Loading
    setState(() => isLoading = true);

    // 3. Montagem dos dados do usuário
    Map<String, dynamic> userData = {
      // Usar .trim() é bom, mas a validação já garantiu que não está vazio
      'nome': fullNameController.text.trim(),
      'cpf': cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      'Usuario_Tipo': isSeller ? 'seller' : 'customer',
      // Garanta que a máscara/limpeza retorne o formato esperado pelo backend
      'telefone': phoneNumberController.text.replaceAll(
          RegExp(r'[^0-9+]'), ''), // Remove tudo exceto números e '+'
      'email': widget.email,
      'senha': passwordController.text
          .trim(), // Idealmente, a senha não deveria ser enviada em plain text
      'cep': cepController.text
          .replaceAll(RegExp(r'[^0-9]'), ''), // Apenas números para o CEP
      'logradouro': addressController.text.trim(),
      'numero': addressNumberController.text.trim(),
      'complemento': addressComplementController.text.trim(),
    };

    // Se for vendedor, adiciona os campos extras
    if (isSeller) {
      // Depuração: imprimir o valor antes de adicionar ao userData
      print(
          'ID da imagem antes de adicionar ao userData: ${sellerImageController.text}');

      // Verificar se o ID da imagem é válido antes de adicioná-lo
      final String imageId = sellerImageController.text.trim();

      userData.addAll({
        'nome_Loja': sellerNameController.text.trim(),
        'descricao_Loja': sellerDescriptionController.text.trim(),
        // Usar diretamente o valor do controller como string, sem tentar decodificar
        'id_Imagem': imageId,
        'tipo_Entrega': sellerDeliveryTypeController.text.trim(),
      });

      // Depuração: imprimir o userData após adicionar o ID da imagem
      print('userData após adicionar ID da imagem: $userData');
    }

    // 4. Formata o JSON conforme o exemplo: {"body": "<string JSON com os dados do usuário>"}
    final jsonBody = jsonEncode(userData);

    // DEBUG: Imprime o JSON exato que será enviado
    print('--- Sending Registration Data ---');
    print(jsonBody);
    print('--- End Registration Data ---');

    final url = Uri.parse(
        'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/RegisterUser');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      // DEBUG: Imprime o status e corpo da resposta SEMPRE
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Aceitar 201 (Created) também
        // Sucesso
        if (mounted) {
          // Verifica se o widget ainda está na árvore
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Cadastro realizado com sucesso!"),
              backgroundColor: Colors.green[700],
            ),
          );
          // Navega para o Login após um pequeno delay para o usuário ver o snackbar
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        LoginEmailScreen(email: widget.email)),
                (Route<dynamic> route) =>
                    false, // Remove todas as rotas anteriores
              );
            }
          });
        }
      } else {
        // Erro do Servidor
        String errorMessage = 'Erro ao realizar cadastro.'; // Mensagem padrão
        try {
          final decoded = jsonDecode(response.body);
          // Tenta pegar a mensagem específica do backend
          if (decoded is Map && decoded.containsKey('message')) {
            errorMessage = decoded['message'] ?? errorMessage;
          } else if (decoded is Map && decoded.containsKey('error')) {
            errorMessage = decoded['error'] ?? errorMessage;
          } else {
            // Se não encontrar 'message' ou 'error', usa o corpo como string (limitado)
            errorMessage = response.body.length > 100
                ? response.body.substring(0, 100) + '...'
                : response.body;
          }
        } catch (e) {
          print('Erro na decodificação da resposta JSON: $e');
          // Se a resposta não for JSON válido, mostra o início do corpo
          errorMessage = response.body.length > 100
              ? response.body.substring(0, 100) + '...'
              : response.body;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(errorMessage), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      // Erro de Conexão/Rede
      print('Erro de conexão/http: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro de conexão: $e'), backgroundColor: Colors.red));
      }
    } finally {
      // Garante que o loading seja desativado mesmo se ocorrer um erro inesperado
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Exibe um alerta caso o usuário não tenha aceitado os termos
  void _showTermsWarning() {
    // Usa o contexto do Scaffold ou o contexto do Builder
    final currentContext = _scaffoldKey.currentContext ?? context;
    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        // Usar dialogContext aqui
        title: Text('Atenção!', style: TextStyle(color: Colors.red[800])),
        content: const Text(
            'Você precisa aceitar nossos termos e políticas para se registrar.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Fecha o dialog
              // Não fechar a tela de cadastro aqui, apenas o dialog.
              // O usuário precisa marcar o checkbox.
              // Se quiser pode levar para a página 3 onde está o checkbox.
              if (_currentPage != 2) {
                _navigateToPage(2);
              }
            },
            child: Text('ENTENDI', style: TextStyle(color: Color(0xFFFbbc2c))),
          ),
        ],
      ),
    );
  }

  // Constrói um TextField padronizado
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    List<TextInputFormatter>? formatters,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)?
        validator, // Opcional: Adicionar validação on-the-fly
    void Function(String)? onChanged, // Opcional: para reações imediatas
  }) {
    return TextFormField(
      // Use TextFormField para habilitar validação
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      onChanged: onChanged,
      autovalidateMode: validator != null
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFFFbbc2c)),
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
          borderSide: BorderSide(color: Color(0xFFFbbc2c)!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          // Estilo para erro de validação
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          // Estilo para erro de validação com foco
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[800]!, width: 2),
        ),
      ),
    );
  }

  // --- Funções para construir as páginas ---

  // Página 1: Informações Pessoais
  Widget _personalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações Pessoais',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFbbc2c)),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: fullNameController,
            label: 'Nome Completo *', // Indica obrigatório
            icon: Icons.person_outline,
            // Opcional: Validador simples direto no campo
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Nome é obrigatório'
                : null,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: cpfController,
            label: 'CPF *',
            icon: Icons.assignment_ind_outlined,
            formatters: [cpfMaskFormatter],
            keyboardType: TextInputType.number,
            validator: (value) => (value == null ||
                    value.replaceAll(RegExp(r'[^0-9]'), '').length != 11)
                ? 'CPF inválido'
                : null,
          ),
          const SizedBox(height: 16),
          Text('* Campos obrigatórios',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  // Página 2: Endereço
  Widget _addressPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Endereço',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFbbc2c))),
          const SizedBox(height: 32),
          _buildTextField(
            controller: cepController,
            label: 'CEP *',
            icon: Icons.location_on_outlined,
            formatters: [cepMaskFormatter],
            keyboardType: TextInputType.number,
            validator: (value) => (value == null ||
                    value.replaceAll(RegExp(r'[^0-9]'), '').length != 8)
                ? 'CEP inválido'
                : null,
            suffixIcon: IconButton(
              icon: Icon(Icons.search, color: Color(0xFFFbbc2c)),
              onPressed: () async {
                final cep =
                    cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
                if (cep.length == 8) {
                  // Opcional: Mostrar loading enquanto busca
                  setState(() => isLoading = true);
                  try {
                    final response = await http
                        .get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
                    if (response.statusCode == 200) {
                      final data = json.decode(response.body);
                      if (data != null && data['logradouro'] != null) {
                        setState(() {
                          addressController.text = data['logradouro'] ?? '';
                          // Poderia preencher bairro, cidade, etc., se tivesse os campos
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("CEP não encontrado."),
                              backgroundColor: Colors.orange),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Erro ao buscar CEP: ${response.statusCode}"),
                            backgroundColor: Colors.red),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Erro ao buscar CEP: $e"),
                          backgroundColor: Colors.red),
                    );
                  } finally {
                    setState(() => isLoading = false);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Digite um CEP válido (8 dígitos)."),
                        backgroundColor: Colors.orange),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Alinha pelo topo se houver erro
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  controller: addressController,
                  label: 'Logradouro *',
                  icon: Icons.home_outlined,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Logradouro obrigatório'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: addressNumberController,
                  label: 'Número *',
                  icon: Icons.numbers_outlined,
                  keyboardType:
                      TextInputType.number, // Teclado numérico para número
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Número obrigatório'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: addressComplementController,
            label: 'Complemento', // Não obrigatório
            icon: Icons.notes_outlined,
          ),
          const SizedBox(height: 16),
          Text('* Campos obrigatórios',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  // Página 3: Contato, Senha e opção de cadastro como vendedor
  Widget _contactInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contato e Senha',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFbbc2c))),
          const SizedBox(height: 32),
          _buildTextField(
            controller: phoneNumberController,
            label: 'Telefone *',
            icon: Icons.phone_android_outlined,
            formatters: [phoneMaskFormatter],
            keyboardType: TextInputType.phone,
            validator: (value) => (value == null ||
                    value.replaceAll(RegExp(r'[^0-9]'), '').length < 10)
                ? 'Telefone inválido'
                : null,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: passwordController,
            label: 'Senha *',
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (value) => (value == null || value.trim().length < 6)
                ? 'Mínimo 6 caracteres'
                : null,
          ),
          const SizedBox(height: 24),
          // Termos de Uso
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: acceptedTerms,
                activeColor: Color(0xFFFbbc2c),
                onChanged: (value) =>
                    setState(() => acceptedTerms = value ?? false),
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap, // Reduz área de toque
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Abre a tela de Termos de Uso
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TermsScreen())); // Use const se TermsScreen não precisar de params
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[800], fontSize: 14),
                      children: [
                        const TextSpan(text: 'Li e aceito os '),
                        TextSpan(
                          text: 'Termos de Uso',
                          style: TextStyle(
                            color: Color(0xFFFbbc2c),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          // recognizer: TapGestureRecognizer()..onTap = () { Navigator.push(...); } // Outra forma de fazer o link clicável
                        ),
                        const TextSpan(text: ' e '),
                        TextSpan(
                          text: 'Política de Privacidade',
                          style: TextStyle(
                            color: Color(0xFFFbbc2c),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          // recognizer: TapGestureRecognizer()..onTap = () { Navigator.push(...); } // Para link da política
                        ),
                        const TextSpan(
                            text: ' *'), // Indica que aceitar é obrigatório
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Botão para alternar a opção de vendedor
          InkWell(
            onTap: () {
              setState(() {
                isSeller = !isSeller;
                // Quando muda, reseta a página atual para evitar ir para uma página inválida
                // Se estava na página de vendedor (3) e desmarcou, volta para a 2.
                if (!isSeller && _currentPage == 3) {
                  _currentPage = 2;
                }
                // Recalcula o número total de páginas
                _pageController
                    .jumpToPage(_currentPage); // Atualiza PageView sem animação
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSeller ? Colors.green[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSeller ? Color(0xFFFbbc2c)! : Colors.grey[300]!,
                  width: isSeller ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSeller
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSeller ? Color(0xFFFbbc2c) : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Quero me cadastrar como vendedor',
                    style: TextStyle(
                        color: Colors.grey[800], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('* Campos obrigatórios',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  // Página 4: Dados do Vendedor (exibida apenas se o usuário optar por ser vendedor)
  Widget _sellerInfoPage() {
    // Não renderiza nada se não for vendedor (precaução)
    if (!isSeller) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dados do Vendedor',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFbbc2c))),
          const SizedBox(height: 32),
          _buildTextField(
            controller: sellerNameController,
            label: 'Nome da Loja *',
            icon: Icons.store_outlined,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Nome da loja obrigatório'
                : null,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: sellerDescriptionController,
            label: 'Descrição da Loja', // Opcional?
            icon: Icons.description_outlined,
            keyboardType: TextInputType.multiline, // Permite múltiplas linhas
            //maxLines: 3, // Limita a altura inicial
          ),
          const SizedBox(height: 24),
          // Botão para selecionar imagem e converter para base64
          InkWell(
            onTap: isLoading ? null : _pickImage, // Desabilita durante loading
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, color: Color(0xFFFbbc2c)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      sellerImageController.text.isEmpty
                          ? 'Selecionar Imagem da Loja' // Mais descritivo
                          : 'Imagem Selecionada ✓', // Feedback visual
                      style: TextStyle(
                          color: sellerImageController.text.isEmpty
                              ? Colors.grey[800]
                              : Color(0xFFFbbc2c),
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (sellerImageController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.red[600]),
                      onPressed: () =>
                          setState(() => sellerImageController.clear()),
                      tooltip: 'Remover Imagem',
                    )
                ],
              ),
            ),
          ),
          // Opcional: Preview da imagem selecionada

          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: sellerDeliveryTypeController.text.isNotEmpty
                ? sellerDeliveryTypeController.text
                : null,
            decoration: InputDecoration(
              labelText: 'Tipo de Entrega *',
              prefixIcon:
                  Icon(Icons.local_shipping_outlined, color: Color(0xFFFbbc2c)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              DropdownMenuItem(
                value: 'Retirada no local',
                child: Text('Retirada no local'),
              ),
              DropdownMenuItem(
                value: 'Delivery',
                child: Text('Delivery'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                sellerDeliveryTypeController.text = value ?? '';
              });
            },
            validator: (value) => (value == null || value.isEmpty)
                ? 'Selecione o tipo de entrega'
                : null,
          ),
          const SizedBox(height: 16),
          Text('* Campos obrigatórios',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  // --- Lógica de Navegação e Build ---

  // Constrói a lista de páginas dinamicamente, conforme a opção de vendedor
  List<Widget> _buildPages() {
    // Usar um Form por página ou um Form global pode ajudar na validação
    // mas para este exemplo, mantemos a validação manual antes da submissão final
    List<Widget> pages = [
      _personalInfoPage(),
      _addressPage(),
      _contactInfoPage(),
    ];
    if (isSeller) pages.add(_sellerInfoPage());
    return pages;
  }

  // Retorna o índice da última página: se for vendedor é 3, senão 2
  int get _finalPageIndex => isSeller ? 3 : 2;

  // Navegação entre páginas no PageView
  void _navigateToPage(int page) {
    // Garante que a página de destino exista
    if (page >= 0 && page < _buildPages().length) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 400), // Duração um pouco maior
        curve: Curves.easeInOutCubic, // Curva mais suave
      );
      // setState(() => _currentPage = page); // onPageChanged já faz isso
    }
  }

  // Validação básica ao tentar avançar de página (opcional, mas melhora UX)
  bool _validateCurrentPage() {
    // Adicione validações por página se desejar feedback imediato ao clicar em "CONTINUAR"
    // Exemplo para a primeira página:
    if (_currentPage == 0) {
      if (fullNameController.text.trim().isEmpty ||
          cpfController.text.replaceAll(RegExp(r'[^0-9]'), '').length != 11) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Preencha Nome e CPF corretamente para continuar."),
              backgroundColor: Colors.orange),
        );
        return false;
      }
    }
    // Adicione validações para as outras páginas (_currentPage == 1, etc.) aqui
    // if (_currentPage == 1) { ... }

    return true; // Permite avançar se a validação da página atual passar
  }

  @override
  Widget build(BuildContext context) {
    // Usar Builder apenas se precisar de um context específico abaixo do Scaffold,
    // senão pode usar o context direto do build. Com GlobalKey, não precisa do Builder.
    final pages = _buildPages(); // Calcula as páginas uma vez por build

    return Scaffold(
      key: _scaffoldKey, // Associa a GlobalKey
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Color(0xFFFbbc2c)), // Ícone diferente
          tooltip: 'Voltar',
          onPressed: () {
            if (_currentPage > 0) {
              _navigateToPage(_currentPage - 1);
            } else {
              // Talvez mostrar um confirm dialog antes de sair?
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          // Define o título baseado na página atual
          _currentPage == 0
              ? 'Informações Pessoais'
              : _currentPage == 1
                  ? 'Endereço'
                  : _currentPage == 2
                      ? 'Contato e Segurança' // Título mais claro
                      : (_currentPage == 3 && isSeller)
                          ? 'Dados do Vendedor'
                          : 'Cadastro', // Fallback
          style: TextStyle(
            color: Color(0xFFFbbc2c),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 1, // Pequena sombra para destacar
        backgroundColor: Colors.grey[50], // Combina com o fundo
        systemOverlayStyle:
            SystemUiOverlayStyle.dark, // Ícones da status bar escuros
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Indicador de progresso (Stepper-like)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length, // Usa o tamanho da lista de páginas atual
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: AnimatedContainer(
                  // Anima a mudança de cor/tamanho
                  duration: const Duration(milliseconds: 300),
                  width:
                      _currentPage == index ? 16 : 10, // Maior na página atual
                  height: 10,
                  decoration: BoxDecoration(
                    color: _currentPage >= index
                        ? Colors
                            .green[700]! // Cor mais forte para ativo/passado
                        : Colors.grey[300]!,
                    borderRadius:
                        BorderRadius.circular(5), // Bordas arredondadas
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: PageView(
              controller: _pageController,
              // physics: NeverScrollableScrollPhysics(), // Permite scroll por gesto se desejado
              physics:
                  const AlwaysScrollableScrollPhysics(), // Ou desabilite com NeverScrollableScrollPhysics
              children: pages, // Usa a lista de páginas calculada
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  // Opcional: Esconder teclado ao mudar de página
                  FocusScope.of(context).unfocus();
                });
              },
            ),
          ),
          // Botões de Navegação
          Padding(
            padding:
                const EdgeInsets.fromLTRB(24, 12, 24, 24), // Ajuste no padding
            child: Row(
              children: [
                // Botão VOLTAR (visível apenas se não for a primeira página)
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14), // Padding interno
                        foregroundColor: Color(0xFFFbbc2c),
                        side: BorderSide(color: Color(0xFFFbbc2c)!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () => _navigateToPage(_currentPage - 1),
                      label: const Text(
                        'VOLTAR',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                // Espaçador entre botões (visível apenas se ambos os botões estiverem presentes)
                if (_currentPage > 0) const SizedBox(width: 16),
                // Botão CONTINUAR / FINALIZAR
                Expanded(
                  child: ElevatedButton.icon(
                    icon: isLoading
                        ? Container(
                            // Indicador de loading no botão
                            width: 20,
                            height: 20,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _currentPage == _finalPageIndex
                                ? Icons.check_circle_outline
                                : Icons.arrow_forward_ios,
                            size: 18,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFbbc2c),
                      foregroundColor: Colors.white, // Cor do texto/ícone
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3, // Sombra
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            // Desabilita se estiver carregando
                            FocusScope.of(context).unfocus(); // Esconde teclado
                            if (_currentPage < _finalPageIndex) {
                              // Opcional: Validar página atual antes de avançar
                              // if (_validateCurrentPage()) {
                              _navigateToPage(_currentPage + 1);
                              // }
                            } else {
                              // É a última página, tenta registrar
                              registerUser();
                            }
                          },
                    label: Text(
                      isLoading
                          ? 'ENVIANDO...'
                          : _currentPage == _finalPageIndex
                              ? 'FINALIZAR'
                              : 'CONTINUAR',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
