import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/measurement.dart';
import '../../models/complaint.dart';
import '../../utils/number_formatter.dart';

class CustomerFullReportDialog extends StatelessWidget {
  final Customer customer;
  final List<Measurement> measurements;
  final List<Invoice> invoices;
  final List<Complaint> complaints;

  const CustomerFullReportDialog({
    required this.customer,
    required this.measurements,
    required this.invoices,
    required this.complaints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width * 0.85,
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _ReportHeader(customer: customer),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel - Summary and Stats
                Expanded(
                  flex: 3,
                  child: _CustomerSummaryPanel(
                    customer: customer,
                    measurements: measurements,
                    invoices: invoices,
                    complaints: complaints,
                  ),
                ),
                // Right panel - Timeline
                Expanded(
                  flex: 4,
                  child: _CustomerTimelinePanel(
                    measurements: measurements,
                    invoices: invoices,
                    complaints: complaints,
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

class CustomerFullReportScreen extends StatelessWidget {
  final Customer customer;
  final List<Measurement> measurements;
  final List<Invoice> invoices;
  final List<Complaint> complaints;

  const CustomerFullReportScreen({
    required this.customer,
    required this.measurements,
    required this.invoices,
    required this.complaints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Report'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Header
          _ReportHeader(customer: customer, isMobile: true),
          
          // Summary Panel
          _CustomerSummaryPanel(
            customer: customer,
            measurements: measurements,
            invoices: invoices,
            complaints: complaints,
            isMobile: true,
          ),
          
          // Timeline Panel - listed directly in ListView
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Activity Timeline',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fade(duration: 400.ms).slideX(begin: 0.2, end: 0),
          ),
          
          // Activity summary chart
          if (_hasEvents())
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildTimelineChart(),
            ),
            
          // Individual timeline items
          if (_hasEvents())
            ..._buildTimelineItems(context)
          else
            _buildEmptyTimeline(context),
            
          // Bottom padding
          const SizedBox(height: 40)
        ],
      ),
    );
  }
  
  bool _hasEvents() {
    return measurements.isNotEmpty || invoices.isNotEmpty || complaints.isNotEmpty;
  }
  
  Widget _buildTimelineChart() {
    // Create instance of _CustomerTimelinePanel just to use its chart building method
    final timelinePanel = _CustomerTimelinePanel(
      measurements: measurements,
      invoices: invoices,
      complaints: complaints,
      isMobile: true,
    );
    
    return timelinePanel._buildActivitySummaryChart(_createTimelineEvents())
        .animate()
        .fade(duration: 800.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }
  
  List<_TimelineEvent> _createTimelineEvents() {
    final events = [
      ...measurements.map((m) => _TimelineEvent(
            date: m.date,
            title: 'New Measurement',
            subtitle: 'Style: ${m.style}',
            icon: Icons.straighten,
            color: Colors.purple,
          )),
      ...invoices.map((i) => _TimelineEvent(
            date: i.date,
            title: 'Invoice #${i.invoiceNumber}',
            subtitle: 'Amount: ${NumberFormatter.formatCurrency(i.amountIncludingVat)}',
            icon: Icons.receipt,
            color: Colors.blue,
          )),
      ...complaints.map((c) => _TimelineEvent(
            date: c.createdAt,
            title: c.title,
            subtitle: 'Status: ${c.status}',
            icon: Icons.warning,
            color: Colors.red,
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));
    
    return events;
  }
  
  List<Widget> _buildTimelineItems(BuildContext context) {
    final theme = Theme.of(context);
    final events = _createTimelineEvents();
    
    return events.asMap().entries.map((entry) {
      final event = entry.value;
      final isLast = entry.key == events.length - 1;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _TimelineItem(
          event: event,
          isLast: isLast,
          theme: theme,
        ).animate(delay: (100 * entry.key).ms)
          .fade(duration: 400.ms)
          .slideX(begin: 0.1, end: 0),
      );
    }).toList();
  }
  
  Widget _buildEmptyTimeline(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 200,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No activity history available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  final Customer customer;
  final bool isMobile;

  const _ReportHeader({
    required this.customer,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: isMobile
            ? null
            : const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 24 : 32,
            backgroundColor: Colors.white24,
            child: Text(
              customer.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: isMobile ? 20 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created ${timeago.format(customer.createdAt)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

class _CustomerSummaryPanel extends StatelessWidget {
  final Customer customer;
  final List<Measurement> measurements;
  final List<Invoice> invoices;
  final List<Complaint> complaints;
  final bool isMobile;

  const _CustomerSummaryPanel({
    required this.customer,
    required this.measurements,
    required this.invoices,
    required this.complaints,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = invoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);
    final totalBalance = invoices.fold(0.0, (sum, inv) => sum + inv.balance);
    final pendingOrders = invoices.where((inv) => !inv.isDelivered).length;
    final totalOrders = invoices.length;
    final completedOrders = totalOrders - pendingOrders;
    final avgOrderValue = totalOrders > 0 ? totalSpent / totalOrders : 0.0;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        border: isMobile
            ? Border(bottom: BorderSide(color: theme.dividerColor))
            : Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fade(duration: 400.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            
            // Key Stats Grid
            _buildStatsGrid(theme).animate().fade(duration: 500.ms, delay: 100.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
            
            const SizedBox(height: 24),

            // Performance Charts
            _buildPerformanceCharts(context),
            
            const SizedBox(height: 24),
            
            // Financial Summary
            _buildSection(
              theme,
              'Financial Summary',
              [
                _buildStat('Total Spent', NumberFormatter.formatCurrency(totalSpent)),
                _buildStat('Outstanding Balance', NumberFormatter.formatCurrency(totalBalance)),
                _buildStat('Average Order Value', NumberFormatter.formatCurrency(avgOrderValue)),
              ],
            ).animate().fade(duration: 600.ms, delay: 300.ms),
            
            const SizedBox(height: 24),
            
            // Order Statistics
            _buildSection(
              theme,
              'Order Statistics',
              [
                _buildStat('Total Orders', '$totalOrders'),
                _buildStat('Completed Orders', '$completedOrders'),
                _buildStat('Pending Orders', '$pendingOrders'),
                _buildStat('Total Measurements', '${measurements.length}'),
                _buildStat('Complaints Filed', '${complaints.length}'),
              ],
            ).animate().fade(duration: 600.ms, delay: 400.ms),
            
            const SizedBox(height: 24),
            
            // Contact Information
            _buildSection(
              theme,
              'Contact Information',
              [
                _buildStat('Bill Number', customer.billNumber),
                _buildStat('Phone', customer.phone),
                if (customer.whatsapp.isNotEmpty)
                  _buildStat('WhatsApp', customer.whatsapp),
                _buildStat('Address', customer.address),
              ],
            ).animate().fade(duration: 600.ms, delay: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCharts(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Performance',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const Divider(height: 24),
        
        // Order History Chart
        _buildOrderHistoryChart()
            .animate()
            .fade(duration: 800.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0),

        const SizedBox(height: 24),

        // Spending Distribution Pie Chart
        _buildSpendingPieChart(context)
            .animate()
            .fade(duration: 800.ms, delay: 300.ms)
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
      ],
    );
  }

  Widget _buildOrderHistoryChart() {
    // Group invoices by month
    final groupedData = <DateTime, double>{};
    
    if (invoices.isNotEmpty) {
      // Get range of dates (last 6 months)
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      
      // Create entries for each month in the range
      for (int i = 0; i < 6; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        if (month.isAfter(sixMonthsAgo) || month.isAtSameMomentAs(sixMonthsAgo)) {
          groupedData[month] = 0;
        }
      }
      
      // Fill in actual data
      for (final invoice in invoices) {
        final invoiceMonth = DateTime(invoice.date.year, invoice.date.month, 1);
        if (invoiceMonth.isAfter(sixMonthsAgo) || invoiceMonth.isAtSameMomentAs(sixMonthsAgo)) {
          groupedData[invoiceMonth] = (groupedData[invoiceMonth] ?? 0) + invoice.amountIncludingVat;
        }
      }
    }

    // Convert to sorted list for chart
    final sortedEntries = groupedData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Spending (Last 6 Months)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sortedEntries.isEmpty 
                ? const Center(child: Text('No order history available'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text('');
                              return Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= sortedEntries.length) {
                                return const Text('');
                              }
                              final date = sortedEntries[index].key;
                              return Text(
                                '${_getMonthAbbreviation(date.month)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      minX: 0,
                      maxX: sortedEntries.length - 1.0,
                      minY: 0,
                      maxY: sortedEntries.isEmpty ? 1000 : sortedEntries.map((e) => e.value).reduce(math.max) * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            sortedEntries.length,
                            (i) => FlSpot(i.toDouble(), sortedEntries[i].value),
                          ),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingPieChart(BuildContext context) {
    final theme = Theme.of(context);
    
    // Analyze invoice data for pie chart
    double totalAmount = 0;
    double paidAmount = 0;
    double pendingAmount = 0;
    
    for (final invoice in invoices) {
      totalAmount += invoice.amountIncludingVat;
      if (invoice.paymentStatus == PaymentStatus.paid) {
        paidAmount += invoice.amountIncludingVat;
      } else {
        pendingAmount += invoice.amountIncludingVat;
      }
    }
    
    final sections = <PieChartSectionData>[];
    
    if (totalAmount > 0) {
      // Add sections only if there's data
      if (paidAmount > 0) {
        sections.add(PieChartSectionData(
          value: paidAmount,
          title: '${(paidAmount / totalAmount * 100).toStringAsFixed(0)}%',
          color: Colors.green,
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ));
      }
      
      if (pendingAmount > 0) {
        sections.add(PieChartSectionData(
          value: pendingAmount,
          title: '${(pendingAmount / totalAmount * 100).toStringAsFixed(0)}%',
          color: Colors.orange,
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ));
      }
    } else {
      // Add placeholder if no data
      sections.add(PieChartSectionData(
        value: 1,
        title: 'No data',
        color: Colors.grey[300]!,
        radius: 60,
        titleStyle: TextStyle(
          color: Colors.grey[600]!,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ));
    }
    
    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Payment Status Distribution',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 0,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      'Paid', 
                      NumberFormatter.formatCurrency(paidAmount), 
                      Colors.green
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'Pending', 
                      NumberFormatter.formatCurrency(pendingAmount), 
                      Colors.orange
                    ),
                    if (totalAmount > 0) ...[
                      const SizedBox(height: 16),
                      _buildLegendItem(
                        'Total', 
                        NumberFormatter.formatCurrency(totalAmount), 
                        Colors.blue
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildStatsGrid(ThemeData theme) {
    final stats = [
      _StatItem(
        label: 'Orders',
        value: '${invoices.length}',
        icon: Icons.receipt,
        color: Colors.blue,
      ),
      _StatItem(
        label: 'Measurements',
        value: '${measurements.length}',
        icon: Icons.straighten,
        color: Colors.purple,
      ),
      _StatItem(
        label: 'Pending',
        value: '${invoices.where((inv) => !inv.isDelivered).length}',
        icon: Icons.pending,
        color: Colors.orange,
      ),
      _StatItem(
        label: 'Complaints',
        value: '${complaints.length}',
        icon: Icons.warning,
        color: Colors.red,
      ),
    ];

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.5 : 2.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: stats.map((stat) => _buildStatCard(theme, stat)).toList(),
    );
  }

  Widget _buildStatCard(ThemeData theme, _StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stat.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: stat.color),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: stat.color,
            ),
          ),
          Text(
            stat.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: stat.color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const Divider(),
        ...children,
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CustomerTimelinePanel extends StatelessWidget {
  final List<Measurement> measurements;
  final List<Invoice> invoices;
  final List<Complaint> complaints;
  final bool isMobile;

  const _CustomerTimelinePanel({
    required this.measurements,
    required this.invoices,
    required this.complaints,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Combine all events and sort by date
    final events = [
      ...measurements.map((m) => _TimelineEvent(
            date: m.date,
            title: 'New Measurement',
            subtitle: 'Style: ${m.style}',
            icon: Icons.straighten,
            color: Colors.purple,
          )),
      ...invoices.map((i) => _TimelineEvent(
            date: i.date,
            title: 'Invoice #${i.invoiceNumber}',
            subtitle: 'Amount: ${NumberFormatter.formatCurrency(i.amountIncludingVat)}',
            icon: Icons.receipt,
            color: Colors.blue,
          )),
      ...complaints.map((c) => _TimelineEvent(
            date: c.createdAt,
            title: c.title,
            subtitle: 'Status: ${c.status}',
            icon: Icons.warning,
            color: Colors.red,
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));

    // For mobile, we can't use a Column with Expanded inside a sliver
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Activity Timeline',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fade(duration: 400.ms).slideX(begin: 0.2, end: 0),
            
            const SizedBox(height: 16),
            
            // Only add chart if there are events
            if (events.isNotEmpty) ...[
              _buildActivitySummaryChart(events)
                .animate()
                .fade(duration: 800.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 24),
              
              // Timeline events - individually listed
              ...events.asMap().entries.map((entry) {
                final event = entry.value;
                final isLast = entry.key == events.length - 1;
                return _TimelineItem(
                  event: event,
                  isLast: isLast,
                  theme: theme,
                ).animate(delay: (100 * entry.key).ms)
                  .fade(duration: 400.ms)
                  .slideX(begin: 0.1, end: 0);
              }),
            ],
            
            // Show empty state if no events
            if (events.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timeline_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No activity history available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    
    // Desktop layout with Column and Expanded ListView
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Timeline',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fade(duration: 400.ms).slideX(begin: 0.2, end: 0),

          const SizedBox(height: 16),
          
          // Only add chart if there are events
          if (events.isNotEmpty) ...[
            _buildActivitySummaryChart(events)
                .animate()
                .fade(duration: 800.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
          ],
          
          // For desktop we can use Expanded
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timeline_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No activity history available',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final isLast = index == events.length - 1;
                      return _TimelineItem(
                        event: event,
                        isLast: isLast,
                        theme: theme,
                      ).animate(delay: (100 * index).ms)
                        .fade(duration: 400.ms)
                        .slideX(begin: 0.1, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummaryChart(List<_TimelineEvent> events) {
    // Group events by type and count
    int measurementsCount = 0;
    int invoicesCount = 0;
    int complaintsCount = 0;
    
    for (final event in events) {
      if (event.icon == Icons.straighten) {
        measurementsCount++;
      } else if (event.icon == Icons.receipt) {
        invoicesCount++;
      } else if (event.icon == Icons.warning) {
        complaintsCount++;
      }
    }
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Distribution',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = ['Measurements', 'Invoices', 'Complaints'];
                        if (value < 0 || value > 2) return const Text('');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            titles[value.toInt()],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: measurementsCount.toDouble(),
                        color: Colors.purple,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: invoicesCount.toDouble(),
                        color: Colors.blue,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: complaintsCount.toDouble(),
                        color: Colors.red,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEvent {
  final DateTime date;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TimelineEvent({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _TimelineItem extends StatelessWidget {
  final _TimelineEvent event;
  final bool isLast;
  final ThemeData theme;

  const _TimelineItem({
    required this.event,
    required this.isLast,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: event.color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.dividerColor,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(event.icon, size: 16, color: event.color),
                      const SizedBox(width: 8),
                      Text(
                        event.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.subtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(event.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}