class StoreModel {
  final String idLoja;
  final String nomeLoja;
  final String imagemLoja;
  final String enderecoLoja;
  final String cepLoja;
  final String tipo_Entrega;

  StoreModel({
    required this.idLoja,
    required this.nomeLoja,
    required this.imagemLoja,
    required this.enderecoLoja,
    required this.cepLoja,
    required this.tipo_Entrega,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      idLoja: json['id_loja']?.toString() ?? '',
      nomeLoja: json['nome_loja']?.toString() ?? '',
      imagemLoja: json['imagem_loja']?.toString() ?? '',
      enderecoLoja: json['endereco_loja']?.toString() ?? '',
      cepLoja: json['cep_loja']?.toString() ?? '',
      tipo_Entrega: json['tipo_entrega']?.toString() ?? '',
    );
  }
}

class ProductModel {
  final String nomeProduto;
  final String imagemProduto;
  final int quantidade;
  final double valorUnitario;
  final StoreModel loja;

  ProductModel({
    required this.nomeProduto,
    required this.imagemProduto,
    required this.quantidade,
    required this.valorUnitario,
    required this.loja,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Tratamento seguro para conversão de tipos
    int parseQuantidade(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    double parseValorUnitario(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return ProductModel(
      nomeProduto: json['nome_produto']?.toString() ?? '',
      imagemProduto: json['imagem_produto']?.toString() ?? '',
      quantidade: parseQuantidade(json['quantidade']),
      valorUnitario: parseValorUnitario(json['valor_unitario']),
      loja: StoreModel.fromJson(json['loja'] ?? {}),
    );
  }
}

class OrderModel {
  final String idPedido;
  final String idPagamento;
  final String statusPedido;
  final String? tipoEntrega;
  final double valorTotal;
  final String dataPedido;
  final String? qrCode;
  final String? qrCodeBase64;
  final List<ProductModel> produtos;
  final bool avaliacaoFeita; // true se já foi avaliado

  OrderModel({
    required this.idPedido,
    required this.idPagamento,
    required this.statusPedido,
    this.tipoEntrega,
    required this.valorTotal,
    required this.dataPedido,
    this.qrCode,
    this.qrCodeBase64,
    required this.produtos,
    this.avaliacaoFeita = false,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Tratamento seguro para conversão de tipos
    double parseValorTotal(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    List<ProductModel> produtosList = [];
    if (json['produtos'] != null) {
      produtosList = List<ProductModel>.from(
        (json['produtos'] as List).map(
          (produto) => ProductModel.fromJson(produto),
        ),
      );
    }

    return OrderModel(
      idPedido: json['id_Pedido']?.toString() ?? '',
      idPagamento: json['id_Pagamento']?.toString() ?? '',
      statusPedido: json['status_pedido']?.toString() ?? '',
      tipoEntrega: json['tipo_entrega']?.toString(),
      valorTotal: parseValorTotal(json['valor_total']),
      dataPedido: json['data_pedido']?.toString() ?? '',
      qrCode: json['qr_code']?.toString(),
      qrCodeBase64: json['qr_code_base64']?.toString(),
      produtos: produtosList,
      avaliacaoFeita: json['AvaliacaoFeita'] == true || json['AvaliacaoFeita'] == 'true' ? true : false,
    );
  }
}

class OrdersResponse {
  final List<OrderModel> pedidos;

  OrdersResponse({required this.pedidos});

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      pedidos: List<OrderModel>.from(
        (json['pedidos'] as List).map(
          (pedido) => OrderModel.fromJson(pedido),
        ),
      ),
    );
  }
}
