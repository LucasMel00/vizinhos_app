import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> paymentData;
  final double totalAmount;

  const PaymentSuccessScreen({
    super.key,
    required this.paymentData,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final pixCode = paymentData['qr_code'] ??
        paymentData['point_of_interaction']?['transaction_data']?['qr_code'];

    final pixImageBase64 = paymentData['qr_code_base64'] ??
        paymentData['point_of_interaction']?['transaction_data']
            ?['qr_code_base64'];

    final status = paymentData['status'] ?? 'pending';
    final paymentId = paymentData['id']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento via PIX'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Pagamento gerado com sucesso!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${_getStatusText(status)}',
              style: TextStyle(
                fontSize: 18,
                color: status == 'approved' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),

            // Card com resumo do pagamento
            _buildInfoCard(
              title: 'Resumo do Pagamento',
              children: [
                _buildInfoRow('Valor total:', _formatCurrency(totalAmount)),
                _buildInfoRow('ID da transação:', paymentId),
                _buildInfoRow('Método:', 'PIX'),
                _buildInfoRow('Status:', _getStatusText(status)),
              ],
            ),

            const SizedBox(height: 25),

            // Seção do QR Code
            if (pixImageBase64 != null || pixCode != null)
              _buildPixSection(context, pixImageBase64, pixCode),

            const SizedBox(height: 30),

            // Botão de ação
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HomePage()),
                  );
                },
                child: const Text(
                  'Voltar ao início',
                  style: TextStyle(
                    fontSize: 18,
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

  Widget _buildPixSection(
      BuildContext context, String? pixImageBase64, String? pixCode) {
    Uint8List? pixImageBytes;

    if (pixImageBase64 != null) {
      try {
        // Remove o cabeçalho data:image/png;base64, se existir
        final base64String = pixImageBase64.replaceFirst(
            RegExp(r'data:image\/[^;]+;base64,'), '');
        pixImageBytes = base64.decode(base64String);
      } catch (e) {
        debugPrint('Erro ao decodificar QR Code: $e');
      }
    }

    return Column(
      children: [
        const Text(
          'Complete seu pagamento',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Escaneie o QR Code ou copie o código PIX abaixo:',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // QR Code
        if (pixImageBytes != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.memory(
              pixImageBytes,
              height: 250,
              width: 250,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
            ),
          )
        else if (pixCode != null)
          const Text(
            'QR Code não disponível',
            style: TextStyle(color: Colors.red),
          ),

        const SizedBox(height: 25),

        // Código PIX
        if (pixCode != null)
          Column(
            children: [
              const Text(
                'Código PIX:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    SelectableText(
                      pixCode,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copiar código'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: pixCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código PIX copiado!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'rejected':
        return 'Rejeitado';
      default:
        return status;
    }
  }
}
