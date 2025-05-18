class PaymentResult {
  final String status; // ex: "pending"
  final String qrCode; // payload para copiar
  final String qrCodeBase64; // imagem codificada
  final String paymentId; // ID do pagamento
  final String orderId; // ID do pedido
  final double transactionAmount; // Valor da transação
  final String collectorId; // ID do recebedor

  PaymentResult({
    required this.status,
    required this.qrCode,
    required this.qrCodeBase64,
    required this.paymentId,
    required this.orderId,
    required this.transactionAmount,
    required this.collectorId,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    // Extrai dados do pagamento da resposta da API
    final paymentData = json['pagamento'] ?? {};
    
    return PaymentResult(
      status: json['status_pedido'] ?? 'pending',
      qrCode: paymentData['qr_code'] ?? '',
      qrCodeBase64: paymentData['qr_code_base64'] ?? '',
      paymentId: paymentData['payment_id']?.toString() ?? '',
      orderId: json['id_Pedido'] ?? '',
      transactionAmount: (paymentData['transaction_ammount'] ?? 0.0).toDouble(),
      collectorId: paymentData['collector_id']?.toString() ?? '',
    );
  }
}

class OrderResponse {
  final String orderId;
  final String? cpf;
  final double valor;
  final String tipoEntrega;
  final String statusPedido;
  final String dataPedido;
  final String horaAtualizacao;
  final PaymentResult payment;

  OrderResponse({
    required this.orderId,
    this.cpf,
    required this.valor,
    required this.tipoEntrega,
    required this.statusPedido,
    required this.dataPedido,
    required this.horaAtualizacao,
    required this.payment,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      orderId: json['id_Pedido'] ?? '',
      cpf: json['fk_Usuario_cpf'],
      valor: (json['valor'] ?? 0.0).toDouble(),
      tipoEntrega: json['tipo_entrega'] ?? '',
      statusPedido: json['status_pedido'] ?? '',
      dataPedido: json['data_pedido'] ?? '',
      horaAtualizacao: json['hora_atualizacao'] ?? '',
      payment: PaymentResult.fromJson(json),
    );
  }
}
