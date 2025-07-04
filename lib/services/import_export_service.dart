import 'dart:io';
import 'dart:async';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

import 'customer_service.dart';
import 'measurement_service.dart';
import '../widgets/export_filter_dialog.dart';

// Expected Excel structure:
//
// Worksheet "Customers" headers:
//   id, bill_number, name, phone, whatsapp, address, gender, created_at, referred_by, family_id, family_relation
//
// Worksheet "Measurements" headers:
//   id, customer_id, bill_number, style, design_type, tarboosh_type, fabric_name,
//   length_arabi, length_kuwaiti, chest, width, sleeve, collar, under, back_length, neck, shoulder,
//   seam, adhesive, under_kandura, tarboosh, open_sleeve, stitching, pleat, button, cuff, embroidery, neck_style,
//   notes, date, last_updated

class ImportExportService {
  final SupabaseService _supabaseService = SupabaseService();
  final MeasurementService _measurementService = MeasurementService();
  final _progressController = StreamController<String>.broadcast();

  Stream<String> get progressStream => _progressController.stream;

  // Add this helper method at class level
  String? validateFamilyRelation(String? value) {
    if (value == null) return null;
    // Convert common variations to valid enum values
    switch (value.trim().toLowerCase()) {
      case 'son':
      case 'beta':
        return 'son';
      case 'father':
      case 'dad':
      case 'abu':
        return 'father';
      case 'brother':
      case 'bhai':
        return 'brother';
      case 'nephew':
        return 'nephew';
      case 'cousin':
        return 'cousin';
      case '':
      case 'o':
      case 'null':
      case 'none':
      case 'no one':
        return null;
      default:
        return null; // Invalid values default to null
    }
  }

  // Add this helper method to get customer ID from bill number
  Future<String?> _getCustomerIdFromBillNumber(String billNumber) async {
    final customer = await _supabaseService.getCustomerByBillNumber(billNumber);
    return customer?.id;
  }

