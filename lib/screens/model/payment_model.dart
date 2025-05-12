class PaymentResult {
  final String status; // ex: "pending"
  final String qrCode; // payload para copiar
  final String qrCodeBase64; // imagem codificada

  PaymentResult({
    required this.status,
    required this.qrCode,
    required this.qrCodeBase64,
  });
}
