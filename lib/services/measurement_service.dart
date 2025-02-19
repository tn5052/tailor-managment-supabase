import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/measurement.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MeasurementService {
  final SupabaseClient _client = Supabase.instance.client;

  // Add measurement
  Future<void> addMeasurement(Measurement measurement) async {
    await _client.from('measurements').insert(measurement.toMap());
  }

  // Update measurement
  Future<void> updateMeasurement(Measurement measurement) async {
    await _client
        .from('measurements')
        .update(measurement.toMap())
        .eq('id', measurement.id);
  }

  // Delete measurement
  Future<void> deleteMeasurement(String measurementId) async {
    await _client.from('measurements').delete().eq('id', measurementId);
  }

  // Get measurement
  Future<Measurement?> getMeasurement(String measurementId) async {
    final response = await _client
        .from('measurements')
        .select()
        .eq('id', measurementId)
        .single();
    
    return Measurement.fromMap(response);
  }

  // Get measurements stream
  Stream<List<Measurement>> getMeasurementsStream() {
    return _client
        .from('measurements')
        .stream(primaryKey: ['id'])
        // Remove the deleted condition
        .order('date', ascending: false)
        .map((maps) => maps.map((map) => Measurement.fromMap(map)).toList())
        .handleError((error) {
          debugPrint('Error in measurements stream: $error');
          return [];
        });
  }

  Future<void> sharePdf(List<int> pdfBytes, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Measurement Details',
      );
    } catch (e) {
      print('Error sharing PDF: $e');
      rethrow;
    }
  }
}
