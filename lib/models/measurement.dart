import 'dart:convert';

class Measurement {
  final String id;
  final String customerId;
  final String billNumber;
  final String style;
  final String designType;
  final String tarbooshType;
  final String fabricName;
  final String lengthArabi;
  final String lengthKuwaiti;
  final String chest;
  final String width;
  final String sleeve;
  final Map<String, String> collar;
  final String under;
  final String backLength;
  final String neck;
  final String shoulder;
  final String seam;
  final String adhesive;
  final String underKandura;
  final String tarboosh;
  final String openSleeve;
  final String stitching;
  final String pleat;
  final String button;
  final String cuff;
  final String embroidery;
  final String neckStyle;
  final String notes;
  final DateTime date;
  final DateTime lastUpdated;

  Measurement({
    required this.id,
    required this.customerId,
    required this.billNumber,
    required this.style,
    required this.designType,
    required this.tarbooshType,
    required this.fabricName,
    required this.lengthArabi,
    required this.lengthKuwaiti,
    required this.chest,
    required this.width,
    required this.sleeve,
    required this.collar,
    required this.under,
    required this.backLength,
    required this.neck,
    required this.shoulder,
    required this.seam,
    required this.adhesive,
    required this.underKandura,
    required this.tarboosh,
    required this.openSleeve,
    required this.stitching,
    required this.pleat,
    required this.button,
    required this.cuff,
    required this.embroidery,
    required this.neckStyle,
    required this.notes,
    required this.date,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'bill_number': billNumber,
      'style': style,
      'design_type': designType,
      'tarboosh_type': tarbooshType,
      'fabric_name': fabricName,
      'length_arabi': lengthArabi,
      'length_kuwaiti': lengthKuwaiti,
      'chest': chest,
      'width': width,
      'sleeve': sleeve,
      'collar': jsonEncode(collar),
      'under': under,
      'back_length': backLength,
      'neck': neck,
      'shoulder': shoulder,
      'seam': seam,
      'adhesive': adhesive,
      'under_kandura': underKandura,
      'tarboosh': tarboosh,
      'open_sleeve': openSleeve,
      'stitching': stitching,
      'pleat': pleat,
      'button': button,
      'cuff': cuff,
      'embroidery': embroidery,
      'neck_style': neckStyle,
      'notes': notes,
      'date': date.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    // Helper to safely parse collar
    Map<String, String> parseCollar(dynamic collarData) {
      if (collarData is String) {
        try {
          final decoded = jsonDecode(collarData);
          if (decoded is Map) {
            return Map<String, String>.from(
              decoded.map((key, value) => MapEntry(key, value.toString())),
            );
          }
        } catch (e) {
          // Ignore if not valid JSON
        }
      }
      if (collarData is Map) {
        return Map<String, String>.from(
          collarData.map((key, value) => MapEntry(key, value.toString())),
        );
      }
      return {'start': '0', 'center': '0', 'end': '0'};
    }

    return Measurement(
      id: map['id'] ?? '',
      customerId: map['customer_id'] ?? '',
      billNumber: map['bill_number'] ?? '',
      style: map['style'] ?? '',
      designType: map['design_type'] ?? 'Aadi',
      tarbooshType: map['tarboosh_type'] ?? 'Fixed',
      fabricName: map['fabric_name'] ?? '',
      lengthArabi: (map['length_arabi'] ?? '0').toString(),
      lengthKuwaiti: (map['length_kuwaiti'] ?? '0').toString(),
      chest: (map['chest'] ?? '0').toString(),
      width: (map['width'] ?? '0').toString(),
      sleeve: (map['sleeve'] ?? '0').toString(),
      collar: parseCollar(map['collar']),
      under: (map['under'] ?? '0').toString(),
      backLength: (map['back_length'] ?? '0').toString(),
      neck: (map['neck'] ?? '0').toString(),
      shoulder: (map['shoulder'] ?? '0').toString(),
      seam: map['seam'] ?? '',
      adhesive: map['adhesive'] ?? '',
      underKandura: map['under_kandura'] ?? '',
      tarboosh: map['tarboosh'] ?? '',
      openSleeve: map['open_sleeve'] ?? '',
      stitching: map['stitching'] ?? '',
      pleat: map['pleat'] ?? '',
      button: map['button'] ?? '',
      cuff: map['cuff'] ?? '',
      embroidery: map['embroidery'] ?? '',
      neckStyle: map['neck_style'] ?? '',
      notes: map['notes'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(
        map['last_updated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Measurement.fromJson(String source) =>
      Measurement.fromMap(json.decode(source));
}
