import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/measurement.dart';
import '../../models/measurement_filter.dart';
import 'measurement_list_item.dart';

class MeasurementList extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final List<Measurement> measurements;
  final MeasurementGroupBy groupBy;

  const MeasurementList({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.measurements,
    this.groupBy = MeasurementGroupBy.none,
  });

  @override
  State<MeasurementList> createState() => _MeasurementListState();
}

class _MeasurementListState extends State<MeasurementList> {
  final Map<String, bool> _expandedGroups = {};

  @override
  Widget build(BuildContext context) {
    if (widget.measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.measurements.isEmpty
                  ? Icons.straighten
                  : Icons.search_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.measurements.isEmpty ? 'No measurements yet' : 'No results found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (widget.groupBy == MeasurementGroupBy.none) {
      return _buildList(widget.measurements);
    }

    final groupedMeasurements = _groupMeasurements();
    return ListView.builder(
      itemCount: groupedMeasurements.length,
      itemBuilder: (context, index) {
        final group = groupedMeasurements.entries.elementAt(index);
        final title = group.key;
        final measurements = group.value;
        final isExpanded = _expandedGroups[title] ?? false;

        return _buildCollapsibleGroup(context, title, measurements, isExpanded);
      },
    );
  }

  Widget _buildList(List<Measurement> measurements) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final measurement = measurements[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MeasurementListItem(
            measurement: measurement,
            index: index,
            isDesktop: widget.isDesktop,
          ),
        );
      },
    );
  }

  Widget _buildCollapsibleGroup(BuildContext context, String title, List<Measurement> measurements, bool isExpanded) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedGroups[title] = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getGroupIcon(),
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${measurements.length} items',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Removed AnimatedSize widget
        if (isExpanded)
          Column(
            children: measurements.map((measurement) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: MeasurementListItem(
                measurement: measurement,
                index: widget.measurements.indexOf(measurement),
                isDesktop: widget.isDesktop,
              ),
            )).toList(),
          ),
      ],
    );
  }

  IconData _getGroupIcon() {
    switch (widget.groupBy) {
      case MeasurementGroupBy.customer:
        return Icons.people_alt_outlined;
      case MeasurementGroupBy.date:
        return Icons.event_outlined;
      case MeasurementGroupBy.month:
        return Icons.calendar_view_month_outlined;
      case MeasurementGroupBy.style:
        return Icons.style_outlined;
      case MeasurementGroupBy.designType:
        return Icons.design_services_outlined;
      case MeasurementGroupBy.none:
        return Icons.grid_view_outlined;
    }
  }

  Map<String, List<Measurement>> _groupMeasurements() {
    final grouped = <String, List<Measurement>>{};
    
    switch (widget.groupBy) {
      case MeasurementGroupBy.customer:
        for (var m in widget.measurements) {
          final key = m.billNumber; // Changed to use billNumber directly
          grouped.putIfAbsent(key, () => []).add(m);
        }
        break;
        
      case MeasurementGroupBy.date:
        final dateFormat = DateFormat('MMMM d, yyyy');
        for (var m in widget.measurements) {
          final key = dateFormat.format(m.date);
          grouped.putIfAbsent(key, () => []).add(m);
        }
        // Sort keys by date descending
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => DateFormat('MMMM d, yyyy')
              .parse(b)
              .compareTo(DateFormat('MMMM d, yyyy').parse(a)));
        return Map.fromEntries(
          sortedKeys.map((key) => MapEntry(key, grouped[key]!))
        );
        
      case MeasurementGroupBy.month:
        final monthFormat = DateFormat('MMMM yyyy');
        for (var m in widget.measurements) {
          final key = monthFormat.format(m.date);
          grouped.putIfAbsent(key, () => []).add(m);
        }
        // Sort keys by month descending
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => DateFormat('MMMM yyyy')
              .parse(b)
              .compareTo(DateFormat('MMMM yyyy').parse(a)));
        return Map.fromEntries(
          sortedKeys.map((key) => MapEntry(key, grouped[key]!))
        );
        
      case MeasurementGroupBy.style:
        for (var m in widget.measurements) {
          grouped.putIfAbsent(m.style, () => []).add(m);
        }
        // Sort keys alphabetically
        final sortedKeys = grouped.keys.toList()..sort();
        return Map.fromEntries(
          sortedKeys.map((key) => MapEntry(key, grouped[key]!))
        );
        
      case MeasurementGroupBy.designType:
        for (var m in widget.measurements) {
          grouped.putIfAbsent(m.designType, () => []).add(m);
        }
        // Sort keys alphabetically
        final sortedKeys = grouped.keys.toList()..sort();
        return Map.fromEntries(
          sortedKeys.map((key) => MapEntry(key, grouped[key]!))
        );
        
      case MeasurementGroupBy.none:
        grouped[''] = widget.measurements;
        break;
    }

    return grouped;
  }
}