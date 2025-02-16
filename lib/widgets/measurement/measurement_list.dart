import 'package:flutter/material.dart';
import '../../models/measurement.dart';
import 'measurement_list_item.dart';

class MeasurementList extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final List<Measurement> measurements;

  const MeasurementList({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              measurements.isEmpty
                  ? Icons.straighten
                  : Icons.search_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              measurements.isEmpty ? 'No measurements yet' : 'No results found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
      itemCount: measurements.length,
      itemBuilder: (_, index) {
        final measurement = measurements[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12), // Adjust bottom spacing
          child: MeasurementListItem(
            measurement: measurement,
            index: index,
            isDesktop: isDesktop,
          ),
        );
      },
    );
  }
}
