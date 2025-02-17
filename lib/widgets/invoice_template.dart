import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../models/invoice.dart';

class InvoiceTemplate {
  static Future<Uint8List> generateInvoice(Invoice invoice) async {
    final pdf = pw.Document();
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/3.png')).buffer.asUint8List(),
    );
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              children: [
                // Header with Logo
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(logoImage, width: 160),
                    pw.Spacer(),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('INVOICE', 
                            style: pw.TextStyle(
                              fontSize: 24, 
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('#${invoice.invoiceNumber}',
                            style: pw.TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                // Business & Customer Info
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Business Info
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Shabab al Yola',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          _buildContactInfo('11th St - Al Nahyan - E19 02 - Abu Dhabi'),
                          _buildContactInfo('Tel: 055 682 9381, 02 443 8687'),
                          _buildContactInfo('WhatsApp: 055 682 9381'),
                          _buildContactInfo('www.shababalyola.ae'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Bill To',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(invoice.customerName,
                              style: const pw.TextStyle(fontSize: 14),
                            ),
                            pw.Text('Bill #${invoice.customerBillNumber}'),
                            pw.Text(invoice.customerPhone),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Dates
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDateInfo('Invoice Date', invoice.date),
                      _buildDateInfo('Delivery Date', invoice.deliveryDate),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Description Box
                if (invoice.details.isNotEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Description',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(invoice.details),
                      ],
                    ),
                  ),

                pw.SizedBox(height: 20),

                // Totals
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    children: [
                      _buildTotalRow('Subtotal', invoice.amount),
                      _buildTotalRow('VAT (5%)', invoice.vat),
                      pw.Divider(color: PdfColors.grey300),
                      _buildTotalRow('Total', invoice.amountIncludingVat,
                          isBold: true, textColor: PdfColors.blue800),
                      if (invoice.advance > 0) ...[
                        _buildTotalRow('Advance', invoice.advance),
                        _buildTotalRow('Balance', invoice.balance,
                            isBold: true,
                            textColor: invoice.balance > 0
                                ? PdfColors.red
                                : PdfColors.green700),
                      ],
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Thank you for your business',
                        style: pw.TextStyle(
                          color: PdfColors.grey600,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
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

  static pw.Widget _buildContactInfo(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text(text,
        style: const pw.TextStyle(
          fontSize: 12,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  static pw.Widget _buildDateInfo(String label, DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
          style: pw.TextStyle(
            color: PdfColors.grey600,
            fontSize: 12,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${date.day}/${date.month}/${date.year}',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    PdfColor textColor = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            'AED ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : null,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

