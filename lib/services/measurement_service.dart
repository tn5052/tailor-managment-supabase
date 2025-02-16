import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/measurement.dart';

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

  // Get measurements stream
  Stream<List<Measurement>> getMeasurementsStream() {
    return _client
        .from('measurements')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false)
        .map((maps) => maps.map((map) => Measurement.fromMap(map)).toList());
  }
}
