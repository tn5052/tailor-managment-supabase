class InvoiceProduct {
  final String id;
  String name;
  String description;
  double unitPrice;
  int quantity;
  String unit;
  String? inventoryId;
  String? inventoryType;

  InvoiceProduct({
    required this.id,
    required this.name,
    this.description = '',
    required this.unitPrice,
    required this.quantity,
    required this.unit,
    this.inventoryId,
    this.inventoryType,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'unit': unit,
      'inventoryId': inventoryId,
      'inventoryType': inventoryType,
    };
  }

  factory InvoiceProduct.fromJson(Map<String, dynamic> json) {
    return InvoiceProduct(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'],
      unit: json['unit'],
      inventoryId: json['inventoryId'],
      inventoryType: json['inventoryType'],
    );
  }
}
