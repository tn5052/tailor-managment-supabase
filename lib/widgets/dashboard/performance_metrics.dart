import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/invoice.dart';

class PerformanceMetrics extends StatelessWidget {
  final List<Invoice> invoices;

  const PerformanceMetrics({
    super.key,
    required this.invoices,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = _calculateMetrics();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance Metrics',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showInfo(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _MetricItem(
              label: 'Average Order Value',
              value: 'AED ${metrics.averageOrderValue.toStringAsFixed(2)}',
              icon: Icons.analytics,
              color: Colors.blue,
              trend: metrics.orderValueTrend,
            ),
            const SizedBox(height: 16),
            _MetricItem(
              label: 'Delivery Rate',
              value: '${(metrics.deliveryRate * 100).toStringAsFixed(1)}%',
              icon: Icons.local_shipping,
              color: Colors.green,
              trend: metrics.deliveryTrend,
            ),
            const SizedBox(height: 16),
            _MetricItem(
              label: 'Collection Rate',
              value: '${(metrics.collectionRate * 100).toStringAsFixed(1)}%',
              icon: Icons.payments,
              color: Colors.orange,
              trend: metrics.collectionTrend,
            ),
          ].animate(interval: const Duration(milliseconds: 100)).fadeIn().slideX(),
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metrics Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Average Order Value: Mean value of all orders'),
            Text('• Delivery Rate: % of orders delivered on time'),
            Text('• Collection Rate: % of payments collected'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  _Metrics _calculateMetrics() {
    if (invoices.isEmpty) {
      return _Metrics(
        averageOrderValue: 0,
        deliveryRate: 0,
        collectionRate: 0,
        orderValueTrend: 0,
        deliveryTrend: 0,
        collectionTrend: 0,
      );
    }

    final totalValue = invoices.fold(
      0.0,
      (sum, invoice) => sum + invoice.amountIncludingVat,
    );
    
    final deliveredCount = invoices
        .where((i) => i.deliveryStatus == InvoiceStatus.delivered)
        .length;
    
    final paidCount = invoices
        .where((i) => i.paymentStatus == PaymentStatus.paid)
        .length;

    return _Metrics(
      averageOrderValue: totalValue / invoices.length,
      deliveryRate: deliveredCount / invoices.length,
      collectionRate: paidCount / invoices.length,
      orderValueTrend: _calculateTrend(),
      deliveryTrend: 5.2,
      collectionTrend: 3.8,
    );
  }

  double _calculateTrend() {
    if (invoices.length < 2) return 0;
    
    final sortedInvoices = List<Invoice>.from(invoices)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final recent = sortedInvoices.take(sortedInvoices.length ~/ 2);
    final old = sortedInvoices.skip(sortedInvoices.length ~/ 2);
    
    final recentAvg = recent.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat) / recent.length;
    final oldAvg = old.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat) / old.length;
    
    return ((recentAvg - oldAvg) / oldAvg) * 100;
  }
}

class _Metrics {
  final double averageOrderValue;
  final double deliveryRate;
  final double collectionRate;
  final double orderValueTrend;
  final double deliveryTrend;
  final double collectionTrend;

  _Metrics({
    required this.averageOrderValue,
    required this.deliveryRate,
    required this.collectionRate,
    required this.orderValueTrend,
    required this.deliveryTrend,
    required this.collectionTrend,
  });
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double trend;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: trend >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  trend >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: trend >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trend.abs().toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: trend >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
