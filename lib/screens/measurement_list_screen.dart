import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../widgets/measurement/measurement_list.dart';
import '../widgets/measurement/add_measurement_dialog.dart';
import '../widgets/measurement/measurement_search_bar.dart';
import '../services/measurement_service.dart';

class MeasurementListScreen extends StatefulWidget {
  const MeasurementListScreen({super.key});

  @override
  State<MeasurementListScreen> createState() => _MeasurementListScreenState();
}

class _MeasurementListScreenState extends State<MeasurementListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MeasurementService _measurementService = MeasurementService();
  String _searchQuery = '';
  DateTime? _selectedDate;
  bool get isDesktop => MediaQuery.of(context).size.width >= 1024;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _filterMeasurement(Measurement measurement, String query) {
    if (query.isEmpty && _selectedDate == null) return true;

    final queryLower = query.toLowerCase();
    final matchesQuery =
        query.isEmpty ||
        measurement.billNumber.toLowerCase().contains(queryLower);

    if (_selectedDate == null) return matchesQuery;

    final measurementDate = DateTime(
      measurement.date.year,
      measurement.date.month,
      measurement.date.day,
    );
    final filterDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    return matchesQuery && measurementDate.isAtSameMomentAs(filterDate);
  }

  void _showAddMeasurementDialog() {
    AddMeasurementDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Measurements',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: !isDesktop,
        actions: [
          if (isDesktop) ...[
            FilledButton.icon(
              onPressed: _showAddMeasurementDialog,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Measurement'),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0, // Keep only vertical padding
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // Add padding only to search bar
              child: MeasurementSearchBar(
                searchController: _searchController,
                onSearchChanged:
                    (value) => setState(() => _searchQuery = value),
                onClearSearch: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                selectedDate: _selectedDate,
                onDateChanged: (date) => setState(() => _selectedDate = date),
                searchQuery: _searchQuery,
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Measurement>>(
                stream: _measurementService.getMeasurementsStream(),
                builder: (context, measurementSnapshot) {
                  if (measurementSnapshot.hasError) {
                    return Center(
                      child: Text('Error: ${measurementSnapshot.error}'),
                    );
                  }

                  if (measurementSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final measurements = measurementSnapshot.data ?? [];
                  final filteredMeasurements =
                      measurements
                          .where((m) => _filterMeasurement(m, _searchQuery))
                          .toList();

                  return MeasurementList(
                    isDesktop: isDesktop,
                    isTablet: isTablet,
                    measurements: filteredMeasurements,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMeasurementDialog,
        label: Text(
          isDesktop ? 'Add Measurement' : '',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        icon: Icon(
          Icons.add,
          color: theme.colorScheme.onPrimary,
        ),
        isExtended: isDesktop,
      ),
    );
  }
}
