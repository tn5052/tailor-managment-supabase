class Measurement {
  final String id;
  final String customerId;
  final String billNumber;
  final String style;
  final double toolArabi;
  final double toolKuwaiti;
  final double sadur;
  final double kum;
  final double katf;
  final double toolKhalfi;
  final double ard;
  final double raqba;
  final double fkm;
  final double taht;
  final String tarboosh;
  final String kumSalai;
  final String khayata;
  final String kisra;
  final String bati;
  final String kaf;
  final String tatreez;
  final String jasba;
  final String tahtKandura;
  final String shaib;
  final String notes;
  final String hesba;
  final String sheeb;
  final DateTime date;
  final DateTime lastUpdated;

  Measurement({
    required this.id,
    required this.customerId,
    required this.billNumber,
    required this.style,
    this.toolArabi = 0,
    this.toolKuwaiti = 0,
    this.sadur = 0,
    this.kum = 0,
    this.katf = 0,
    this.toolKhalfi = 0,
    this.ard = 0,
    this.raqba = 0,
    this.fkm = 0,
    this.taht = 0,
    this.tarboosh = '',
    this.kumSalai = '',
    this.khayata = '',
    this.kisra = '',
    this.bati = '',
    this.kaf = '',
    this.tatreez = '',
    this.jasba = '',
    this.tahtKandura = '',
    this.shaib = '',
    this.notes = '',
    this.hesba = '',
    this.sheeb = '',
    required this.date,
    required this.lastUpdated,
  });

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'],
      customerId: map['customer_id'] ?? '',
      billNumber: map['bill_number'] ?? '',
      style: map['style'] ?? '',
      toolArabi: (map['tool_arabi'] ?? 0).toDouble(),
      toolKuwaiti: (map['tool_kuwaiti'] ?? 0).toDouble(),
      sadur: (map['sadur'] ?? 0).toDouble(),
      kum: (map['kum'] ?? 0).toDouble(),
      katf: (map['katf'] ?? 0).toDouble(),
      toolKhalfi: (map['tool_khalfi'] ?? 0).toDouble(),
      ard: (map['ard'] ?? 0).toDouble(),
      raqba: (map['raqba'] ?? 0).toDouble(),
      fkm: (map['fkm'] ?? 0).toDouble(),
      taht: (map['taht'] ?? 0).toDouble(),
      tarboosh: map['tarboosh'] ?? '',
      kumSalai: map['kum_salai'] ?? '',
      khayata: map['khayata'] ?? '',
      kisra: map['kisra'] ?? '',
      bati: map['bati'] ?? '',
      kaf: map['kaf'] ?? '',
      tatreez: map['tatreez'] ?? '',
      jasba: map['jasba'] ?? '',
      tahtKandura: map['taht_kandura'] ?? '',
      shaib: map['shaib'] ?? '',
      notes: map['notes'] ?? '',
      hesba: map['hesba'] ?? '',
      sheeb: map['sheeb'] ?? '',
      date: DateTime.parse(map['date']),
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'bill_number': billNumber,
      'style': style,
      'tool_arabi': toolArabi,
      'tool_kuwaiti': toolKuwaiti,
      'sadur': sadur,
      'kum': kum,
      'katf': katf,
      'tool_khalfi': toolKhalfi,
      'ard': ard,
      'raqba': raqba,
      'fkm': fkm,
      'taht': taht,
      'tarboosh': tarboosh,
      'kum_salai': kumSalai,
      'khayata': khayata,
      'kisra': kisra,
      'bati': bati,
      'kaf': kaf,
      'tatreez': tatreez,
      'jasba': jasba,
      'taht_kandura': tahtKandura,
      'shaib': shaib,
      'notes': notes,
      'hesba': hesba,
      'sheeb': sheeb,
      'date': date.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
