

class Lote {
  final String idLote;
  final String fkIdProduto;
  final String dtFabricacao;
  final int quantidade;
  final double valorVendaDesc;

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
      quantidade: int.tryParse(json['quantidade']?.toString() ?? '0') ?? 0,
      valorVendaDesc: double.tryParse(json['valor_venda_desc']?.toString() ?? '0') ?? 0.0,
    );
  }

  // Adicione este método
  Map<String, dynamic> toJson() {
    return {
      'id_Lote': idLote,
      'fk_id_Produto': fkIdProduto,
      'dt_fabricacao': dtFabricacao,
      'quantidade': quantidade.toString(),
      'valor_venda_desc': valorVendaDesc.toString(),
    };
  }
}