import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import '../widgets/invoice_template.dart';
import '../models/invoice.dart';

class InvoiceService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> addInvoice(Invoice invoice) async {
    await _client.from('invoices').insert({
      'id': invoice.id,
      'invoice_number': invoice.invoiceNumber,
      'date': invoice.date.toIso8601String(),
      'delivery_date': invoice.deliveryDate.toIso8601String(),
      'amount': invoice.amount,
      'vat': invoice.vat,
      'amount_including_vat': invoice.amountIncludingVat,
      'net_total': invoice.netTotal,
      'advance': invoice.advance,
      'balance': invoice.balance,
      'customer_id': invoice.customerId,
      'customer_name': invoice.customerName,
      'customer_phone': invoice.customerPhone,
      'details': invoice.details,
      'customer_bill_number': invoice.customerBillNumber,
      'measurement_id': invoice.measurementId,
      'measurement_name': invoice.measurementName,
      'payment_status': invoice.paymentStatus.toString(),
      'delivery_status': invoice.deliveryStatus.toString(),
      'delivered_at': invoice.deliveredAt?.toIso8601String(),
      'paid_at': invoice.paidAt?.toIso8601String(),
      'notes': invoice.notes,
      'payments':
          invoice.payments
              .map(
                (p) => {
                  'amount': p.amount,
                  'date': p.date.toIso8601String(),
                  'note': p.note,
                },
              )
              .toList(),
      'is_delivered': invoice.isDelivered,
    });
  }

  Future<void> updateInvoice(Invoice invoice) async {
    await _client
        .from('invoices')
        .update({
          'delivery_status': invoice.deliveryStatus.toString(),
          'payment_status': invoice.paymentStatus.toString(),
          'delivered_at': invoice.deliveredAt?.toIso8601String(),
          'paid_at': invoice.paidAt?.toIso8601String(),
          'notes': invoice.notes,
          'payments':
              invoice.payments
                  .map(
                    (p) => {
                      'amount': p.amount,
                      'date': p.date.toIso8601String(),
                      'note': p.note,
                    },
                  )
                  .toList(),
          'is_delivered': invoice.isDelivered,
        })
        .eq('id', invoice.id);
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await _client.from('invoices').delete().eq('id', invoiceId);
  }

  Stream<List<Invoice>> getInvoicesStream() {
    return _client
        .from('invoices')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false)
        .map((maps) => maps.map((map) => Invoice.fromMap(map)).toList());
  }

  Future<String> generateInvoiceNumber() async {
    try {
      final response =
          await _client
              .from('invoices')
              .select('invoice_number')
              .order('invoice_number', ascending: false)
              .limit(1)
              .single();

      final data = response;

      final lastNumber = int.parse(data['invoice_number']);
      return (lastNumber + 1).toString();
    } catch (e) {
      return '1001';
    }
  }

  Future<Uint8List> generatePdfBytes(Invoice invoice) async {
    return await InvoiceTemplate.generateInvoice(invoice);
  }

  Future<void> generateAndShareInvoice(Invoice invoice) async {
    try {
      final pdfBytes = await generatePdfBytes(invoice);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invoice_${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice #${invoice.invoiceNumber}',
      );
    } catch (e) {
      throw Exception('Failed to generate invoice: $e');
    }
  }
}
