class Customer {
  final String id;
  final String billNumber;
  final String name;
  final String phone;
  final String whatsapp;
  final String address;
  final Gender gender;
  final DateTime createdAt;
  final String? referredBy; // New field for customer reference

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
  }) : createdAt = createdAt ?? DateTime.now();

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      billNumber: map['bill_number'],
      name: map['name'],
      phone: map['phone'],
      whatsapp: map['whatsapp'] ?? '',
      address: map['address'],
      gender: map['gender'] == 'female' ? Gender.female : Gender.male,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      referredBy: map['referred_by'], // Retrieve referred_by from map
    );
  }
}

enum Gender { male, female }
