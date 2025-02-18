import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../../models/invoice.dart';

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
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header with Logo and Basic Info
                _buildHeaderSection(logo, invoice, arabicFont),
                pw.SizedBox(height: 15),

                // Business Details
                _buildBusinessDetails(arabicFont, invoice),
                pw.SizedBox(height: 15),

                // Customer Information
                _buildCustomerSection(invoice, arabicFont),
                pw.SizedBox(height: 15),

                // Amount Details
                _buildAmountTable(invoice, arabicFont),
                pw.SizedBox(height: 15),

                // Details Box (if available)
                _buildDetailsBox(invoice, arabicFont),
                
                pw.Spacer(),
                _buildFooter(arabicFont),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderSection(
    pw.MemoryImage logo, 
    Invoice invoice, 
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Image(logo, width: 100, height: 60),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Shabab al Yola',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('TRN: 100556789012345'),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildTrilingualRow(
                'Invoice #',
                invoice.invoiceNumber,
                'رقم الفاتورة',
                arabicFont,
                fontSize: 14,
                isBold: true,
              ),
              pw.SizedBox(height: 4),
              _buildTrilingualRow(
                'Date',
                _formatDate(invoice.date),
                'التاريخ',
                arabicFont,
                fontSize: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBusinessDetails(pw.Font arabicFont, Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoLine('Address:', '11th St - Al Nahyan - E19 02 - Abu Dhabi'),
                _buildInfoLine('Tel:', '02 443 8687'),
                _buildInfoLine('WhatsApp:', '055 682 9381'),
                _buildInfoLine('Website:', 'www.shababalyola.ae'),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              children: [
                pw.BarcodeWidget(
                  data: _generateQRData(invoice),
                  barcode: pw.Barcode.qrCode(
                    errorCorrectLevel: pw.BarcodeQRCorrectionLevel.high,
                  ),
                  width: 80,
                  height: 80,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Scan for details',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerSection(Invoice invoice, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildTrilingualRow(
            'Customer',
            invoice.customerName,
            'العميل',
            arabicFont,
            fontSize: 12,
            isBold: true,
          ),
          pw.SizedBox(height: 4),
          _buildTrilingualRow(
            'Phone',
            invoice.customerPhone,
            'الهاتف',
            arabicFont,
            fontSize: 12,
          ),
          pw.SizedBox(height: 4),
          _buildTrilingualRow(
            'Delivery Date',
            _formatDate(invoice.deliveryDate),
            'تاريخ التسليم',
            arabicFont,
            fontSize: 12,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailsBox(Invoice invoice, pw.Font arabicFont) {
    if (invoice.details.isEmpty) {
      return pw.Container();
    }

    // Split details by language (assuming Arabic text contains Arabic characters)
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(invoice.details);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Details',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'التفاصيل',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Details content with mixed text handling
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: _buildDetailsContent(invoice.details, hasArabic, arabicFont),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailsContent(String text, bool hasArabic, pw.Font arabicFont) {
    if (hasArabic) {
      // For Arabic or mixed text
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              text,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 11,
                lineSpacing: 1.5,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      );
    }
    
    // For English-only text
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(
              fontSize: 11,
              lineSpacing: 1.5,
            ),
            textAlign: pw.TextAlign.left,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 4),
          pw.Text(value),
        ],
      ),
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
          ...invoice.products.map((product) => _buildProductTableRow(
            product.name,
            'AED ${product.price.toStringAsFixed(2)}',
            '', // No Arabic translation for product name
            arabicFont,
          )).toList(),
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

  static pw.TableRow _buildProductTableRow(
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

  static String _generateQRData(Invoice invoice) {
    // Create shorter, more compact QR content
    return '''
SHABAB AL YOLA
─────────────────
INV#${invoice.invoiceNumber}
BILL#${invoice.customerBillNumber}
${invoice.customerName}
${_formatDate(invoice.date)}
─────────────────
Amount: ${invoice.amountIncludingVat.toStringAsFixed(2)}
Adv: ${invoice.advance.toStringAsFixed(2)}
Bal: ${invoice.balance.toStringAsFixed(2)}
─────────────────
Tel: 02 443 8687''';
  }
}

