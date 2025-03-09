import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/measurement.dart';
import '../utils/tenant_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class MeasurementService {
  final SupabaseClient _client = Supabase.instance.client;
  StreamController<List<Measurement>>? _measurementsController;
  StreamSubscription? _subscription;
  Timer? _reconnectionTimer;
  Timer? _pollingTimer;
  bool _isConnected = false;
  bool _usePolling = false;
  
  // Configure timeouts and polling intervals
  final Duration _reconnectionDelay = const Duration(seconds: 5);
  final Duration _pollingInterval = const Duration(seconds: 8);
  final int _maxReconnectAttempts = 3;
  int _reconnectAttempts = 0;

  // Add measurement
  Future<void> addMeasurement(Measurement measurement) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    final measurementMap = measurement.toMap();
    measurementMap['tenant_id'] = tenantId;
    await _client.from('measurements').insert(measurementMap);
  }

  // Update measurement
  Future<void> updateMeasurement(Measurement measurement) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    await _client
        .from('measurements')
        .update(measurement.toMap())
        .eq('id', measurement.id)
        .eq('tenant_id', tenantId);
  }

  // Delete measurement
  Future<void> deleteMeasurement(String measurementId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    await _client
        .from('measurements')
        .delete()
        .eq('id', measurementId)
        .eq('tenant_id', tenantId);
  }

  // Get measurement
  Future<Measurement?> getMeasurement(String measurementId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    final response = await _client
        .from('measurements')
        .select()
        .eq('id', measurementId)
        .eq('tenant_id', tenantId)
        .single();
    
    return Measurement.fromMap(response);
  }

  Future<Measurement?> getMeasurementByBillNumber(String billNumber) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response = await _client
          .from('measurements')
          .select()
          .eq('bill_number', billNumber)
          .eq('tenant_id', tenantId)
          .maybeSingle();
      return response != null ? Measurement.fromMap(response) : null;
    } catch (e) {
      debugPrint('Error in getMeasurementByBillNumber: $e');
      return null;
    }
  }

  Future<void> updateMeasurementByBillNumber(String billNumber, Map<String, dynamic> measurementData) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    await _client
        .from('measurements')
        .update(measurementData)
        .eq('bill_number', billNumber)
        .eq('tenant_id', tenantId);
  }

  Future<void> addMeasurementWithoutId(Map<String, dynamic> measurementData) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    // Remove id so Supabase auto-generates it.
    final dataToInsert = Map<String, dynamic>.from(measurementData)..remove('id');
    dataToInsert['tenant_id'] = tenantId;
    await _client.from('measurements').insert(dataToInsert);
  }

  // Get measurements stream with improved error handling and fallback polling
  Stream<List<Measurement>> getMeasurementsStream() {
    _measurementsController?.close();
    _measurementsController = StreamController<List<Measurement>>.broadcast(
      onListen: () => _initializeStream(),
      onCancel: () => _disposeStream(),
    );

    return _measurementsController!.stream;
  }

  void _initializeStream() {
    _reconnectAttempts = 0;
    _usePolling = false;
    _reconnectToStream();
  }

  void _disposeStream() {
    _subscription?.cancel();
    _reconnectionTimer?.cancel();
    _pollingTimer?.cancel();
    _isConnected = false;
  }

  Future<void> _reconnectToStream() async {
    if (_isConnected || _usePolling) return;
    final String tenantId = TenantManager.getCurrentTenantId();
    
    try {
      _subscription?.cancel();
      debugPrint('Attempting to establish realtime connection for measurements...');
      
      _subscription = _client
          .from('measurements')
          .stream(primaryKey: ['id'])
          .eq('tenant_id', tenantId)
          .order('date', ascending: false)
          .map((maps) => maps.map((map) => Measurement.fromMap(map)).toList())
          .listen(
            (data) {
              if (!(_measurementsController?.isClosed ?? true)) {
                _measurementsController?.add(data);
              }
              _isConnected = true;
              _reconnectAttempts = 0;
              _reconnectionTimer?.cancel();
              debugPrint('Realtime measurements stream connected successfully');
            },
            onError: (error) {
              debugPrint('Error in measurements stream: $error');
              _isConnected = false;
              
              // Check if we should switch to polling
              if (++_reconnectAttempts >= _maxReconnectAttempts) {
                debugPrint('Max reconnection attempts reached. Switching to polling.');
                _switchToPolling();
              } else {
                _scheduleReconnection();
              }
            },
            cancelOnError: false,
          );
    } catch (e) {
      debugPrint('Error establishing stream connection: $e');
      _isConnected = false;
      
      if (++_reconnectAttempts >= _maxReconnectAttempts) {
        _switchToPolling();
      } else {
        _scheduleReconnection();
      }
    }
  }

  void _scheduleReconnection() {
    _reconnectionTimer?.cancel();
    debugPrint('Scheduling realtime reconnection attempt ${_reconnectAttempts+1}/$_maxReconnectAttempts...');
    _reconnectionTimer = Timer(_reconnectionDelay, () {
      if (!_isConnected && !_usePolling && !(_measurementsController?.isClosed ?? true)) {
        _reconnectToStream();
      }
    });
  }

  void _switchToPolling() {
    _usePolling = true;
    _subscription?.cancel();
    _reconnectionTimer?.cancel();
    debugPrint('Switching to polling for measurements data');
    
    // Start polling immediately
    _pollMeasurements();
    
    // Then set up regular polling interval
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _pollMeasurements();
    });
  }

  Future<void> _pollMeasurements() async {
    if (_measurementsController?.isClosed ?? true) {
      _pollingTimer?.cancel();
      return;
    }
    
    final String tenantId = TenantManager.getCurrentTenantId();
    
    try {
      debugPrint('Polling measurements data...');
      final response = await _client
          .from('measurements')
          .select()
          .eq('tenant_id', tenantId)
          .order('date', ascending: false);
      
      final measurements = (response as List).map((map) => Measurement.fromMap(map)).toList();
      
      if (!(_measurementsController?.isClosed ?? true)) {
        _measurementsController?.add(measurements);
      }
    } catch (e) {
      debugPrint('Error polling measurements: $e');
      // Still send empty list to keep stream active
      if (!(_measurementsController?.isClosed ?? true)) {
        _measurementsController?.add([]);
      }
    }
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
    final String tenantId = TenantManager.getCurrentTenantId();
    final response = await _client
        .from('measurements')
        .select()
        .eq('tenant_id', tenantId);
    return (response as List).map((map) => Measurement.fromMap(map)).toList();
  }

  Future<List<Measurement>> getMeasurementsByBillNumber(String billNumber) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    final response = await _client
        .from('measurements')
        .select()
        .eq('bill_number', billNumber)
        .eq('tenant_id', tenantId);
    return (response as List).map((map) => Measurement.fromMap(map)).toList();
  }

  Future<List<Measurement>> getMeasurementsByCustomerId(String customerId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    final response = await _client
        .from('measurements')
        .select()
        .eq('customer_id', customerId)
        .eq('tenant_id', tenantId)
        .order('date', ascending: false);
    return (response as List).map((map) => Measurement.fromMap(map)).toList();
  }

  Future<bool> customerHasMeasurements(String customerId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    final response = await _client
        .from('measurements')
        .select('id')
        .eq('customer_id', customerId)
        .eq('tenant_id', tenantId)
        .limit(1)
        .maybeSingle();
    return response != null;
  }

  Future<int> getMeasurementCountByCustomerId(String customerId) async {
    try {
      final response = await Supabase.instance.client
          .from('measurements')
          .select('id')
          .eq('customer_id', customerId);
      
      return response.length;
    } catch (e) {
      debugPrint('Error getting measurement count: $e');
      return 0;
    }
  }
}
