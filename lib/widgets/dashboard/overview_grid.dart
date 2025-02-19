import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/invoice.dart';
import 'kpi_card.dart';
import '../../utils/number_formatter.dart';

class OverviewGrid extends StatelessWidget {
  final List<Invoice> invoices;
  final bool isExpanded;

  const OverviewGrid({
    super.key,
    required this.invoices,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final analytics = _calculateAnalytics();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 2 : 3;
        
        // Calculate dynamic aspect ratio based on content
        final aspectRatio = isMobile ? 1.2 : 1.5;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            KPICard(
              title: 'Today\'s Revenue',
              value: 'AED ${analytics.todayRevenue}',
              subtitle: '${NumberFormatter.formatCompactNumber(analytics.todayOrders)} orders today',
              icon: Icons.today,
              color: Colors.blue,
              trend: analytics.revenueTrend,
            ),
            KPICard(
              title: 'Monthly Revenue',
              value: 'AED ${analytics.monthlyRevenue}',
              subtitle: 'This month\'s total',
              icon: Icons.calendar_month,
              color: Colors.green,
              trend: analytics.monthlyTrend,
            ),
            KPICard(
              title: 'Pending Orders',
              value: analytics.pendingOrders.toString(),
              subtitle: 'Awaiting delivery',
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
            KPICard(
              title: 'Total Customers',
              value: analytics.uniqueCustomers.toString(),
              subtitle: 'Active customers',
              icon: Icons.people,
              color: Colors.purple,
              trend: analytics.customerGrowth,
            ),
            KPICard(
              title: 'Average Order Value',
              value: 'AED ${analytics.averageOrderValue}',
              subtitle: 'Mean order value',
              icon: Icons.shopping_cart,
              color: Colors.teal,
              trend: analytics.orderValueTrend,
            ),
            KPICard(
              title: 'Customer Satisfaction',
              value: '${analytics.customerSatisfaction.toStringAsFixed(1)}%',
              subtitle: 'Customer feedback score',
              icon: Icons.star,
              color: Colors.amber,
              trend: analytics.satisfactionTrend,
            ),
          ].animate(interval: const Duration(milliseconds: 100)).fadeIn().slideX(),
        );
      },
    );
  }

  _DashboardAnalytics _calculateAnalytics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    final todayInvoices = invoices.where((inv) => inv.date.isAfter(today));
    final monthInvoices = invoices.where((inv) => inv.date.isAfter(monthStart));
    final lastMonthInvoices = invoices.where((inv) =>
        inv.date.isAfter(monthStart.subtract(const Duration(days: 30))) &&
        inv.date.isBefore(monthStart));

    final uniqueCustomers = invoices
        .map((inv) => inv.customerId)
        .toSet()
        .length;

    final totalRevenue = invoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);
    final averageOrderValue = invoices.isNotEmpty ? totalRevenue / invoices.length : 0.0;

    return _DashboardAnalytics(
      todayRevenue: todayInvoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat),
      todayOrders: todayInvoices.length,
      monthlyRevenue: monthInvoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat),
      pendingOrders: invoices.where((inv) => inv.deliveryStatus == InvoiceStatus.pending).length,
      uniqueCustomers: uniqueCustomers,
      revenueTrend: _calculateTrend(todayInvoices, invoices),
      monthlyTrend: _calculateTrend(monthInvoices, lastMonthInvoices),
      customerGrowth: 5.2, // This should be calculated based on historical data
      averageOrderValue: averageOrderValue,
      orderValueTrend: 2.8, // Example trend
      customerSatisfaction: 92.5, // Example satisfaction score
      satisfactionTrend: 1.5, // Example trend
    );
  }

  double _calculateTrend(Iterable<Invoice> current, Iterable<Invoice> previous) {
    final currentTotal = current.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);
    final previousTotal = previous.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);

    if (previousTotal == 0) return 0;
    return ((currentTotal - previousTotal) / previousTotal) * 100;
  }
}

class _DashboardAnalytics {
  final double todayRevenue;
  final int todayOrders;
  final double monthlyRevenue;
  final int pendingOrders;
  final int uniqueCustomers;
  final double revenueTrend;
  final double monthlyTrend;
  final double customerGrowth;
  final double averageOrderValue;
  final double orderValueTrend;
  final double customerSatisfaction;
  final double satisfactionTrend;

  _DashboardAnalytics({
    required this.todayRevenue,
    required this.todayOrders,
    required this.monthlyRevenue,
    required this.pendingOrders,
    required this.uniqueCustomers,
    required this.revenueTrend,
    required this.monthlyTrend,
    required this.customerGrowth,
    required this.averageOrderValue,
    required this.orderValueTrend,
    required this.customerSatisfaction,
    required this.satisfactionTrend,
  });
}
