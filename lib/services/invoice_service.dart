import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../widgets/invoice/invoice_template.dart';
import '../models/invoice.dart';

class InvoiceService {
  final _supabase = Supabase.instance.client;

  Future<void> addInvoice(Invoice invoice) async {
    await _supabase.from('invoices').insert({
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
      'products': invoice.products.map((p) => p.toMap()).toList(),
    });
  }

  Future<void> updateInvoice(Invoice invoice) async {
    await _supabase
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
          'products': invoice.products.map((p) => p.toMap()).toList(),
          'amount': invoice.amount,
          'vat': invoice.vat,
          'amount_including_vat': invoice.amountIncludingVat,
        })
        .eq('id', invoice.id);
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await _supabase.from('invoices').delete().eq('id', invoiceId);
  }

  Stream<List<Invoice>> getInvoicesStream() {
    return _supabase
        .from('invoices')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false)
        .map((maps) => maps.map((map) => Invoice.fromMap(map)).toList());
  }

  Future<String> generateInvoiceNumber() async {
    try {
      final response =
          await _supabase
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

  Future<List<Invoice>> getInvoicesByDateRange(DateTime start, DateTime end) async {
    try {
      final response = await _supabase
          .from('invoices')
          .select()
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .order('date');
      
      return (response as List).map((map) => Invoice.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching invoices by date range: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getKPIs() async {
    try {
      final response = await _supabase
          .from('invoices')
          .select('amount_including_vat, payment_status, delivery_status')
          .order('date');

      double totalRevenue = 0;
      double pendingPayments = 0;
      int pendingDeliveries = 0;
      
      final invoices = (response as List).map((map) => Invoice.fromMap(map)).toList();
      
      for (var invoice in invoices) {
        totalRevenue += invoice.amountIncludingVat;
        if (invoice.paymentStatus != PaymentStatus.paid) {
          pendingPayments += invoice.remainingBalance;
        }
        if (invoice.deliveryStatus == InvoiceStatus.pending) {
          pendingDeliveries++;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'pendingPayments': pendingPayments,
        'totalOrders': invoices.length,
        'pendingDeliveries': pendingDeliveries,
      };
    } catch (e) {
      debugPrint('Error fetching KPIs: $e');
      return {
        'totalRevenue': 0.0,
        'pendingPayments': 0.0,
        'totalOrders': 0,
        'pendingDeliveries': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getRevenueData() async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      
      final response = await _supabase
          .from('invoices')
          .select('date, amount_including_vat')
          .gte('date', startDate.toIso8601String())
          .lte('date', now.toIso8601String())
          .order('date');

      final Map<String, double> dailyRevenue = {};
      
      for (var row in response) {
        final date = DateTime.parse(row['date']).toString().split(' ')[0];
        dailyRevenue[date] = (dailyRevenue[date] ?? 0) + 
            (row['amount_including_vat'] as num).toDouble();
      }

      return dailyRevenue.entries.map((e) => {
        'date': e.key,
        'amount': e.value,
      }).toList();
    } catch (e) {
      debugPrint('Error fetching revenue data: $e');
      return [];
    }
  }

  // Get invoices by customer ID
  Future<List<Invoice>> getCustomerInvoices(String customerId) async {
    final response = await _supabase
        .from('invoices')
        .select()
        .eq('customer_id', customerId)
        .order('date', ascending: false);

    return response.map((data) => Invoice.fromMap(data)).toList();
  }

  // Add this method to get a single invoice by ID
  Future<Invoice> getInvoiceById(String invoiceId) async {
    final response = await _supabase
        .from('invoices')
        .select()
        .eq('id', invoiceId)
        .single();
        
    return Invoice.fromMap(response);
  }

  Future<void> processRefund(String invoiceId, double amount, String reason) async {
    final invoice = await getInvoiceById(invoiceId);
    
    if (invoice.isRefunded) {
      throw Exception('Invoice is already refunded');
    }

    if (amount <= 0) {
      throw Exception('Refund amount must be greater than 0');
    }

    if (amount > invoice.amountIncludingVat) {
      throw Exception('Refund amount cannot exceed invoice total');
    }

    invoice.processRefund(amount, reason);
    await updateInvoice(invoice);
  }
}
