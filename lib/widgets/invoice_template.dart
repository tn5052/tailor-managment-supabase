import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../models/invoice.dart';

class InvoiceTemplate {
  static Future<Uint8List> generateInvoice(Invoice invoice) async {
    // Load both English and Arabic fonts
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'));
    final englishFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final englishBoldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    
    final logoImage = (await rootBundle.load('assets/images/3.png')).buffer.asUint8List();
    final logo = pw.MemoryImage(logoImage);
    
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: englishFont,
        bold: englishBoldFont,
      ),
    );
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(logo, invoice, arabicFont),
            pw.SizedBox(height: 20),
            _buildBusinessInfoBox(arabicFont, invoice),
            pw.SizedBox(height: 20),
            _buildInvoiceDetailsTable(invoice, arabicFont),
            pw.SizedBox(height: 20),
            _buildAmountTable(invoice, arabicFont),
            pw.SizedBox(height: 20),
            _buildDetailsBox(invoice, arabicFont),
            pw.SizedBox(height: 20),
            _buildFooter(arabicFont),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.MemoryImage logo, Invoice invoice, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Image(logo, width: 120),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildTrilingualRow(
                'Invoice #',
                invoice.invoiceNumber,
                'رقم الفاتورة',
                arabicFont,
                fontSize: 16,
                isBold: true,
              ),
              pw.SizedBox(height: 5),
              _buildTrilingualRow(
                'Bill #',
                invoice.customerBillNumber,
                'رقم الطلب',
                arabicFont,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBusinessInfoBox(pw.Font arabicFont, Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Shabab al Yola',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('11th St - Al Nahyan - E19 02'),
              pw.Text('Abu Dhabi, UAE'),
              pw.Text('Tel: 055 682 9381'),
            ],
          ),
          pw.BarcodeWidget(
            data: invoice.invoiceNumber,
            barcode: pw.Barcode.qrCode(),
            width: 60,
            height: 60,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceDetailsTable(Invoice invoice, pw.Font arabicFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        _buildTableRow(
          'Customer',
          invoice.customerName,
          'العميل',
          arabicFont,
          isHeader: true,
        ),
        _buildTableRow(
          'Phone',
          invoice.customerPhone,
          'رقم الهاتف',
          arabicFont,
        ),
        _buildTableRow(
          'Date',
          _formatDate(invoice.date),
          'التاريخ',
          arabicFont,
        ),
        _buildTableRow(
          'Delivery Date',
          _formatDate(invoice.deliveryDate),
          'تاريخ التسليم',
          arabicFont,
        ),
      ],
    );
  }

  static pw.Widget _buildAmountTable(Invoice invoice, pw.Font arabicFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          _buildTableRow(
            'Amount',
            'AED ${invoice.amount.toStringAsFixed(2)}',
            'المبلغ',
            arabicFont,
          ),
          _buildTableRow(
            'VAT (5%)',
            'AED ${invoice.vat.toStringAsFixed(2)}',
            'ضريبة القيمة المضافة',
            arabicFont,
          ),
          _buildTableRow(
            'Total',
            'AED ${invoice.amountIncludingVat.toStringAsFixed(2)}',
            'المجموع',
            arabicFont,
            isTotal: true,
          ),
          if (invoice.advance > 0) ...[
            _buildTableRow(
              'Advance',
              'AED ${invoice.advance.toStringAsFixed(2)}',
              'دفعة مقدمة',
              arabicFont,
            ),
            _buildTableRow(
              'Balance',
              'AED ${invoice.balance.toStringAsFixed(2)}',
              'المتبقي',
              arabicFont,
              isTotal: true,
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildDetailsBox(Invoice invoice, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildTrilingualRow(
            'Details',
            '',
            'التفاصيل',
            arabicFont,
            isBold: true,
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              invoice.details ?? 'No details provided',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableRow(
    String english,
    String value,
    String arabic,
    pw.Font arabicFont, {
    bool isHeader = false,
    bool isTotal = false,
  }) {
    final style = pw.TextStyle(
      fontSize: isHeader || isTotal ? 14 : 12,
      fontWeight: isHeader || isTotal ? pw.FontWeight.bold : null,
    );

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isHeader ? PdfColors.grey200 : null,
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(english, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.center,
            style: style,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            arabic,
            textDirection: pw.TextDirection.rtl,
            style: style.copyWith(font: arabicFont),
          ),
        ),
        ],
    );
  }

  static pw.Widget _buildFooter(pw.Font arabicFont) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Center(
        child: _buildBilingualText(
          'Thank you for your business',
          'شكراً لتعاملكم معنا',
          12,
          true,
          arabicFont,
        ),
      ),
    );
  }

  static pw.Widget _buildBilingualText(
    String english,
    String arabic,
    double fontSize,
    bool isBold, [
    pw.Font? arabicFont,
  ]) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          english,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : null,
          ),
        ),
        if (arabicFont != null)
          pw.Text(
            arabic,
            textDirection: pw.TextDirection.rtl, // Enable RTL for Arabic
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : null,
            ),
          ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static pw.Widget _buildTrilingualRow(
    String englishLabel,
    String value,
    String arabicLabel,
    pw.Font arabicFont, {
    double fontSize = 12,
    bool isBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          englishLabel,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : null,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : null,
          ),
        ),
        pw.Text(
          arabicLabel,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
            font: arabicFont,
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}

