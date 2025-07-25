enum FamilyRelation {
  parent,
  spouse,
  child,
  sibling,
  other
}

class Customer {
  final String id;
  final String billNumber;
  final String name;
  final String phone;
  final String whatsapp;
  final String address;
  final Gender gender;
  final DateTime createdAt;
  final String? referredBy; // UUID of referring customer
  final int referralCount; // Number of customers referred
  final String? familyId; // UUID of family head customer
  final FamilyRelation? familyRelation; // Relationship to family head

  Customer({
    required this.id,
    required this.billNumber,
    required this.name,
    required this.phone,
    this.whatsapp = '',
    required this.address,
    required this.gender,
    DateTime? createdAt,
    this.referredBy, // Initialize the new field
    this.referralCount = 0,
    this.familyId,
    this.familyRelation,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Customer.fromJson(Map<String, dynamic> json) => Customer.fromMap(json);

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      billNumber: map['bill_number'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      address: map['address'] ?? '',
      gender: map['gender'] == 'female' ? Gender.female : Gender.male,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      referredBy: map['referred_by'], // Retrieve referred_by from map
      referralCount: map['referral_count'] ?? 0,
      familyId: map['family_id'],
      familyRelation: map['family_relation'] != null 
          ? FamilyRelation.values.firstWhere(
              (e) => e.name == map['family_relation'],
              orElse: () => FamilyRelation.other,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_number': billNumber,
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'address': address,
      'gender': gender.name,
      'created_at': createdAt.toIso8601String(),
      'referred_by': referredBy,
      'referral_count': referralCount,
      'family_id': familyId,
      'family_relation': familyRelation?.name,
    };
  }

  // Add helper method to get relation display text
  String get familyRelationDisplay {
    if (familyRelation == null) return '';
    switch (familyRelation!) {
      case FamilyRelation.parent: return 'Parent';
      case FamilyRelation.spouse: return 'Spouse';
      case FamilyRelation.child: return 'Child';
      case FamilyRelation.sibling: return 'Sibling';
      case FamilyRelation.other: return 'Family Member';
    }
  }
}

enum Gender { male, female }
