import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../../models/measurement.dart';

class MeasurementTemplate {
  static Future<Uint8List> generateMeasurement(
    Measurement measurement,
    String customerName,
  ) async {
    // Load fonts
    // Removed unused arabicFont variable
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
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeaderSection(logo, customerName, measurement),
              pw.SizedBox(height: 20),
              
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: _buildMainMeasurements(measurement),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    flex: 2,
                    child: _buildSideDetails(measurement),
                  ),
                ],
              ),
              
              if (measurement.notes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildNotesSection(measurement),
              ],
              
              pw.Spacer(),
              _buildFooterSection(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderSection(
    pw.MemoryImage logo,
    String customerName,
    Measurement measurement,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Image(logo, width: 60, height: 40),
                  pw.SizedBox(width: 15),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SHABAB AL YOLA',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Professional Tailoring Services',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      data: _generateDetailedQRData(measurement, customerName),
                      barcode: pw.Barcode.qrCode(),
                      width: 80,
                      height: 80,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Scan for all details',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Customer',
                      style: const pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      customerName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill Number',
                      style: const pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      measurement.billNumber,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Date',
                      style: const pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      _formatDate(measurement.date),
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _generateDetailedQRData(Measurement measurement, String customerName) {
    final measurementData = {
      'Customer Info': {
        'Name': customerName,
        'Bill': measurement.billNumber,
        'Date': _formatDate(measurement.date),
      },
      'Style Info': {
        'Style': measurement.style,
        'Design': measurement.designType,
        'Fabric': measurement.fabricName,
      },
      'Measurements': {
        'Length': measurement.style == 'Emirati' 
            ? '${measurement.lengthArabi} (Arabic)'
            : '${measurement.lengthKuwaiti} (Kuwaiti)',
        'Chest': measurement.chest,
        'Width': measurement.width,
        'Sleeve': measurement.sleeve,
        'Collar': measurement.collar,
        'Under': measurement.under,
        'Back': measurement.backLength,
        'Neck': measurement.neck,
        'Shoulder': measurement.shoulder,
        'Seam': measurement.seam,
        'Adhesive': measurement.adhesive,
        'Under Kandura': measurement.underKandura,
      },
      'Style Details': {
        'Cap Style': measurement.tarboosh,
        'Sleeve Style': measurement.openSleeve,
        'Stitching': measurement.stitching,
        'Pleat': measurement.pleat,
        'Button': measurement.button,
        'Cuff': measurement.cuff,
        'Embroidery': measurement.embroidery,
        'Neck Style': measurement.neckStyle,
      },
    };

    // Convert map to formatted string
    String result = '';
    measurementData.forEach((section, details) {
      result += '=== $section ===\n';
      details.forEach((key, value) {
        if (value.toString().isNotEmpty && value.toString() != '0.0') {
          result += '$key: $value\n';
        }
      });
      result += '\n';
    });

    // Add contact information
    result += '''=== By Shabab Al Yola ===''';

    return result;
  }

  static pw.Widget _buildMainMeasurements(Measurement measurement) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('MEASUREMENTS'),
          pw.SizedBox(height: 10),
          
          // Style & Fabric Info
          _buildInfoRow('Style Type', measurement.style),
          _buildInfoRow('Design', measurement.designType),
          _buildInfoRow('Fabric', measurement.fabricName),
          pw.Divider(color: PdfColors.grey300),
          
          // Primary Measurements in two columns
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    if (measurement.style == 'Emirati')
                      _buildMeasurement('Arabic Length', measurement.lengthArabi)
                    else
                      _buildMeasurement('Kuwaiti Length', measurement.lengthKuwaiti),
                    _buildMeasurement('Chest', measurement.chest),
                    _buildMeasurement('Width', measurement.width),
                    _buildMeasurement('Sleeve', measurement.sleeve),
                    _buildMeasurement('Shoulder', measurement.shoulder),
                    _buildDetailRow('Seam', measurement.seam),
                    _buildDetailRow('Adhesive', measurement.adhesive),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    _buildMeasurement('Collar', measurement.collar),
                    _buildMeasurement('Under', measurement.under),
                    _buildMeasurement('Back Length', measurement.backLength),
                    _buildMeasurement('Neck', measurement.neck),
                    _buildDetailRow('Under Kandura', measurement.underKandura),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSideDetails(Measurement measurement) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('STYLE DETAILS'),
          pw.SizedBox(height: 10),
          _buildDetailRow('Tarboosh', measurement.tarboosh),
          _buildDetailRow('Sleeve Style', measurement.openSleeve),
          _buildDetailRow('Stitching', measurement.stitching),
          _buildDetailRow('Pleat', measurement.pleat),
          _buildDetailRow('Button', measurement.button),
          _buildDetailRow('Cuff', measurement.cuff),
          _buildDetailRow('Embroidery', measurement.embroidery),
          _buildDetailRow('Neck Style', measurement.neckStyle),
        ],
      ),
    );
  }

  static pw.Widget _buildNotesSection(Measurement measurement) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('NOTES'),
          pw.SizedBox(height: 10),
          pw.Text(
            measurement.notes,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Contact: 02 443 8687 | WhatsApp: 055 682 9381',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            '11th St - Al Nahyan - E19 02 - Abu Dhabi',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.BoxDecoration _boxDecoration() {
    return pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.grey300),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _buildMeasurement(String label, double value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            value.toStringAsFixed(1),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            value.isEmpty ? '-' : value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
