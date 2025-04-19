import 'package:flutter/material.dart';

final primaryColor = const Color(0xFFFbbc2c);

class CreateProductScreen extends StatefulWidget {
  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  int lotQuantity = 0;
  String category = 'Doce';

  // Controllers para os campos
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final discountController = TextEditingController();
  final costController = TextEditingController();
  final validityController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    discountController.dispose();
    costController.dispose();
    validityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Criar produto',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: primaryColor),
            onPressed: () {},
            tooltip: 'Adicionar imagem',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Container(
            color: primaryColor,
            height: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem do produto
              Center(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(Icons.image, size: 40, color: Colors.grey[400]),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: primaryColor,
                        shape: CircleBorder(),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child:
                                Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28),

              TextFormField(
                controller: nameController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Nome do produto',
                  hintText: 'Ex: Bolo',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o nome' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                maxLines: 2,
                decoration: inputDecoration.copyWith(
                  labelText: 'Descrição',
                  hintText: 'Ex: Bolo caseiro de chocolate...',
                ),
              ),
              SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Preço',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: discountController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Preço desconto',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),

              TextFormField(
                controller: costController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Custo produção',
                  prefixText: 'R\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 14),

              TextFormField(
                controller: validityController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Dias validade',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: category,
                items: ['Doce', 'Salgado', 'Bebida']
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    category = value!;
                  });
                },
                decoration: inputDecoration.copyWith(
                  labelText: 'Categoria',
                ),
              ),
              SizedBox(height: 18),

              Text(
                'Lotes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lote 1234',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          SizedBox(height: 2),
                          Text(
                            'Data fabricação: 05/03/2025',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove, color: primaryColor),
                      onPressed: () {
                        setState(() {
                          if (lotQuantity > 0) lotQuantity--;
                        });
                      },
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    Container(
                      width: 32,
                      alignment: Alignment.center,
                      child: Text(
                        lotQuantity.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: primaryColor, size: 22),
                      onPressed: () {
                        setState(() {
                          lotQuantity++;
                        });
                      },
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Salvar produto
                    }
                  },
                  child: Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
