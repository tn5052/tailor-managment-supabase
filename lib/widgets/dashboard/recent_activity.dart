import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/invoice.dart';
import '../../models/measurement.dart';
import '../../utils/number_formatter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../widgets/measurement/detail_dialog.dart';
import '../../widgets/invoice/invoice_details_dialog.dart';

class RecentActivity extends StatelessWidget {
  final List<Invoice> invoices;
  final List<Measurement>? measurements;
  
  const RecentActivity({
    super.key,
    required this.invoices,
    this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentActivities = _getAllActivities();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recent Activities',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentActivities.length,
            itemBuilder: (context, index) {
              final activity = recentActivities[index];
              return _ActivityItem(
                activity: activity,
                onView: () => _handleViewActivity(context, activity),
              ).animate(delay: Duration(milliseconds: index * 50))
                .fadeIn()
                .slideX();
            },
          ),
        ],
      ),
    );
  }

  List<_Activity> _getAllActivities() {
    final activities = <_Activity>[];
    final now = DateTime.now();

    // Add invoice activities
    for (final invoice in invoices) {
      if (invoice.deliveredAt != null) {
        activities.add(_Activity(
          title: 'Order Delivered',
          description: 'Invoice #${invoice.invoiceNumber} delivered',
          timestamp: invoice.deliveredAt!,
          icon: Icons.local_shipping,
          color: Colors.green,
          type: ActivityType.invoice,
          data: invoice,
          amount: invoice.amountIncludingVat,
          status: invoice.deliveryStatus.toString().split('.').last,
          customerName: invoice.customerName,
        ));
      }

      if (invoice.paidAt != null) {
        activities.add(_Activity(
          title: 'Payment Received',
          description: '${NumberFormatter.formatCurrency(invoice.amountIncludingVat)} received for #${invoice.invoiceNumber}',
          timestamp: invoice.paidAt!,
          icon: Icons.payments,
          color: Colors.blue,
          type: ActivityType.invoice,
          data: invoice,
          amount: invoice.amountIncludingVat,
          status: invoice.paymentStatus.toString().split('.').last,
          customerName: invoice.customerName,
        ));
      }

      // New orders
      if (invoice.date.isAfter(now.subtract(const Duration(days: 7)))) {
        activities.add(_Activity(
          title: 'New Invoice',
          description: 'Order #${invoice.invoiceNumber} for ${invoice.customerName}',
          timestamp: invoice.date,
          icon: Icons.receipt,
          color: Colors.purple,
          type: ActivityType.invoice,
          data: invoice,
          amount: invoice.amountIncludingVat,
          status: invoice.paymentStatus.toString().split('.').last,
          customerName: invoice.customerName,
        ));
      }
    }

    // Add measurement activities
    if (measurements != null) {
      for (final measurement in measurements!) {
        if (measurement.date.isAfter(now.subtract(const Duration(days: 7)))) {
          activities.add(_Activity(
            title: 'New Measurement',
            description: 'Measurements taken for ${measurement.style} style',
            timestamp: measurement.date,
            icon: Icons.straighten,
            color: Colors.teal,
            type: ActivityType.measurement,
            data: measurement,
            customerName: measurement.billNumber,
            status: 'Created',
          ));
        }
      }
    }

    // Sort by timestamp
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(15).toList(); // Show more recent activities
  }

  void _handleViewActivity(BuildContext context, _Activity activity) {
    switch (activity.type) {
      case ActivityType.invoice:
        // Fix: Replace "invoice:" with just the invoice argument
        InvoiceDetailsDialog.show(
          context,
          activity.data as Invoice,
        );
        break;
      case ActivityType.measurement:
        DetailDialog.show(
          context,
          measurement: activity.data as Measurement,
          customerId: (activity.data as Measurement).customerId,
        );
        break;
    }
  }
}

enum ActivityType { invoice, measurement }

class _Activity {
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final ActivityType type;
  final dynamic data;
  final double? amount;
  final String status;
  final String customerName;

  _Activity({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
    required this.type,
    required this.data,
    this.amount,
    required this.status,
    required this.customerName,
  });
}

class _ActivityItem extends StatelessWidget {
  final _Activity activity;
  final VoidCallback onView;

  const _ActivityItem({
    required this.activity,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activity.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  activity.icon,
                  color: activity.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          activity.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (activity.amount != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              NumberFormatter.formatCurrency(activity.amount!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.customerName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: activity.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            activity.status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: activity.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeago.format(activity.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    tooltip: 'View Details',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
