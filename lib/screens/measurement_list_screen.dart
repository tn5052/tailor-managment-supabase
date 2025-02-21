import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../widgets/measurement/measurement_list.dart';
import '../widgets/measurement/add_measurement_dialog.dart';
import '../widgets/measurement/measurement_search_bar.dart';
import '../services/measurement_service.dart';
import '../../models/measurement_filter.dart';  // Add this import

class MeasurementListScreen extends StatefulWidget {
  const MeasurementListScreen({super.key});

  @override
  State<MeasurementListScreen> createState() => _MeasurementListScreenState();
}

class _MeasurementListScreenState extends State<MeasurementListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MeasurementService _measurementService = MeasurementService();
  MeasurementFilter _filter = const MeasurementFilter(); // Replace _searchQuery and _selectedDate with filter

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _filterMeasurement(Measurement measurement) {
    if (!_filter.hasActiveFilters && _filter.groupBy == MeasurementGroupBy.none) {
      return true;
    }

    bool matches = true;

    // Search query filter
    if (_filter.searchQuery.isNotEmpty) {
      final queryLower = _filter.searchQuery.toLowerCase();
      matches = matches && (
        measurement.billNumber.toLowerCase().contains(queryLower) ||
        measurement.style.toLowerCase().contains(queryLower)
      );
    }

    // Date range filter
    if (_filter.dateRange != null) {
      matches = matches && (
        measurement.date.isAfter(_filter.dateRange!.start.subtract(const Duration(days: 1))) &&
        measurement.date.isBefore(_filter.dateRange!.end.add(const Duration(days: 1)))
      );
    }

    // Style filter
    if (_filter.style != null) {
      matches = matches && measurement.style == _filter.style;
    }

    // Design type filter
    if (_filter.designType != null) {
      matches = matches && measurement.designType == _filter.designType;
    }

    // Only recent updates filter
    if (_filter.onlyRecentUpdates) {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      matches = matches && measurement.lastUpdated.isAfter(sevenDaysAgo);
    }

    return matches;
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MeasurementSearchBar(
                searchController: _searchController,
                onSearchChanged: (value) => setState(() {
                  _filter = _filter.copyWith(searchQuery: value);
                }),
                onClearSearch: () {
                  _searchController.clear();
                  setState(() {
                    _filter = _filter.copyWith(searchQuery: '');
                  });
                },
                filter: _filter,
                onFilterChanged: (newFilter) {
                  setState(() => _filter = newFilter);
                },
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
                      measurements.where((m) => _filterMeasurement(m)).toList();

                  return MeasurementList(
                    isDesktop: isDesktop,
                    isTablet: isTablet,
                    measurements: filteredMeasurements,
                    groupBy: _filter.groupBy, // Add this line
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: !isDesktop ? FloatingActionButton(
        onPressed: _showAddMeasurementDialog,
        elevation: 4,
        backgroundColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.add_rounded,
          color: theme.colorScheme.onPrimary,
          size: 28,
        ),
      ) : FloatingActionButton.extended(
        onPressed: _showAddMeasurementDialog,
        elevation: 4,
        backgroundColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        label: Text(
          'Add Measurement',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Icon(
          Icons.add_rounded,
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
      ),
    );
  }
}
