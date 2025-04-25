import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vizinhos_app/screens/vendor/vendor_create_product_page.dart';
import 'package:vizinhos_app/screens/vendor/vendor_edit_product_page.dart';
import 'dart:typed_data'; // Import necessário para manipulação de base64

final primaryColor = const Color(0xFFFbbc2c);
final storage = FlutterSecureStorage();

class Product {
  final String nome;
  final String descricao;
  final double valorVenda;
  final bool disponivel;
  final String categoria;
  final String? imagemUrl;
  final List<String> caracteristicas;
  final String? imagemBase64;

  Product({
    required this.nome,
    required this.descricao,
    required this.valorVenda,
    required this.disponivel,
    required this.categoria,
    this.imagemUrl,
    required this.caracteristicas,
    this.imagemBase64, // Nova propriedade para imagem em base64
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Garantir que 'valor_venda' seja convertido corretamente
    var valorVenda = json['valor_venda'];
    double valorVendaConvertido = 0.0;

    if (valorVenda is String) {
      valorVendaConvertido = double.tryParse(valorVenda) ?? 0.0;
    } else if (valorVenda is num) {
      valorVendaConvertido = valorVenda.toDouble();
    }

    return Product(
      nome: json['nome'],
      descricao: json['descricao'],
      valorVenda: valorVendaConvertido,
      disponivel: json['disponivel'],
      categoria: json['categoria'] ?? 'Sem categoria',
      imagemUrl: json['imagem_url'],
      caracteristicas: List<String>.from(json['caracteristicas'] ?? []),
      imagemBase64: json['id_imagem'], // Adicionando a imagem em base64
    );
  }
}

class VendorProductsPage extends StatefulWidget {
  @override
  _VendorProductsPageState createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage> {
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  // Função para recarregar os produtos
  Future<void> loadProducts() async {
    try {
      final enderecoId = await storage.read(key: 'id_Endereco');
      if (enderecoId == null) return;

      final uri = Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetProductsByStore?fk_id_Endereco=$enderecoId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final produtos = List<Product>.from(
          (data['produtos'] as List).map((item) => Product.fromJson(item)),
        );

        if (mounted) {
          // Verificação se o widget ainda está montado
          setState(() {
            products = produtos;
            isLoading = false;
          });
        }
      } else {
        print('Erro ao carregar produtos: ${response.body}');
        if (mounted) {
          // Verificação se o widget ainda está montado
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print('Erro: $e');
      if (mounted) {
        // Verificação se o widget ainda está montado
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Produtos',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: primaryColor, height: 2),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: loadProducts, // Função que recarrega os produtos
              color: primaryColor, // Cor do indicador de atualização
              child: products.isEmpty
                  ? Center(child: Text('Nenhum produto encontrado.'))
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0.5,
                          color: Color(0xFFF9F5ED),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: Colors.grey[200],
                                      ),
                                      child: p.imagemBase64 != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.memory(
                                                base64Decode(p.imagemBase64!),
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : p.imagemUrl != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Image.network(
                                                    p.imagemUrl!,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Icon(Icons.image,
                                                  color: Colors.grey),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(p.nome,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                          Text(
                                            p.descricao,
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: primaryColor, size: 20),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  EditProductScreen()),
                                        );
                                      },
                                      tooltip: 'Editar',
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                        'R\$${p.valorVenda.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    Spacer(),
                                    Switch(
                                      value: p.disponivel,
                                      onChanged: (_) {},
                                      activeColor: primaryColor,
                                    )
                                  ],
                                ),
                                SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  child: Text(
                                    p.categoria,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                // Exibição das características com cor diferente
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 233, 165, 40), // Cor diferente
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  child: Text(
                                    'Características: ${p.caracteristicas.join(', ')}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateProductScreen()),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
