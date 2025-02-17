import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import '../models/invoice.dart';

class InvoiceTemplate {
  static Future<Uint8List> generateInvoice(Invoice invoice) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with Logo and Business Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Shabab al Yola',
                            style: pw.TextStyle(
                                fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text('11th St - Al Nahyan - E19 02 - Abu Dhabi'),
                        pw.Text('Tel: 055 682 9381, 02 443 8687'),
                        pw.Text('WhatsApp: 055 682 9381'),
                        pw.Text('www.shababalyola.ae'),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Invoice Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(invoice.customerName),
                        pw.Text('Phone: ${invoice.customerPhone}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Invoice No: ${invoice.invoiceNumber}'),
                        pw.Text('Date: ${_formatDate(invoice.date)}'),
                        pw.Text('Delivery Date: ${_formatDate(invoice.deliveryDate)}'),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Invoice Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Table Header
                    pw.TableRow(
                      children: [
                        _tableHeader('Description'),
                        _tableHeader('Amount'),
                      ],
                    ),
                    // Table Data
                    pw.TableRow(
                      children: [
                        _tableCell(invoice.details),
                        _tableCell('AED ${invoice.amount.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Totals
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _totalRow('Subtotal:', invoice.amount),
                      _totalRow('VAT (5%):', invoice.vat),
                      _totalRow('Total:', invoice.amountIncludingVat),
                      _totalRow('Advance:', invoice.advance),
                      _totalRow('Balance:', invoice.balance),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text),
    );
  }

  static pw.Widget _totalRow(String label, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(label),
        pw.SizedBox(width: 20),
        pw.Text('AED ${amount.toStringAsFixed(2)}'),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

