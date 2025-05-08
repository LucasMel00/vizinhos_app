import 'dart:convert';

class Lote {
  final String idLote;
  final String fkIdProduto;
  final String dtFabricacao; // Consider using DateTime if needed
  final String quantidade; // Consider using int or double
  final String valorVendaDesc; // Consider using double

  Lote({
    required this.idLote,
    required this.fkIdProduto,
    required this.dtFabricacao,
    required this.quantidade,
    required this.valorVendaDesc,
  });

  factory Lote.fromJson(Map<String, dynamic> json) {
    return Lote(
      idLote: json['id_Lote'] ?? '',
      fkIdProduto: json['fk_id_Produto'] ?? '',
      dtFabricacao: json['dt_fabricacao'] ?? '',
      quantidade: json['quantidade'] ?? '',
      valorVendaDesc: json['valor_venda_desc'] ?? '',
    );
  }
}

