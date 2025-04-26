class Product {
  final String id;
  final String nome;
  final String descricao;
  final double valorVenda;
  final double valorCusto;
  final int diasValidade;
  final bool disponivel;
  final String categoria;
  List<String> caracteristicasIDs;
  final String? imagemUrl;
  final String? imagemBase64;
  final double? desconto;

  Product({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.valorVenda,
    required this.valorCusto,
    required this.diasValidade,
    required this.disponivel,
    required this.categoria,
    required this.caracteristicasIDs,
    this.imagemUrl,
    this.imagemBase64,
    this.desconto,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Corrigindo o mapeamento de características
    List<String> parseCharacteristics(dynamic characteristics) {
      if (characteristics == null) return [];
      if (characteristics is List) {
        return characteristics
            .map((e) => e.toString()) // Garante que todos os IDs são strings
            .where((id) => id.isNotEmpty) // Remove IDs vazios
            .toList();
      }
      return [];
    }

    return Product(
      id: json['id_Produto']?.toString() ??
          json['id_produto']?.toString() ??
          '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      valorVenda: _parseDouble(json['valor_venda']),
      valorCusto: _parseDouble(json['valor_custo']),
      diasValidade: _parseInt(json['dias_vcto']),
      disponivel: json['disponivel'] ?? false,
      categoria: json['categoria'] ?? 'Sem categoria',
      caracteristicasIDs: parseCharacteristics(
          json['caracteristicas_IDs']), // Usa a nova função
      imagemUrl: json['imagem_url'],
      imagemBase64: json['id_imagem'],
      desconto: _parseDouble(json['desconto']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_Produto': id,
      'nome': nome,
      'descricao': descricao,
      'valor_venda': valorVenda,
      'valor_custo': valorCusto,
      'dias_vcto': diasValidade,
      'disponivel': disponivel,
      'categoria': categoria,
      'caracteristicas_IDs': caracteristicasIDs,
      if (imagemBase64 != null) 'id_imagem': imagemBase64,
      if (desconto != null) 'desconto': desconto,
    };
  }
}