  // Modified importExcel to process both customer and measurement rows
  // separately. If record_type is 'customer', update/insert customer.
  // If 'measurement', always insert (new measurement).
  Future<void> importExcel(File file) async {
    try {
      _progressController.add('Reading file...');
      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;
      if (rows.isEmpty) throw Exception("Excel sheet is empty");
      final headers =
          rows.first.map((e) => e!.value.toString().trim()).toList();
      final recordTypeIndex = headers.indexOf('record_type');
      if (recordTypeIndex < 0) {
        throw Exception('Missing "record_type" column in Excel header');
      }

      // Helper function that returns null if the field is empty or equals "null" (case-insensitive).
      String? cleanField(dynamic value) {
        final s = value?.toString().trim();
        if (s == null || s.isEmpty || s.toLowerCase() == 'null') return null;
        return s;
      }

      // Process each row by record type.
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final recordType =
            row[recordTypeIndex]!.value.toString().trim().toLowerCase();
        final data = {
          for (var j = 0; j < headers.length; j++) headers[j]: row[j]?.value,
        };
        if (recordType == 'customer') {
          // Process customer fields (columns 1 to 11)
          final rawFamilyId = cleanField(data['family_id']);
          final rawFamilyRelation = cleanField(data['family_relation']);
          final familyId = (rawFamilyId != null && (rawFamilyId.toUpperCase() == "O" || rawFamilyId.toUpperCase() == "NONE"))
              ? null : rawFamilyId;
          final familyRelation = validateFamilyRelation(rawFamilyRelation);
          final customerData = {
            'bill_number': cleanField(data['bill_number']) ?? '',
            'name': cleanField(data['name']) ?? '',
            'phone': cleanField(data['phone']) ?? '',
            'whatsapp': cleanField(data['whatsapp']) ?? '',
            'address': cleanField(data['address']) ?? '',
            'gender': cleanField(data['gender'])?.toLowerCase() ?? '',
            'created_at': (data['created_at'] == null || data['created_at'].toString().trim().isEmpty)
                ? DateTime.now().toIso8601String() : data['created_at'].toString(),
            'referred_by': cleanField(data['referred_by']),
            'family_id': familyId,
            'family_relation': familyRelation,
          };
          // …existing resolution of referred_by and family_id…
          final existingCustomer = await _supabaseService.getCustomerByBillNumberAndDetail(
              customerData['bill_number']!, customerData['phone']!, customerData['name']!);
          String customerBill;
          if (existingCustomer != null) {
            customerBill = existingCustomer.billNumber;
            await _supabaseService.updateCustomerByBillNumber(customerBill, customerData);
          } else {
            await _supabaseService.addCustomerWithoutId(customerData);
            customerBill = customerData['bill_number']!;
          }

          // Auto-detect measurement info (columns 12 to last)
          final measurementIndicator = cleanField(data['style']);
          if (measurementIndicator != null && measurementIndicator.isNotEmpty) {
            final customerId = await _getCustomerIdFromBillNumber(customerData['bill_number']!);
            final measurementData = {
              'customer_id': customerId, // Add this line
              'bill_number': cleanField(data['bill_number']) ?? '',
              'style': cleanField(data['style']) ?? '',
              'design_type': cleanField(data['design_type']) ?? '',
              'tarboosh_type': cleanField(data['tarboosh_type']) ?? '',
              'fabric_name': cleanField(data['fabric_name']) ?? '',
              'length_arabi': double.tryParse(cleanField(data['length_arabi']) ?? '') ?? 0,
              'length_kuwaiti': double.tryParse(cleanField(data['length_kuwaiti']) ?? '') ?? 0,
              'chest': double.tryParse(cleanField(data['chest']) ?? '') ?? 0,
              'width': double.tryParse(cleanField(data['width']) ?? '') ?? 0,
              'sleeve': double.tryParse(cleanField(data['sleeve']) ?? '') ?? 0,
              'collar': _parseCollar(cleanField(data['collar'])),
              'under': double.tryParse(cleanField(data['under']) ?? '') ?? 0,
              'back_length': double.tryParse(cleanField(data['back_length']) ?? '') ?? 0,
              'neck': double.tryParse(cleanField(data['neck']) ?? '') ?? 0,
              'shoulder': double.tryParse(cleanField(data['shoulder']) ?? '') ?? 0,
              'seam': cleanField(data['seam']) ?? '',
              'adhesive': cleanField(data['adhesive']) ?? '',
              'under_kandura': cleanField(data['under_kandura']) ?? '',
              'tarboosh': cleanField(data['tarboosh']) ?? '',
              'open_sleeve': cleanField(data['open_sleeve']) ?? '',
              'stitching': cleanField(data['stitching']) ?? '',
              'pleat': cleanField(data['pleat']) ?? '',
              'button': cleanField(data['button']) ?? '',
              'cuff': cleanField(data['cuff']) ?? '',
              'embroidery': cleanField(data['embroidery']) ?? '',
              'neck_style': cleanField(data['neck_style']) ?? '',
              'notes': cleanField(data['notes']) ?? '',
              'date': (data['date'] == null || data['date'].toString().trim().isEmpty)
                  ? DateTime.now().toIso8601String() : data['date'].toString(),
              'last_updated': (data['last_updated'] == null || data['last_updated'].toString().trim().isEmpty)
                  ? DateTime.now().toIso8601String() : data['last_updated'].toString(),
            };
            await _measurementService.addMeasurementWithoutId(measurementData);
          }
        } else if (recordType == 'measurement') {
          // For measurement rows, always insert new record.
          final billNumber = data['bill_number']?.toString() ?? '';
          final customerId = await _getCustomerIdFromBillNumber(billNumber);
          
          final measurementData = {
            'customer_id': customerId, // Add this line
            'bill_number': billNumber,
            'style': data['style']?.toString() ?? '',
            'design_type': data['design_type']?.toString() ?? '',
            'tarboosh_type': data['tarboosh_type']?.toString() ?? '',
            'fabric_name': data['fabric_name']?.toString() ?? '',
            'length_arabi':
                double.tryParse(data['length_arabi']?.toString() ?? '') ?? 0,
            'length_kuwaiti':
                double.tryParse(data['length_kuwaiti']?.toString() ?? '') ?? 0,
            'chest': double.tryParse(data['chest']?.toString() ?? '') ?? 0,
            'width': double.tryParse(data['width']?.toString() ?? '') ?? 0,
            'sleeve': double.tryParse(data['sleeve']?.toString() ?? '') ?? 0,
            'collar': _parseCollar(data['collar']?.toString()),
            'under': double.tryParse(data['under']?.toString() ?? '') ?? 0,
            'back_length':
                double.tryParse(data['back_length']?.toString() ?? '') ?? 0,
            'neck': double.tryParse(data['neck']?.toString() ?? '') ?? 0,
            'shoulder':
                double.tryParse(data['shoulder']?.toString() ?? '') ?? 0,
            'seam': data['seam']?.toString() ?? '',
            'adhesive': data['adhesive']?.toString() ?? '',
            'under_kandura': data['under_kandura']?.toString() ?? '',
            'tarboosh': data['tarboosh']?.toString() ?? '',
            'open_sleeve': data['open_sleeve']?.toString() ?? '',
            'stitching': data['stitching']?.toString() ?? '',
            'pleat': data['pleat']?.toString() ?? '',
            'button': data['button']?.toString() ?? '',
            'cuff': data['cuff']?.toString() ?? '',
            'embroidery': data['embroidery']?.toString() ?? '',
            'neck_style': data['neck_style']?.toString() ?? '',
            'notes': data['notes']?.toString() ?? '',
            // Auto-set date fields if not provided.
            'date':
                (data['date'] == null || data['date'].toString().trim().isEmpty)
                    ? DateTime.now().toIso8601String()
                    : data['date'].toString(),
            'last_updated':
                (data['last_updated'] == null ||
                        data['last_updated'].toString().trim().isEmpty)
                    ? DateTime.now().toIso8601String()
                    : data['last_updated'].toString(),
          };
          await _measurementService.addMeasurementWithoutId(measurementData);
        }
      }
      _progressController.add('Import completed');
    } catch (e) {
      _progressController.add('Error: $e');
      if (kDebugMode) print('Error importing Excel data: $e');
      rethrow;
    }
  }

  // Modified exportExcel to support filters.
  // In combined (all) mode, for each customer we fetch all measurements
  // and output one row per measurement. If no measurement, output one row with blanks.
  Future<File> exportExcel({
    ExportFilterType filter = ExportFilterType.all,
  }) async {
    try {
      _progressController.add('Preparing export...');
      final excel = Excel.createExcel();
      final sheet = excel['Data'];

      if (filter == ExportFilterType.customer) {
        final headers = [
          'record_type',
          'bill_number',
          'name',
          'phone',
          'whatsapp',
          'address',
          'gender',
          'created_at',
          'referred_by',
          'family_id',
          'family_relation',
        ];
        sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
        _progressController.add('Exporting customers...');
        final customers = await _supabaseService.getAllCustomers();
        for (var customer in customers) {
          sheet.appendRow([
            TextCellValue('customer'),
            TextCellValue(customer.billNumber),
            TextCellValue(customer.name),
            TextCellValue(customer.phone),
            TextCellValue(customer.whatsapp),
            TextCellValue(customer.address),
            TextCellValue(customer.gender.name),
            TextCellValue(customer.createdAt.toIso8601String()),
            TextCellValue(customer.referredBy ?? ''),
            TextCellValue(customer.familyId ?? ''),
            TextCellValue(customer.familyRelation?.name ?? ''),
          ]);
        }
      } else if (filter == ExportFilterType.measurement) {
        final headers = [
          'record_type',
          'bill_number',
          'customer_name',    // Add these customer detail columns
          'customer_phone',
          'style',
          'design_type',
          'tarboosh_type',
          'fabric_name',
          'length_arabi',
          'length_kuwaiti',
          'chest',
          'width',
          'sleeve',
          'collar',
          'under',
          'back_length',
          'neck',
          'shoulder',
          'seam',
          'adhesive',
          'under_kandura',
          'tarboosh',
          'open_sleeve',
          'stitching',
          'pleat',
          'button',
          'cuff',
          'embroidery',
          'neck_style',
          'notes',
          'date',
          'last_updated',
        ];
        sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
        _progressController.add('Exporting measurements...');
        final measurements = await _measurementService.getAllMeasurements();
        for (var measurement in measurements) {
          // Get customer details for this measurement
          final customer = await _supabaseService.getCustomerByBillNumber(measurement.billNumber);

          sheet.appendRow([
            TextCellValue('measurement'),
            TextCellValue(measurement.billNumber),
            TextCellValue(customer?.name ?? ''),
            TextCellValue(customer?.phone ?? ''),
            TextCellValue(measurement.style),
            TextCellValue(measurement.designType),
            TextCellValue(measurement.tarbooshType),
            TextCellValue(measurement.fabricName),
            DoubleCellValue(double.tryParse(measurement.lengthArabi.toString()) ?? 0.0),
            DoubleCellValue(double.tryParse(measurement.lengthKuwaiti.toString()) ?? 0.0),
            DoubleCellValue(double.tryParse(measurement.chest.toString()) ?? 0.0),
            DoubleCellValue(double.tryParse(measurement.width.toString()) ?? 0.0),
            DoubleCellValue(double.tryParse(measurement.sleeve.toString()) ?? 0.0),
            TextCellValue(_formatCollar(_parseCollar(measurement.collar.toString()))),
            DoubleCellValue(double.tryParse(measurement.under.toString()) ?? 0.0),
            DoubleCellValue(double.tryParse(measurement.backLength.toString()) ?? 0.0),
            DoubleCellValue(double.tryParse(measurement.neck.toString()) ?? 0.0),
            DoubleCellValue(double.tryParse(measurement.shoulder.toString()) ?? 0.0),
            TextCellValue(measurement.seam),
            TextCellValue(measurement.adhesive),
            TextCellValue(measurement.underKandura),
            TextCellValue(measurement.tarboosh),
            TextCellValue(measurement.openSleeve),
            TextCellValue(measurement.stitching),
            TextCellValue(measurement.pleat),
            TextCellValue(measurement.button),
            TextCellValue(measurement.cuff),
            TextCellValue(measurement.embroidery),
            TextCellValue(measurement.neckStyle),
            TextCellValue(measurement.notes),
            TextCellValue(measurement.date.toIso8601String()),
            TextCellValue(measurement.lastUpdated.toIso8601String()),
          ]);
        }
      } else {
        // Combined export (default)
        final headers = [
          'record_type',
          'bill_number',
          'name',
          'phone',
          'whatsapp',
          'address',
          'gender',
          'created_at',
          'referred_by',
          'family_id',
          'family_relation',
          'style',
          'design_type',
          'tarboosh_type',
          'fabric_name',
          'length_arabi',
          'length_kuwaiti',
          'chest',
          'width',
          'sleeve',
          'collar',
          'under',
          'back_length',
          'neck',
          'shoulder',
          'seam',
          'adhesive',
          'under_kandura',
          'tarboosh',
          'open_sleeve',
          'stitching',
          'pleat',
          'button',
          'cuff',
          'embroidery',
          'neck_style',
          'notes',
          'date',
          'last_updated',
        ];
        sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
        _progressController.add('Exporting combined data...');
        final customers = await _supabaseService.getAllCustomers();
        for (var customer in customers) {
          // Get all measurements for this customer.
          final measurements = await _measurementService
              .getMeasurementsByBillNumber(customer.billNumber);
          // If none, output one row with measurement columns empty.
          if (measurements.isEmpty) {
            sheet.appendRow([
              TextCellValue('customer'),
              TextCellValue(customer.billNumber),
              TextCellValue(customer.name),
              TextCellValue(customer.phone),
              TextCellValue(customer.whatsapp),
              TextCellValue(customer.address),
              TextCellValue(customer.gender.name),
              TextCellValue(customer.createdAt.toIso8601String()),
              TextCellValue(customer.referredBy ?? ''),
              TextCellValue(customer.familyId ?? ''),
              TextCellValue(customer.familyRelation?.name ?? ''),
              ...List.filled(28, TextCellValue('')),
            ]);
          } else {
            // For each measurement, output a row combining customer details.
            for (var measurement in measurements) {
              sheet.appendRow([
                TextCellValue('customer'),
                TextCellValue(customer.billNumber),
                TextCellValue(customer.name),
                TextCellValue(customer.phone),
                TextCellValue(customer.whatsapp ),
                TextCellValue(customer.address),
                TextCellValue(customer.gender.name),
                TextCellValue(customer.createdAt.toIso8601String()),
                TextCellValue(customer.referredBy ?? ''),
                TextCellValue(customer.familyId ?? ''),
                TextCellValue(customer.familyRelation?.name ?? ''),
                TextCellValue(measurement.style),
                TextCellValue(measurement.designType),
                TextCellValue(measurement.tarbooshType),
                TextCellValue(measurement.fabricName),
                DoubleCellValue(double.tryParse(measurement.lengthArabi.toString()) ?? 0.0),
                DoubleCellValue(double.tryParse(measurement.lengthKuwaiti.toString()) ?? 0.0),
                DoubleCellValue(double.tryParse(measurement.chest.toString()) ?? 0.0),
                DoubleCellValue(double.tryParse(measurement.width.toString()) ?? 0.0),
                DoubleCellValue(double.tryParse(measurement.sleeve.toString()) ?? 0.0),
                TextCellValue(_formatCollar(_parseCollar(measurement.collar.toString()))),
                DoubleCellValue(double.tryParse(measurement.under.toString()) ?? 0.0),
                DoubleCellValue(double.tryParse(measurement.backLength.toString()) ?? 0.0),
                DoubleCellValue(double.tryParse(measurement.neck.toString()) ?? 0.0),
                DoubleCellValue(double.tryParse(measurement.shoulder.toString()) ?? 0.0),
                TextCellValue(measurement.seam),
                TextCellValue(measurement.adhesive),
                TextCellValue(measurement.underKandura),
                TextCellValue(measurement.tarboosh),
                TextCellValue(measurement.openSleeve),
                TextCellValue(measurement.stitching),
                TextCellValue(measurement.pleat),
                TextCellValue(measurement.button),
                TextCellValue(measurement.cuff),
                TextCellValue(measurement.embroidery),
                TextCellValue(measurement.neckStyle),
                TextCellValue(measurement.notes),
                TextCellValue(measurement.date.toIso8601String()),
                TextCellValue(measurement.lastUpdated.toIso8601String()),
              ]);
            }
          }
        }
      }

      _progressController.add('Saving file...');
      final fileBytes = excel.encode();
      final directory = Directory.systemTemp;
      final file =
          File('${directory.path}/exported_data.xlsx')
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes!);
      _progressController.add('Export completed');
      return file;
    } catch (e) {
      _progressController.add('Error: $e');
      rethrow;
    }
  }

  Map<String, double> _parseCollar(String? value) {
    if (value == null || value.isEmpty) {
      return {'start': 0.0, 'center': 0.0, 'end': 0.0};
    }
    try {
      final parts = value.split(' ');
      final start = double.tryParse(parts[0].split(':')[1]) ?? 0.0;
      final center = double.tryParse(parts[1].split(':')[1]) ?? 0.0;
      final end = double.tryParse(parts[2].split(':')[1]) ?? 0.0;
      return {'start': start, 'center': center, 'end': end};
    } catch (e) {
      return {'start': 0.0, 'center': 0.0, 'end': 0.0};
    }
  }

  String _formatCollar(Map<String, double> collar) {
    return 'S:${collar['start'] ?? 0} C:${collar['center'] ?? 0} E:${collar['end'] ?? 0}';
  }

  void dispose() {
    _progressController.close();
  }
}
