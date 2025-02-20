import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/invoice.dart';
import '../../models/measurement.dart';
import '../../models/complaint.dart';  // Add this import
import '../../utils/number_formatter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../widgets/measurement/detail_dialog.dart';
import '../../widgets/invoice/invoice_details_dialog.dart';
import '../../widgets/complaint_detail_dialog.dart';  // Add this import
import '../../services/customer_service.dart';  // Add this import
import '../../theme/app_theme.dart';  // Corrected import path

class RecentActivity extends StatefulWidget {  // Change to StatefulWidget
  final List<Invoice> invoices;
  final List<Measurement>? measurements;
  final List<Complaint>? complaints;  // Add this parameter
  
  const RecentActivity({
    super.key,
    required this.invoices,
    this.measurements,
    this.complaints,  // Add this parameter
  });

  @override
  _RecentActivityState createState() => _RecentActivityState();
}

class _RecentActivityState extends State<RecentActivity> {
  final _customerService = CustomerService(Supabase.instance.client);
  final Map<String, String> _customerNames = {};
  static const int _initialItemCount = 10;

  @override
  void initState() {
    super.initState();
    _loadCustomerNames();
  }

  Future<void> _loadCustomerNames() async {
    if (widget.complaints == null) return;
    
    for (final complaint in widget.complaints!) {
      try {
        final customer = await _customerService.getCustomerById(complaint.customerId);
        if (mounted) {
          setState(() {
            _customerNames[complaint.customerId] = customer.name;
          });
        }
      } catch (e) {
        debugPrint('Error loading customer name: $e');
      }
    }
  }

