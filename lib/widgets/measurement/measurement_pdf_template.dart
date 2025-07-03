import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../../models/measurement.dart';

class MeasurementTemplate {
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF4A4A4A);
  static const PdfColor _secondaryColor = PdfColor.fromInt(0xFF888888);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFFEAEAEA);
  static const PdfColor _highlightColor = PdfColor.fromInt(0xFFF7F7F7);

  static Future<Uint8List> generateMeasurement(
    Measurement measurement,
    String customerName,
  ) async {
    final englishFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final englishBoldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    
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
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader(logo, customerName, measurement),
              pw.SizedBox(height: 24),
              
              _buildSection(
                title: 'Style & Design',
                content: _buildStyleAndDesign(measurement),
              ),
              pw.SizedBox(height: 16),

              _buildSection(
                title: 'Main Measurements',
                content: _buildMainMeasurements(measurement),
              ),
              pw.SizedBox(height: 16),

              _buildSection(
                title: 'Style Details',
                content: _buildStyleDetails(measurement),
              ),
              
              if (measurement.notes.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                _buildSection(
                  title: 'Additional Notes',
                  content: pw.Text(
                    measurement.notes,
                    style: const pw.TextStyle(fontSize: 10, color: _secondaryColor),
                  ),
                ),
              ],
              
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage logo,
    String customerName,
    Measurement measurement,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Image(logo, width: 50, height: 50),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SHABAB AL YOLA',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Measurement Details',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: _secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            _buildHeaderInfo('CUSTOMER', customerName),
            pw.SizedBox(height: 8),
            _buildHeaderInfo('BILL NUMBER', measurement.billNumber),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.BarcodeWidget(
              data: _generateDetailedQRData(measurement, customerName),
              barcode: pw.Barcode.qrCode(),
              width: 70,
              height: 70,
            ),
            pw.SizedBox(height: 8),
            _buildHeaderInfo('DATE', _formatDate(measurement.date), alignRight: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildHeaderInfo(String label, String value, {bool alignRight = false}) {
    return pw.Column(
      crossAxisAlignment: alignRight ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: _secondaryColor,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSection({required String title, required pw.Widget content}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
            letterSpacing: 1,
          ),
        ),
        pw.Divider(color: _borderColor, height: 8),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _highlightColor,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: content,
        ),
      ],
    );
  }

  static pw.Widget _buildStyleAndDesign(Measurement measurement) {
    final List<pw.Widget> styleItems = [
      _buildDetailItem('Style', measurement.style),
      _buildDetailItem('Design', measurement.designType),
      _buildDetailItem('Cap Style', measurement.tarbooshType),
    ];

    return pw.Wrap(
      spacing: 12,
      runSpacing: 12,
      children: styleItems.map((item) => pw.SizedBox(width: 150, child: item)).toList(),
    );
  }

  static pw.Widget _buildMainMeasurements(Measurement measurement) {
    final List<pw.Widget> measurementItems = [
      _buildMeasurementItem(
        measurement.style == 'Emirati' ? 'Length (Arabic)' : 'Length (Kuwaiti)',
        measurement.style == 'Emirati' ? measurement.lengthArabi : measurement.lengthKuwaiti,
      ),
      _buildMeasurementItem('Chest', measurement.chest),
      _buildMeasurementItem('Width', measurement.width),
      _buildMeasurementItem('Back Length', measurement.backLength),
      _buildMeasurementItem('Neck Size', measurement.neck),
      _buildMeasurementItem('Shoulder', measurement.shoulder),
      _buildMeasurementItem('Sleeve Length', measurement.sleeve),
      _buildCollarMeasurement('Sleeve Fitting', measurement.collar),
      _buildMeasurementItem('Under Shoulder', measurement.under),
      _buildDetailItem('Side Seam', measurement.seam),
      _buildDetailItem('Adhesive', measurement.adhesive),
      _buildDetailItem('Under Kandura', measurement.underKandura),
    ];

    return pw.Wrap(
      spacing: 12,
      runSpacing: 12,
      children: measurementItems.map((item) => pw.SizedBox(width: 150, child: item)).toList(),
    );
  }

  static pw.Widget _buildStyleDetails(Measurement measurement) {
    final List<pw.Widget> styleItems = [
      _buildDetailItem('Sleeve Opening', measurement.openSleeve),
      _buildDetailItem('Stitching Style', measurement.stitching),
      _buildDetailItem('Pleat Style', measurement.pleat),
      _buildDetailItem('Side Pocket', measurement.button),
      _buildDetailItem('Cuff Style', measurement.cuff),
      _buildDetailItem('Embroidery', measurement.embroidery),
      _buildDetailItem('Neck Style', measurement.neckStyle),
    ];

    return pw.Wrap(
      spacing: 12,
      runSpacing: 12,
      children: styleItems.map((item) => pw.SizedBox(width: 150, child: item)).toList(),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: _borderColor),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Contact: 02 443 8687 | WhatsApp: 055 682 9381',
              style: const pw.TextStyle(fontSize: 9, color: _secondaryColor),
            ),
            pw.Text(
              '11th St - Al Nahyan - E19 02 - Abu Dhabi',
              style: const pw.TextStyle(fontSize: 9, color: _secondaryColor),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMeasurementItem(String label, double value) {
    final displayValue = value != 0.0 ? value.toStringAsFixed(1) : '-';
    return _buildDetailItem(label, displayValue);
  }

  static pw.Widget _buildCollarMeasurement(String label, Map<String, double> value) {
    final start = value['start'] ?? 0.0;
    final center = value['center'] ?? 0.0;
    final end = value['end'] ?? 0.0;
    
    if (start == 0.0 && center == 0.0 && end == 0.0) {
      return _buildDetailItem(label, '-');
    }

    final formattedValue = 'S:${start.toStringAsFixed(1)} C:${center.toStringAsFixed(1)} E:${end.toStringAsFixed(1)}';
    return _buildDetailItem(label, formattedValue);
  }

  static pw.Widget _buildDetailItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: _secondaryColor),
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value.trim().isEmpty ? '-' : value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _generateDetailedQRData(Measurement measurement, String customerName) {
    final data = {
      'Customer': customerName,
      'Bill': measurement.billNumber,
      'Date': _formatDate(measurement.date),
      'Style': measurement.style,
      'Design': measurement.designType,
      'Length': measurement.style == 'Emirati' 
          ? '${measurement.lengthArabi} (Ar)'
          : '${measurement.lengthKuwaiti} (Kw)',
      'Chest': measurement.chest,
      'Width': measurement.width,
      'Sleeve': measurement.sleeve,
      'Collar': 'S:${measurement.collar['start'] ?? 0},C:${measurement.collar['center'] ?? 0},E:${measurement.collar['end'] ?? 0}',
      'Neck': measurement.neck,
      'Shoulder': measurement.shoulder,
    };

    return data.entries.map((e) => '${e.key}:${e.value}').join('; ');
  }
}
