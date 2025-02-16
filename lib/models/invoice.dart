import 'package:uuid/uuid.dart';
import 'customer.dart';

enum InvoiceStatus {
  pending,
  delivered,
  cancelled
}

enum PaymentStatus {
  unpaid,
  partial,
  paid
}

class Invoice {
  static const String trn = '100566119200003';
  static const double vatRate = 0.05;

  final String id;
  final String invoiceNumber;
  final DateTime date;
  final DateTime deliveryDate;
  final double amountIncludingVat;
  final double amount;
  final double vat;
  final double netTotal;
  final double advance;
  final double balance;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String details;
  final String customerBillNumber;
  final String? measurementId;
  final String? measurementName;
  PaymentStatus paymentStatus;
  InvoiceStatus deliveryStatus;
  DateTime? deliveredAt;
  DateTime? paidAt;
  List<String> notes;
  List<Payment> payments;
  final bool isDelivered;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.deliveryDate,
    required this.amountIncludingVat,
    required this.amount,
    required this.vat,
    required this.netTotal,
    required this.advance,
    required this.balance,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.details,
    required this.customerBillNumber,
    this.measurementId,
    this.measurementName,
    this.isDelivered = false,
    this.paymentStatus = PaymentStatus.unpaid,
    this.deliveryStatus = InvoiceStatus.pending,
    this.deliveredAt,
    this.paidAt,
    this.notes = const [],
    this.payments = const [],
  });

  factory Invoice.create({
    required String invoiceNumber,
    required DateTime date,
    required DateTime deliveryDate,
    required double amount,
    required double advance,
    required Customer customer,
    String? details,
    String? measurementId,
    String? measurementName,
  }) {
    final vat = amount * vatRate;
    final amountIncludingVat = amount + vat;
    final balance = amountIncludingVat - advance;

    return Invoice(
      id: const Uuid().v4(),
      invoiceNumber: invoiceNumber,
      date: date,
      deliveryDate: deliveryDate,
      amount: amount,
      vat: vat,
      amountIncludingVat: amountIncludingVat,
      netTotal: amount,
      advance: advance,
      balance: balance,
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      details: details ?? '',
      customerBillNumber: customer.billNumber,
      measurementId: measurementId,
      measurementName: measurementName,
      isDelivered: false,
      paymentStatus: advance >= amountIncludingVat ? PaymentStatus.paid : advance > 0 ? PaymentStatus.partial : PaymentStatus.unpaid,
      deliveryStatus: InvoiceStatus.pending,
      notes: [],
      payments: [],
    );
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      date: DateTime.parse(map['date']),
      deliveryDate: DateTime.parse(map['delivery_date']),
      amount: map['amount'],
      vat: map['vat'],
      amountIncludingVat: map['amount_including_vat'],
      netTotal: map['net_total'],
      advance: map['advance'],
      balance: map['balance'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      details: map['details'],
      customerBillNumber: map['customer_bill_number'],
      measurementId: map['measurement_id'],
      measurementName: map['measurement_name'],
      deliveryStatus: InvoiceStatus.values.firstWhere(
        (e) => e.toString() == map['delivery_status'],
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == map['payment_status'],
      ),
      deliveredAt: map['delivered_at'] != null
          ? DateTime.parse(map['delivered_at'])
          : null,
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at']) : null,
      notes: List<String>.from(map['notes'] ?? []),
      payments: (map['payments'] as List<dynamic>? ?? [])
          .map((p) => Payment(
                amount: p['amount'],
                date: DateTime.parse(p['date']),
                note: p['note'],
              ))
          .toList(),
      isDelivered: map['is_delivered'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'date': date.toIso8601String(),
      'delivery_date': deliveryDate.toIso8601String(),
      'amount': amount,
      'vat': vat,
      'amount_including_vat': amountIncludingVat,
      'net_total': netTotal,
      'advance': advance,
      'balance': balance,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'details': details,
      'customer_bill_number': customerBillNumber,
      'measurement_id': measurementId,
      'measurement_name': measurementName,
      'delivery_status': deliveryStatus.toString(),
      'payment_status': paymentStatus.toString(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'notes': notes,
      'payments': payments.map((p) => p.toMap()).toList(),
      'is_delivered': isDelivered,
    };
  }

  String get displayNumber => 'INV-$customerBillNumber-${invoiceNumber.substring(0, 3)}';

  double get remainingBalance => balance - payments.fold(0.0, (sum, payment) => sum + payment.amount);

  void addPayment(double amount, String note) {
    payments.add(Payment(
      amount: amount,
      date: DateTime.now(),
      note: note,
    ));
    if (remainingBalance <= 0) {
      paymentStatus = PaymentStatus.paid;
      paidAt = DateTime.now();
    } else if (payments.isNotEmpty) {
      paymentStatus = PaymentStatus.partial;
    }
  }

  void markAsDelivered() {
    deliveryStatus = InvoiceStatus.delivered;
    deliveredAt = DateTime.now();
  }

  void markAsPaid() {
    paymentStatus = PaymentStatus.paid;
    paidAt = DateTime.now();
  }

  void addNote(String note) {
    notes.add(note);
  }
}

class Payment {
  final double amount;
  final DateTime date;
  final String note;

  Payment({
    required this.amount,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}
