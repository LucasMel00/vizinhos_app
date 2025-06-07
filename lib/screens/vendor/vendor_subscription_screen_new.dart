import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/screens/login/login_email_screen.dart';

class VendorSubscriptionScreen extends StatefulWidget {
  final String email;

  const VendorSubscriptionScreen({super.key, required this.email});

  @override
  State<VendorSubscriptionScreen> createState() => _VendorSubscriptionScreenState();
}

class _VendorSubscriptionScreenState extends State<VendorSubscriptionScreen>
    with TickerProviderStateMixin {
  String? selectedPlan;
  bool isLoading = false;
  Map<String, dynamic>? paymentData;
  Uint8List? _qrCodeBytes;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Map<String, Map<String, dynamic>> plans = {
    'one_month': {
      'title': 'Plano Mensal',
      'price': 50.00,
      'originalPrice': 50.00,
      'discount': 0,
      'duration': '1 mês',
      'description': 'Ideal para começar',
      'features': [
        'Venda ilimitada de produtos',
        'Dashboard de vendas',
        'Suporte básico',
        'Análise de métricas básicas',
      ],
      'color': Colors.blue,
      'popular': false,
    },
    'three_month': {
      'title': 'Plano Trimestral',
      'price': 120.00,
      'originalPrice': 150.00,
      'discount': 30,
      'duration': '3 meses',
      'description': 'Mais popular',
      'features': [
        'Tudo do plano mensal',
        'Desconto de 20%',
      ],
      'color': Color(0xFFFbbc2c),
      'popular': true,
    },
    'six_month': {
      'title': 'Plano Semestral',
      'price': 220.00,
      'originalPrice': 360.00,
      'discount': 140,
      'duration': '6 meses',
      'description': 'Melhor custo-benefício',
      'features': [
        'Tudo do plano trimestral',
        'Desconto de ~39%',
      ],
      'color': Colors.green,
      'popular': false,
    },
  };


  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _createSubscription() async {
    if (selectedPlan == null) {
      _showSnackBar('Por favor, selecione um plano primeiro.', Colors.redAccent);
      return;
    }

    setState(() {
      isLoading = true;
      _qrCodeBytes = null;
      paymentData = null;
    });

    try {
      final Map<String, dynamic> requestBody = {
        'email': widget.email,
        'vendor_plan': selectedPlan!,
      };

      final response = await http.post(
        Uri.parse('https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/VendorSubscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        Uint8List? decodedBytes;

        if (responseData.containsKey('qr_code_base64')) {
          final qrBase64 = responseData['qr_code_base64'] as String?;
          if (qrBase64 != null && qrBase64.isNotEmpty) {
             try {
               final String pureBase64 = qrBase64.startsWith('data:image')
                   ? qrBase64.substring(qrBase64.indexOf(',') + 1)
                   : qrBase64;
               decodedBytes = base64Decode(pureBase64);
             } catch (e) {
               print('[VendorSubscriptionScreen] Base64 decode failed: $e');
             }
          } else {
             print('[VendorSubscriptionScreen] Received empty or null qr_code_base64 string.');
          }
        } else {
           print('[VendorSubscriptionScreen] Response does not contain qr_code_base64 key.');
        }

        setState(() {
          paymentData = responseData;
          _qrCodeBytes = decodedBytes;
        });

        _showPaymentScreen();
        if (_qrCodeBytes == null) {
           _showSnackBar('Assinatura criada, mas houve um problema ao gerar o QR Code. Use o código PIX.', Colors.orangeAccent);
        }

      } else {
        String errorMessage = 'Erro ao criar assinatura.';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('message')) {
            errorMessage = decoded['message'] ?? errorMessage;
          }
        } catch (e) {
        }
        _showSnackBar(errorMessage, Colors.redAccent);
      }
    } catch (e) {
      print('[VendorSubscriptionScreen] Connection Error: $e');
      _showSnackBar('Erro de conexão. Verifique sua internet.', Colors.redAccent);
    } finally {
      if (mounted) {
         setState(() {
           isLoading = false;
         });
      }
    }
  }

  void _showPaymentScreen() {
    if (paymentData == null && !isLoading) {
       print("[VendorSubscriptionScreen] Payment data is null, not showing modal.");
       return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentModal(),
    );
  }

  void _navigateToLogin() {
    if (mounted) {
       if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
       }

       Navigator.pushAndRemoveUntil(
         context,
         MaterialPageRoute(builder: (context) => LoginEmailScreen(email: widget.email)),
         (Route<dynamic> route) => false,
       );
    }
  }

  Widget _buildPaymentModal() {
    if (paymentData == null) {
      return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: const Center(child: CircularProgressIndicator(color: Color(0xFFFbbc2c)))
      );
    }

    final transactionAmount = paymentData!['transaction_ammount'] ?? 0.0;
    final qrCodePix = paymentData!['qr_code'] as String?;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pagamento PIX',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFbbc2c),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _navigateToLogin();
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                  tooltip: 'Fechar e ir para Login',
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Valor a pagar:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'R\$ ${transactionAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFbbc2c),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      'Escaneie o QR Code para pagar:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildQRCodeImage(),

                    const SizedBox(height: 24),

                    if (qrCodePix != null && qrCodePix.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ou copie o código PIX:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    qrCodePix,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontFamily: 'monospace',
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: qrCodePix),
                                    );
                                    _showSnackBar('Código PIX copiado!', Colors.green);
                                  },
                                  icon: const Icon(
                                    Icons.copy,
                                    size: 20,
                                    color: Color(0xFFFbbc2c),
                                  ),
                                  tooltip: 'Copiar Código PIX',
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                       Padding(
                         padding: const EdgeInsets.symmetric(vertical: 16.0),
                         child: Text(
                           'Código PIX não disponível.',
                           style: TextStyle(color: Colors.grey[600]),
                         ),
                       ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _navigateToLogin();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFbbc2c),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Concluir e Ir para Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeImage() {
    if (_qrCodeBytes == null) {
      return _buildErrorPlaceholder('QR Code indisponível');
    }

    return Container(
      width: 240,
      height: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Image.memory(
        _qrCodeBytes!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('[VendorSubscriptionScreen] Error rendering stored QR bytes: $error');
          return _buildErrorPlaceholder('Erro ao exibir QR Code');
        },
      ),
    );
  }

  Widget _buildErrorPlaceholder(String message) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Tente usar o código PIX abaixo ou contate o suporte se o problema persistir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assinatura de Vendedor'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Escolha seu Plano',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFbbc2c)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione o plano que melhor se adapta às suas necessidades.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ...plans.entries.map((entry) {
                    return _buildPlanCard(entry.key, entry.value);
                  }).toList(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _createSubscription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFbbc2c),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Criar Assinatura e Pagar', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                   TextButton(
                     onPressed: isLoading ? null : () => Navigator.maybePop(context),
                     child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                   ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFbbc2c)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String planKey, Map<String, dynamic> plan) {
    final isSelected = selectedPlan == planKey;
    final isPopular = plan['popular'] as bool? ?? false;
    final color = plan['color'] as Color? ?? Colors.grey;
    final price = plan['price'] as double? ?? 0.0;
    final originalPrice = plan['originalPrice'] as double?;
    final discount = plan['discount'] as num?;

    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan['title'] ?? 'Plano',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Popular',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'R\$ ${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.black,
                ),
              ),
              Text(
                ' / ${plan['duration'] ?? ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (originalPrice != null && discount != null && discount > 0 && originalPrice > price)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                 children: [
                   Text(
                     'De R\$ ${originalPrice.toStringAsFixed(2)}',
                     style: TextStyle(
                       fontSize: 12,
                       color: Colors.grey[500],
                       decoration: TextDecoration.lineThrough,
                     ),
                   ),
                   const SizedBox(width: 8),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                     decoration: BoxDecoration(
                       color: Colors.redAccent.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(4)
                     ),
                     child: Text(
                       'Economize R\$ ${(originalPrice - price).toStringAsFixed(2)}',
                       style: const TextStyle(
                         fontSize: 10,
                         color: Colors.redAccent,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   )
                 ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            plan['description'] ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          if (plan['features'] is List)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (plan['features'] as List).map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature.toString(), style: const TextStyle(fontSize: 13))), // Ensure feature is string
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );

    Widget animatedCard = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.05) : Colors.white,
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2.5 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: cardContent,
    );

    if (isPopular) {
      animatedCard = ScaleTransition(
        scale: _pulseAnimation,
        child: animatedCard,
      );
    }

    return GestureDetector(
      onTap: () {
        if (!isLoading) {
           setState(() {
             selectedPlan = planKey;
           });
        }
      },
      child: animatedCard,
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(15, 5, 15, 10),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

