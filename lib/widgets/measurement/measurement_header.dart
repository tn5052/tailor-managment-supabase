import 'package:flutter/material.dart';

class MeasurementHeader extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onAddPressed;

  const MeasurementHeader({
    super.key,
    required this.isDesktop,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Measurements',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (isDesktop)
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add),
            label: const Text('Add Measurement'),
          ),
      ],
    );
  }
}
