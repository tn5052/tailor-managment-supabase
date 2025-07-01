import 'package:uuid/uuid.dart';

class InvoiceProduct {
  final String id;
  final String name;
  final String description;
  final double unitPrice;
  double quantity;
  final String unit;
  final String inventoryId;
  final String inventoryType; // 'fabric' or 'accessory'
  double? inventoryDeductionQuantity; // For Kandora yardage, etc.

  InvoiceProduct({
    required this.id,
    required this.name,
    this.description = '',
    required this.unitPrice,
    required this.quantity,
    required this.unit,
    required this.inventoryId,
    required this.inventoryType,
    this.inventoryDeductionQuantity,
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
      'inventoryDeductionQuantity': inventoryDeductionQuantity,
      'totalPrice': totalPrice,
    };
  }

  factory InvoiceProduct.fromJson(Map<String, dynamic> json) {
    return InvoiceProduct(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      unitPrice:
          (json['unitPrice'] ?? 0.0) is int
              ? (json['unitPrice'] as int).toDouble()
              : (json['unitPrice'] ?? 0.0),
      quantity:
          (json['quantity'] ?? 1.0) is int
              ? (json['quantity'] as int).toDouble()
              : (json['quantity'] ?? 1.0),
      unit: json['unit'] ?? 'pcs',
      inventoryId: json['inventoryId'],
      inventoryType: json['inventoryType'],
      inventoryDeductionQuantity:
          (json['inventoryDeductionQuantity'] as num?)?.toDouble(),
    );
  }

  InvoiceProduct copyWith({
    String? id,
    String? name,
    String? description,
    double? unitPrice,
    double? quantity,
    String? unit,
    String? inventoryId,
    String? inventoryType,
    double? inventoryDeductionQuantity,
  }) {
    return InvoiceProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      inventoryId: inventoryId ?? this.inventoryId,
      inventoryType: inventoryType ?? this.inventoryType,
      inventoryDeductionQuantity:
          inventoryDeductionQuantity ?? this.inventoryDeductionQuantity,
    );
  }
}