  Color _getStatusColor(ComplaintStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case ComplaintStatus.pending:
        return isDark ? Colors.orange : AppTheme.warningColor;
      case ComplaintStatus.inProgress:
        return isDark ? Colors.blue : AppTheme.primaryColor;
      case ComplaintStatus.resolved:
        return isDark ? Colors.green : AppTheme.successColor;
      case ComplaintStatus.closed:
        return isDark ? Colors.grey : AppTheme.neutralColor;
      case ComplaintStatus.rejected:
        return isDark ? Colors.red : AppTheme.errorColor;
    }
  }

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
            itemCount: recentActivities.length > _initialItemCount 
                ? _initialItemCount + 1 // +1 for "Show More" button
                : recentActivities.length,
            itemBuilder: (context, index) {
              if (index == _initialItemCount) {
                return _buildShowMoreButton(
                  context, 
                  recentActivities,
                  theme,
                );
              }
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

  Widget _buildShowMoreButton(
    BuildContext context, 
    List<_Activity> activities,
    ThemeData theme,
  ) {
    return TextButton(
      onPressed: () => _showAllActivities(context, activities),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Show More Activities',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showAllActivities(BuildContext context, List<_Activity> activities) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * (isMobile ? 0.9 : 0.8),
            maxWidth: isMobile ? double.infinity : 600,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 28),
          ),
          child: Column(
            children: [
              _buildDialogHeader(context),
              Expanded(
                child: _buildActivityList(activities, isMobile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isMobile ? 12 : 28),
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            color: theme.colorScheme.primary,
            size: isMobile ? 20 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All Activities',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 18 : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<_Activity> activities, bool isMobile) {
    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _ActivityItem(
          activity: activity,
          onView: () {
            Navigator.pop(context);
            _handleViewActivity(context, activity);
          },
          isMobile: isMobile,
        );
      },
    );
  }


  List<_Activity> _getAllActivities() {
    final activities = <_Activity>[];
    final now = DateTime.now();

    // Add invoice activities
    for (final invoice in widget.invoices) {
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
    if (widget.measurements != null) {
      for (final measurement in widget.measurements!) {
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

    // Modified complaint activities
    if (widget.complaints != null) {
      for (final complaint in widget.complaints!) {
        final customerName = _customerNames[complaint.customerId] ?? 'Loading...';
        final statusColor = _getStatusColor(complaint.status);
        
        // New complaints
        if (complaint.createdAt.isAfter(now.subtract(const Duration(days: 7)))) {
          activities.add(_Activity(
            title: 'New Complaint',
            description: complaint.title,
            timestamp: complaint.createdAt,
            icon: Icons.report_problem_outlined,
            color: statusColor,  // Use status color
            type: ActivityType.complaint,
            data: complaint,
            status: complaint.status.toString().split('.').last,
            customerName: customerName,
          ));
        }

        // Resolved complaints
        if (complaint.resolvedAt != null && 
            complaint.resolvedAt!.isAfter(now.subtract(const Duration(days: 7)))) {
          activities.add(_Activity(
            title: 'Complaint Resolved',
            description: 'Resolved: ${complaint.title}',
            timestamp: complaint.resolvedAt!,
            icon: Icons.check_circle_outline,
            color: AppTheme.successColor,  // Always use success color for resolved
            type: ActivityType.complaint,
            data: complaint,
            status: 'Resolved',
            customerName: customerName,
          ));
        }

        // Refund related activities
        if (complaint.refundRequestedAt != null && 
            complaint.refundRequestedAt!.isAfter(now.subtract(const Duration(days: 7)))) {
          activities.add(_Activity(
            title: 'Refund Requested',
            description: 'Amount: ${NumberFormatter.formatCurrency(complaint.refundAmount ?? 0)}',
            timestamp: complaint.refundRequestedAt!,
            icon: Icons.currency_exchange,
            color: AppTheme.warningColor,  // Use warning color for pending refunds
            type: ActivityType.complaint,
            data: complaint,
            status: complaint.refundStatus.toString().split('.').last,
            customerName: customerName,
            amount: complaint.refundAmount,
          ));
        }

        // Completed refunds
        if (complaint.refundCompletedAt != null && 
            complaint.refundCompletedAt!.isAfter(now.subtract(const Duration(days: 7)))) {
          activities.add(_Activity(
            title: 'Refund Completed',
            description: 'Amount: ${NumberFormatter.formatCurrency(complaint.refundAmount ?? 0)}',
            timestamp: complaint.refundCompletedAt!,
            icon: Icons.check_circle,
            color: AppTheme.successColor,  // Use success color for completed refunds
            type: ActivityType.complaint,
            data: complaint,
            status: 'Refund Completed',
            customerName: customerName,
            amount: complaint.refundAmount,
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
      case ActivityType.complaint:
        showDialog(
          context: context,
          builder: (context) => ComplaintDetailDialog(
            complaint: activity.data as Complaint,
          ),
        );
        break;
    }
  }
}

enum ActivityType { invoice, measurement, complaint }  // Add this

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
  final bool isMobile;

  const _ActivityItem({
    required this.activity,
    required this.onView,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 16,
            vertical: isMobile ? 8 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: activity.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                ),
                child: Icon(
                  activity.icon,
                  color: activity.color,
                  size: isMobile ? 16 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 13 / textScale : null,
                            ),
                          ),
                        ),
                        if (!isMobile && activity.amount != null)
                          _buildAmountChip(theme),
                      ],
                    ),
                    if (isMobile && activity.amount != null) ...[
                      const SizedBox(height: 4),
                      _buildAmountChip(theme),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: isMobile ? 12 / textScale : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildFooter(theme, textScale),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                _buildTimeAndActions(theme, textScale),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountChip(ThemeData theme) {
    return Container(
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
    );
  }

  Widget _buildFooter(ThemeData theme, double textScale) {
    return Row(
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
            fontSize: isMobile ? 12 / textScale : null,
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
              fontSize: isMobile ? 12 / textScale : null,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return timeago.format(dateTime, allowFromNow: true);
    }
  }

  Widget _buildTimeAndActions(ThemeData theme, double textScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _getTimeAgo(activity.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: isMobile ? 11 / textScale : null,
          ),
        ),
        const SizedBox(height: 4),
        IconButton(
          onPressed: onView,
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'View Details',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
