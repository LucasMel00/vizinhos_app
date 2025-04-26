class Characteristic {
  final String id;
  final String descricao;

  Characteristic({required this.id, required this.descricao});

  factory Characteristic.fromJson(Map<String, dynamic> json) {
    return Characteristic(
      id: json['id_Caracteristica'],
      descricao: json['descricao'],
    );
  }
}
