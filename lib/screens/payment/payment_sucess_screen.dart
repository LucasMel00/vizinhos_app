import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vizinhos_app/screens/User/home_page_user.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;
  // Removi totalAmount do construtor pois vamos usar o valor da API diretamente
  const PaymentSuccessScreen({
    super.key,
    required this.orderData, required double totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    // Extrair dados do pagamento da resposta da API
    final paymentData = orderData['pagamento'] ?? {};
    final transactionAmount = (paymentData['transaction_ammount'] ?? 0).toDouble();

    final pixCode = paymentData['qr_code'] ?? '';
    final pixImageBase64 = paymentData['qr_code_base64'] ?? '';
    final status = orderData['status_pedido'] ?? 'pending';
    final paymentId = paymentData['payment_id']?.toString() ?? '';
    final orderId = orderData['id_Pedido'] ?? '';
    final tipoEntrega = orderData['tipo_entrega'] ?? 'Retirada';

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
              'Pedido gerado com sucesso!',
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

            // Card com resumo do pedido
            _buildInfoCard(
              title: 'Resumo do Pedido',
              children: [
                _buildInfoRow('Número do Pedido:', orderId),
                _buildInfoRow('Valor total:', _formatCurrency(transactionAmount)),
                _buildInfoRow('Status:', _getStatusText(status)),
                _buildInfoRow('Data:', _formatDate(orderData['data_pedido'] ?? '')),
                _buildInfoRow('Tipo de entrega:', tipoEntrega),
              ],
            ),

            const SizedBox(height: 20),

            // Card com resumo do pagamento
            _buildInfoCard(
              title: 'Dados do Pagamento',
              children: [
                _buildInfoRow('ID da transação:', paymentId),
                _buildInfoRow('Método:', 'PIX'),
                _buildInfoRow('Status:', _getStatusText(status)),
              ],
            ),

            const SizedBox(height: 25),

            // Seção do QR Code
            if (pixImageBase64.isNotEmpty || pixCode.isNotEmpty)
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

    if (pixImageBase64 != null && pixImageBase64.isNotEmpty) {
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
        else if (pixCode != null && pixCode.isNotEmpty)
          const Text(
            'QR Code não disponível',
            style: TextStyle(color: Colors.red),
          ),

        const SizedBox(height: 25),

        // Código PIX
        if (pixCode != null && pixCode.isNotEmpty)
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
  
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
      case 'Pendente':
        return 'Pendente';
      case 'rejected':
        return 'Rejeitado';
      default:
        return status;
    }
  }
}
