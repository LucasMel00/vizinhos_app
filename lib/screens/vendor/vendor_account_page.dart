import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/model/product.dart';
import 'package:vizinhos_app/screens/vendor/vendor_edit_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_orders_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_products_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_metrics_page.dart';
import 'package:vizinhos_app/services/app_theme.dart';
import 'package:vizinhos_app/screens/onboarding/mercado_pago_key_screen.dart';
import 'package:vizinhos_app/services/secure_storage.dart';
import 'vendor_reviews_sheet.dart';

class VendorAccountPage extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const VendorAccountPage({super.key, required this.userInfo});

  @override
  _VendorAccountPageState createState() => _VendorAccountPageState();
}

class _VendorAccountPageState extends State<VendorAccountPage>
    with WidgetsBindingObserver {
  late Map<String, dynamic> _currentUserInfo = widget.userInfo;

  Map<String, dynamic>? storeData;
  bool _isLoading = true;

  bool _infoExpanded = true;
  bool _mercadoPagoKeyMissing = false;

  final SecureStorage _secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUserInfo = widget.userInfo;
    _loadStoreData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStoreData();
    }
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    try {
      final idEndereco = _currentUserInfo['endereco']?['id_Endereco'];
      if (idEndereco == null) throw Exception('ID do endereço não encontrado');

      // Salvar o ID do endereço no SecureStorage para uso posterior
      await _secureStorage.setEnderecoId(idEndereco.toString());

      // Busca dados da loja + avaliações
      final response = await http.get(
        Uri.parse(
            'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetReviewByStore?idLoja=$idEndereco'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        final responseData = jsonDecode(response.body);
        setState(() {
          storeData = responseData;
          _mercadoPagoKeyMissing =
              responseData['loja']?['access_token'] == null ||
                  responseData['loja']['access_token'].toString().isEmpty;
          _isLoading = false;
        });
        // Salva token se presente
        final hasAccessToken = responseData['loja']?['access_token'] != null &&
            responseData['loja']['access_token'].toString().isNotEmpty;
        if (hasAccessToken) {
          await _secureStorage
              .setMercadoPagoToken(responseData['loja']['access_token']);
          await _secureStorage.setMercadoPagoSkipped(false);
        }
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar loja: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _navigateToEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorEditPage(
          userInfo: _currentUserInfo,
          storeData: storeData ?? {},
          onSave: (updatedData) {
            setState(() {
              storeData = updatedData;
            });
          },
        ),
      ),
    );
  }

  void _navigateToMercadoPagoKeyScreen() async {
    // Navegar para MercadoPagoKeyScreen SEM mostrar o alerta (showAlertOnEntry: false)
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const MercadoPagoKeyScreen(showAlertOnEntry: false),
      ),
    );
    // Recarregar dados da loja ao retornar
    _loadStoreData();
  }

  // Exibe a média de avaliações, se disponível
  Widget? _buildRatingAverage() {
    // Busca média tanto do root quanto de 'loja' (compatível com ambas APIs)
    final media = storeData?['media_avaliacoes'] ??
        storeData?['loja']?['media_avaliacoes'];
    double avg = 5.0;
    if (media is num) {
      avg = media.toDouble();
    } else if (media != null) {
      avg = double.tryParse(media.toString()) ?? 5.0;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_border_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 4),
        Text(
          avg.toStringAsFixed(2),
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ALERTA: Exigir cadastro do token Mercado Pago antes de tudo
    if (_mercadoPagoKeyMissing) {
      Future.microtask(() async {
        final shouldGo = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Atenção!'),
            content: const Text(
              'Você precisa cadastrar o token do Mercado Pago para acessar as funcionalidades da loja.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Cadastrar agora'),
              ),
            ],
          ),
        );
        if (shouldGo == true) {
          _navigateToMercadoPagoKeyScreen();
        }
      });
    }

    final loja = storeData?['loja'] ?? storeData?['endereco'] ?? {};
    final storeName = loja['nome_Loja'] ?? 'Sua Loja';
    final storeDescription = loja['descricao_Loja'] ?? 'Sem descrição';
    final userName =
        widget.userInfo['usuario']?['nome'] ?? 'Nome não disponível';
    final userPhone =
        widget.userInfo['usuario']?['telefone'] ?? 'Telefone não disponível';
    final storeAddress = '${loja['logradouro'] ?? ''}, ${loja['numero'] ?? ''}';
    final storeComplement = loja['complemento'] ?? '';
    final deliveryType = loja['tipo_Entrega'] ?? 'Não especificado';
    final storeCep = loja['cep'] ?? '';

    // Imagem da loja (compatível com ambos formatos)
    String? imageUrl = loja['imagem_url'];
    String? idImagem = loja['id_Imagem']?.toString();
    if ((imageUrl == null || imageUrl.isEmpty) &&
        idImagem != null &&
        idImagem.isNotEmpty) {
      imageUrl = 'https://loja-profile-pictures.s3.amazonaws.com/$idImagem';
    }
    Widget storeImageWidget =
        Icon(Icons.store, size: 40, color: AppTheme.primaryColor);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      storeImageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 110,
        height: 110,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.store, size: 40, color: AppTheme.primaryColor),
      );
    }

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(storeName),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEditPage,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                physics: BouncingScrollPhysics(),
                children: [
                  // Cabeçalho com informações da loja
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).round()),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: storeData?['endereco'] != null &&
                                  storeData!['endereco']['id_Imagem'] != null &&
                                  storeData!['endereco']['id_Imagem']
                                      .toString()
                                      .isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    'https://loja-profile-pictures.s3.amazonaws.com/${storeData?['endereco']['id_Imagem']}',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.grey[200],
                                      child: Icon(Icons.store,
                                          size: 40, color: Colors.grey),
                                    ),
                                  ),
                                )
                              : ClipOval(
                                  child: SizedBox(
                                    width: 110,
                                    height: 110,
                                    child: storeImageWidget,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              storeName,
                              style: AppTheme.onPrimaryTextStyle.copyWith(
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (_buildRatingAverage() != null)
                              _buildRatingAverage()!,
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          storeDescription,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Remover chamada duplicada da avaliação abaixo do nome
                        // _buildRatingAverage() ?? const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Widget de Alerta para Chave Mercado Pago - exibido apenas se o access_token estiver ausente na API
                  if (_mercadoPagoKeyMissing)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: _navigateToMercadoPagoKeyScreen,
                        child: Card(
                          color: Colors.red[50],
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.red[700], size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Clique aqui para cadastrar seu token do Mercado Pago e receber pagamentos.',
                                    style: TextStyle(
                                        color: Colors.red[900],
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios,
                                    color: Colors.red[700], size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Conteúdo principal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: ExpansionTile(
                            initiallyExpanded: _infoExpanded,
                            onExpansionChanged: (val) {
                              setState(() => _infoExpanded = val);
                            },
                            leading:
                                Icon(Icons.info, color: AppTheme.accentColor),
                            title: Text(
                              'Informações da Loja',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, bottom: 16),
                                child: Column(
                                  children: [
                                    AppTheme.buildInfoCard(
                                      icon: Icons.person,
                                      title: 'Proprietário',
                                      value: userName,
                                    ),
                                    AppTheme.buildInfoCard(
                                      icon: Icons.phone,
                                      title: 'Telefone',
                                      value: userPhone,
                                    ),
                                    AppTheme.buildInfoCard(
                                      icon: Icons.location_on,
                                      title: 'Endereço',
                                      value:
                                          '$storeAddress${storeComplement.isNotEmpty ? ' - $storeComplement' : ''}',
                                    ),
                                    AppTheme.buildInfoCard(
                                      icon: Icons.local_shipping,
                                      title: 'Tipo de Entrega',
                                      value: deliveryType,
                                    ),
                                    AppTheme.buildInfoCard(
                                      icon: Icons.location_city,
                                      title: 'CEP',
                                      value: storeCep,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppTheme.buildSectionHeader(
                            'Ações Rápidas', Icons.flash_on),
                        const SizedBox(height: 15),
                        // Substituir Row por Wrap para evitar quebra de botões em telas pequenas
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            AppTheme.buildActionButton(
                              label: 'Produtos',
                              icon: Icons.shopping_bag,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VendorProductsPage(),
                                  ),
                                );
                              },
                            ),
                            AppTheme.buildActionButton(
                              label: 'Pedidos',
                              icon: Icons.receipt_long,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrdersVendorPage(
                                      deliveryType: deliveryType,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppTheme.buildActionButton(
                              label: 'Desempenho',
                              icon: Icons.bar_chart,
                              onPressed: () {
                                final idLoja = storeData?['loja']
                                            ?['id_Endereco']
                                        ?.toString() ??
                                    storeData?['endereco']?['id_Endereco']
                                        ?.toString();
                                if (idLoja != null && idLoja.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VendorMetricsPage(idLoja: idLoja),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('ID da loja não encontrado.')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: AppTheme.buildActionButton(
                                label: 'Mercado Pago',
                                icon: Icons.payment,
                                onPressed: _navigateToMercadoPagoKeyScreen,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if ((storeData?['avaliacoes'] as List?)
                                    ?.isNotEmpty ??
                                false)
                              Expanded(
                                child: AppTheme.buildActionButton(
                                  label: 'Ver Avaliações',
                                  icon: Icons.star_rate,
                                  onPressed: () {
                                    final idLoja = storeData?['loja']
                                            ?['id_Endereco']
                                        ?.toString();
                                    if (idLoja != null && idLoja.isNotEmpty) {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(24)),
                                        ),
                                        builder: (context) =>
                                            VendorReviewsSheet(idLoja: idLoja),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'ID da loja não encontrado.')),
                                      );
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
