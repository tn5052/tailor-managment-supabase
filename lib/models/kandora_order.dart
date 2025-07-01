class KandoraOrder {
  final String id;
  final String invoiceId;
  final String kandoraProductId;
  final String fabricInventoryId;
  final double fabricYardsConsumed;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;
  final String tenantId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Additional fields for detailed view
  final String? kandoraName;
  final double? fabricYardsRequired;
  final String? fabricItemName;
  final String? shadeColor;
  final String? fabricCode;
  final String? invoiceNumber;
  final String? customerName;

  const KandoraOrder({
    required this.id,
    required this.invoiceId,
    required this.kandoraProductId,
    required this.fabricInventoryId,
    required this.fabricYardsConsumed,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.tenantId,
    required this.createdAt,
    this.updatedAt,
    // Additional fields
    this.kandoraName,
    this.fabricYardsRequired,
    this.fabricItemName,
    this.shadeColor,
    this.fabricCode,
    this.invoiceNumber,
    this.customerName,
  });

  factory KandoraOrder.fromJson(Map<String, dynamic> json) {
    return KandoraOrder(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      kandoraProductId: json['kandora_product_id'] as String,
      fabricInventoryId: json['fabric_inventory_id'] as String,
      fabricYardsConsumed: (json['fabric_yards_consumed'] as num).toDouble(),
      quantity: json['quantity'] as int,
      pricePerUnit: (json['price_per_unit'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      tenantId: json['tenant_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      // Additional fields from view
      kandoraName: json['kandora_name'] as String?,
      fabricYardsRequired: json['fabric_yards_required'] != null 
          ? (json['fabric_yards_required'] as num).toDouble() 
          : null,
      fabricItemName: json['fabric_item_name'] as String?,
      shadeColor: json['shade_color'] as String?,
      fabricCode: json['fabric_code'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      customerName: json['customer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'kandora_product_id': kandoraProductId,
      'fabric_inventory_id': fabricInventoryId,
      'fabric_yards_consumed': fabricYardsConsumed,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
      'tenant_id': tenantId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    // For inserting new records (without id, timestamps)
    return {
      'invoice_id': invoiceId,
      'kandora_product_id': kandoraProductId,
      'fabric_inventory_id': fabricInventoryId,
      'fabric_yards_consumed': fabricYardsConsumed,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
      'tenant_id': tenantId,
    };
  }

  KandoraOrder copyWith({
    String? id,
    String? invoiceId,
    String? kandoraProductId,
    String? fabricInventoryId,
    double? fabricYardsConsumed,
    int? quantity,
    double? pricePerUnit,
    double? totalPrice,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? kandoraName,
    double? fabricYardsRequired,
    String? fabricItemName,
    String? shadeColor,
    String? fabricCode,
    String? invoiceNumber,
    String? customerName,
  }) {
    return KandoraOrder(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      kandoraProductId: kandoraProductId ?? this.kandoraProductId,
      fabricInventoryId: fabricInventoryId ?? this.fabricInventoryId,
      fabricYardsConsumed: fabricYardsConsumed ?? this.fabricYardsConsumed,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalPrice: totalPrice ?? this.totalPrice,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      kandoraName: kandoraName ?? this.kandoraName,
      fabricYardsRequired: fabricYardsRequired ?? this.fabricYardsRequired,
      fabricItemName: fabricItemName ?? this.fabricItemName,
      shadeColor: shadeColor ?? this.shadeColor,
      fabricCode: fabricCode ?? this.fabricCode,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
    );
  }

  @override
  String toString() {
    return 'KandoraOrder(id: $id, kandoraName: $kandoraName, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KandoraOrder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper method to get display name for invoice
  String get displayName => kandoraName ?? 'Kandora';
  
  // Helper method to get fabric details for display
  String get fabricDetails => fabricItemName != null && shadeColor != null 
      ? '$fabricItemName - $shadeColor' 
      : 'Fabric';
}
