import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/invoice.dart';

class StatusDistribution extends StatelessWidget {
  final List<Invoice> invoices;
  
  const StatusDistribution({
    super.key,
    required this.invoices,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _calculateStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Status',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    _buildStatusItem(
                      context,
                      'Pending',
                      stats.pending,
                      Colors.orange,
                      constraints.maxWidth / 3,
                    ),
                    _buildStatusItem(
                      context,
                      'In Progress',
                      stats.inProgress,
                      Colors.blue,
                      constraints.maxWidth / 3,
                    ),
                    _buildStatusItem(
                      context,
                      'Completed',
                      stats.completed,
                      Colors.green,
                      constraints.maxWidth / 3,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    int count,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: count / invoices.length,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ).animate().fadeIn().slideX(),
        ],
      ),
    );
  }

  _StatusStats _calculateStats() {
    int pending = 0, inProgress = 0, completed = 0;

    for (final invoice in invoices) {
      if (invoice.deliveryStatus == InvoiceStatus.delivered) {
        completed++;
      } else if (invoice.deliveryStatus == InvoiceStatus.pending) {
        pending++;
      } else {
        inProgress++;
      }
    }

    return _StatusStats(
      pending: pending,
      inProgress: inProgress,
      completed: completed,
    );
  }

}

class _StatusStats {
  final int pending;
  final int inProgress;
  final int completed;

  _StatusStats({
    required this.pending,
    required this.inProgress,
    required this.completed,
  });
}

class StatusItem {
  final String label;
  final int count;
  final int total;

  StatusItem({
    required this.label,
    required this.count,
    required this.total,
  });
}
