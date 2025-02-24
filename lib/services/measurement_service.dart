import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/measurement.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class MeasurementService {
  final SupabaseClient _client = Supabase.instance.client;
  StreamController<List<Measurement>>? _measurementsController;
  StreamSubscription? _subscription;
  Timer? _reconnectionTimer;
  bool _isConnected = false;

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

  Future<Measurement?> getMeasurementByBillNumber(String billNumber) async {
    try {
      final response = await _client
          .from('measurements')
          .select()
          .eq('bill_number', billNumber)
          .maybeSingle();
      return response != null ? Measurement.fromMap(response) : null;
    } catch (e) {
      debugPrint('Error in getMeasurementByBillNumber: $e');
      return null;
    }
  }

  Future<void> updateMeasurementByBillNumber(String billNumber, Map<String, dynamic> measurementData) async {
    await _client.from('measurements').update(measurementData).eq('bill_number', billNumber);
  }

  Future<void> addMeasurementWithoutId(Map<String, dynamic> measurementData) async {
    // Remove id so Supabase auto-generates it.
    final dataToInsert = Map<String, dynamic>.from(measurementData)..remove('id');
    await _client.from('measurements').insert(dataToInsert);
  }

  // Get measurements stream with improved error handling
  Stream<List<Measurement>> getMeasurementsStream() {
    _measurementsController?.close();
    _measurementsController = StreamController<List<Measurement>>.broadcast(
      onListen: () => _initializeStream(),
      onCancel: () => _disposeStream(),
    );

    return _measurementsController!.stream;
  }

  void _initializeStream() {
    _reconnectToStream();
  }

  void _disposeStream() {
    _subscription?.cancel();
    _reconnectionTimer?.cancel();
    _isConnected = false;
  }

  Future<void> _reconnectToStream() async {
    if (_isConnected) return;

    try {
      _subscription?.cancel();
      _subscription = _client
          .from('measurements')
          .stream(primaryKey: ['id'])
          .order('date', ascending: false)
          .map((maps) => maps.map((map) => Measurement.fromMap(map)).toList())
          .listen(
            (data) {
              if (!(_measurementsController?.isClosed ?? true)) {
                _measurementsController?.add(data);
              }
              _isConnected = true;
              _reconnectionTimer?.cancel();
            },
            onError: (error) {
              debugPrint('Error in measurements stream: $error');
              _isConnected = false;
              _scheduleReconnection();
            },
            cancelOnError: false,
          );
    } catch (e) {
      debugPrint('Error establishing stream connection: $e');
      _isConnected = false;
      _scheduleReconnection();
    }
  }

  void _scheduleReconnection() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected && !(_measurementsController?.isClosed ?? true)) {
        _reconnectToStream();
      }
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

  Future<List<Measurement>> getAllMeasurements() async {
    final response = await _client.from('measurements').select();
    return (response as List).map((map) => Measurement.fromMap(map)).toList();
  }

  Future<List<Measurement>> getMeasurementsByBillNumber(String billNumber) async {
    final response = await _client
        .from('measurements')
        .select()
        .eq('bill_number', billNumber);
    return (response as List).map((map) => Measurement.fromMap(map)).toList();
  }

  Future<List<Measurement>> getMeasurementsByCustomerId(String customerId) async {
    final response = await _client
        .from('measurements')
        .select()
        .eq('customer_id', customerId)
        .order('date', ascending: false);
    return (response as List).map((map) => Measurement.fromMap(map)).toList();
  }

  Future<bool> customerHasMeasurements(String customerId) async {
    final response = await _client
        .from('measurements')
        .select('id')
        .eq('customer_id', customerId)
        .limit(1)
        .maybeSingle();
    return response != null;
  }
}
