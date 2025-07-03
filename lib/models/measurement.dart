class Measurement {
  final String id;
  final String customerId;
  final String billNumber;
  final String style;
  final String designType;
  final String tarbooshType;
  final String fabricName;
  
  // Measurements section
  final double lengthArabi;    // طول عربي
  final double lengthKuwaiti;  // طول كويتي
  final double chest;          // صدر
  final double width;          // عرض
  final double sleeve;         // كم
  final Map<String, double> collar;         // فكم
  final double under;          // تحت
  final double backLength;     // طول خلفي
  final double neck;           // رقبة (Measurement)
  final double shoulder;       // كتف
  final String seam;           // شسيب
  final String adhesive;       // چسبا
  final String underKandura;   // تحت كندورة

  // Style Details section
  final String tarboosh;       // تربوش
  final String openSleeve;     // كم سلالي
  final String stitching;      // خياطة
  final String pleat;          // كسرة
  final String button;         // بتي
  final String cuff;          // كف
  final String embroidery;     // تطريز
  final String neckStyle;      // رقبة (Style)

  final String notes;
  final DateTime date;
  final DateTime lastUpdated;

  Measurement({
    required this.id,
    required this.customerId,
    required this.billNumber,
    required this.style,
    this.designType = 'Aadi',
    this.tarbooshType = 'Fixed',
    this.fabricName = '',
    this.lengthArabi = 0,
    this.lengthKuwaiti = 0,
    this.chest = 0,
    this.width = 0,
    this.sleeve = 0,
    this.collar = const {'start': 0, 'center': 0, 'end': 0},
    this.under = 0,
    this.backLength = 0,
    this.neck = 0,
    this.shoulder = 0,
    this.seam = '',
    this.adhesive = '',
    this.underKandura = '',
    this.tarboosh = '',
    this.openSleeve = '',
    this.stitching = '',
    this.pleat = '',
    this.button = '',
    this.cuff = '',
    this.embroidery = '',
    this.neckStyle = '',
    this.notes = '',
    required this.date,
    required this.lastUpdated,
  });

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'],
      customerId: map['customer_id'] ?? '',
      billNumber: map['bill_number'] ?? '',
      style: map['style'] ?? '',
      designType: map['design_type'] ?? 'Aadi',
      tarbooshType: map['tarboosh_type'] ?? 'Fixed',
      fabricName: map['fabric_name'] ?? '',
      lengthArabi: (map['length_arabi'] ?? 0).toDouble(),
      lengthKuwaiti: (map['length_kuwaiti'] ?? 0).toDouble(),
      chest: (map['chest'] ?? 0).toDouble(),
      width: (map['width'] ?? 0).toDouble(),
      sleeve: (map['sleeve'] ?? 0).toDouble(),
      collar: _parseCollarFromMap(map['collar']),
      under: (map['under'] ?? 0).toDouble(),
      backLength: (map['back_length'] ?? 0).toDouble(),
      neck: (map['neck'] ?? 0).toDouble(),
      shoulder: (map['shoulder'] ?? 0).toDouble(),
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
      date: DateTime.parse(map['date']),
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }

  static Map<String, double> _parseCollarFromMap(dynamic collarData) {
    if (collarData is Map) {
      // It's already a map, just ensure the values are doubles
      return {
        'start': (collarData['start'] ?? 0.0).toDouble(),
        'center': (collarData['center'] ?? 0.0).toDouble(),
        'end': (collarData['end'] ?? 0.0).toDouble(),
      };
    }
    // Handle legacy data if it's just a number
    if (collarData is num) {
      return {
        'start': collarData.toDouble(),
        'center': 0.0,
        'end': 0.0,
      };
    }
    // Default value
    return {'start': 0.0, 'center': 0.0, 'end': 0.0};
  }

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
      'collar': collar,
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
}
