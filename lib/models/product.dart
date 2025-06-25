class Product {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String unit;
  final String type; // 'fabric', 'accessory', 'custom'

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.unit,
    required this.type,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      unit: json['unit'] as String,
      type: json['type'] as String? ?? 'custom',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'unit': unit,
      'type': type,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? unit,
    String? type,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      unit: unit ?? this.unit,
      type: type ?? this.type,
    );
  }
}
