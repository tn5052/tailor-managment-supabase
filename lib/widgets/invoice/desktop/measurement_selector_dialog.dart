import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/measurement.dart';
import '../../../services/measurement_service.dart';
import '../../../theme/inventory_design_config.dart';

class MeasurementSelectorDialog extends StatefulWidget {
  final String customerId;

  const MeasurementSelectorDialog({super.key, required this.customerId});

  static Future<Measurement?> show(
    BuildContext context, {
    required String customerId,
  }) {
    return showDialog<Measurement>(
      context: context,
      builder: (context) => MeasurementSelectorDialog(customerId: customerId),
    );
  }

  @override
  State<MeasurementSelectorDialog> createState() =>
      _MeasurementSelectorDialogState();
}

class _MeasurementSelectorDialogState extends State<MeasurementSelectorDialog> {
  final _measurementService = MeasurementService();
  final _searchController = TextEditingController();
  List<Measurement> _measurements = [];
  List<Measurement> _filteredMeasurements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMeasurements();
    _searchController.addListener(
      () => _filterMeasurements(_searchController.text),
    );
  }

  Future<void> _fetchMeasurements() async {
    try {
      final measurements = await _measurementService
          .getMeasurementsByCustomerId(widget.customerId);
      setState(() {
        _measurements = measurements;
        _filteredMeasurements = measurements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  void _filterMeasurements(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMeasurements = _measurements;
      } else {
        _filteredMeasurements =
            _measurements.where((m) {
              return m.style.toLowerCase().contains(query.toLowerCase()) ||
                  m.designType.toLowerCase().contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        height: 600,
        decoration: BoxDecoration(
          color: InventoryDesignConfig.surfaceColor,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        ),
        child: Column(
          children: [
            // Header, Search, List similar to CustomerSelectorDialog
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Measurement',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by style...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: _filteredMeasurements.length,
                        itemBuilder: (context, index) {
                          final measurement = _filteredMeasurements[index];
                          return ListTile(
                            title: Text(measurement.style),
                            subtitle: Text(
                              'Created: ${DateFormat.yMd().format(measurement.date)}',
                            ),
                            onTap: () => Navigator.pop(context, measurement),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
