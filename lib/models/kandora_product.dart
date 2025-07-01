class KandoraProduct {
  final String id;
  final String name;
  final double fabricYardsRequired;
  final String? description;
  final bool isActive;
  final String tenantId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const KandoraProduct({
    required this.id,
    required this.name,
    required this.fabricYardsRequired,
    this.description,
    required this.isActive,
    required this.tenantId,
    required this.createdAt,
    this.updatedAt,
  });

  factory KandoraProduct.fromJson(Map<String, dynamic> json) {
    return KandoraProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      fabricYardsRequired: (json['fabric_yards_required'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      tenantId: json['tenant_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fabric_yards_required': fabricYardsRequired,
      'description': description,
      'is_active': isActive,
      'tenant_id': tenantId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  KandoraProduct copyWith({
    String? id,
    String? name,
    double? fabricYardsRequired,
    String? description,
    bool? isActive,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KandoraProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      fabricYardsRequired: fabricYardsRequired ?? this.fabricYardsRequired,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'KandoraProduct(id: $id, name: $name, fabricYardsRequired: $fabricYardsRequired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KandoraProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
