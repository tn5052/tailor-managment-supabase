import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/measurement.dart';
import '../../models/complaint.dart';
import '../../utils/number_formatter.dart';
import '../invoice/invoice_details_dialog.dart';
import '../complaint/complaint_detail_dialog.dart';

// 1. Helper Components
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const GradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AnimatedCount extends StatelessWidget {
  final double count;
  final String? prefix;
  final String? suffix;
  final TextStyle? style;
  final Duration duration;
  final int fractionDigits;

  const AnimatedCount({
    super.key,
    required this.count,
    this.prefix,
    this.suffix,
    this.style,
    this.duration = const Duration(milliseconds: 750),
    this.fractionDigits = 2,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: count),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Text(
          '${prefix ?? ''}${value.toStringAsFixed(fractionDigits)}${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? 
        (theme.brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[700]!);
    final highlightColor = widget.highlightColor ?? 
        (theme.brightness == Brightness.light ? Colors.grey[100]! : Colors.grey[600]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [baseColor, highlightColor, baseColor],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(_animation.value - 1, -0.5),
            end: Alignment(_animation.value + 1, 0.5),
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// Step 2: Add helper classes for visualization
class _ChartData {
  final DateTime date;
  final double value;
  _ChartData(this.date, this.value);
}

class CustomerFullReportScreen extends StatefulWidget {
  final Customer customer;
  final List<Measurement> measurements;
  final List<Invoice> invoices;
  final List<Complaint> complaints;

  const CustomerFullReportScreen({
    super.key,
    required this.customer,
    required this.measurements,
    required this.invoices,
    required this.complaints,
  });

  @override
  State<CustomerFullReportScreen> createState() => _CustomerFullReportScreenState();
}

class _CustomerFullReportScreenState extends State<CustomerFullReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.colorScheme.primary,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: AnimatedOpacity(
                opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  widget.customer.name,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              background: _buildHeader(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 3, color: theme.colorScheme.primary),
                    insets: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Orders'),
                    Tab(text: 'Measurements'),
                    Tab(text: 'Financial'),
                    Tab(text: 'Support'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildOrdersTab(),
            _buildMeasurementsTab(),
            _buildFinancialTab(),  // Changed from _buildSupportTab()
            _buildSupportTab(),    // Added as fifth tab
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = widget.invoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);
    final lastOrder = widget.invoices.isNotEmpty 
        ? widget.invoices.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
        : null;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button and basic info area
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Identity section
                  Padding(
                    padding: const EdgeInsets.only(left: 58), // Aligned with name below back button
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customer.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Bill #${widget.customer.billNumber}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Stats area with gradient overlay
            Container(
              margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Customer since info
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Customer since ${timeago.format(widget.customer.createdAt)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Spent',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedCount(
                              count: totalSpent,
                              prefix: 'AED ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      if (lastOrder != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Last Order',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      timeago.format(lastOrder.date),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);
    final padding = MediaQuery.of(context).size.width * 0.04;
    
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      children: [
        // Financial Overview Section
        _buildSectionHeader('Financial Overview', Icons.monetization_on),
        const SizedBox(height: 16),
        _buildFinancialMetrics(),
        const SizedBox(height: 24),

        // Order Status
        _buildSectionHeader('Order Status', Icons.local_shipping),
        const SizedBox(height: 16),
        _buildOrderStatusGrid(),
        const SizedBox(height: 24),

        // Recent Activity Timeline
        _buildSectionHeader('Recent Activity', Icons.history),
        const SizedBox(height: 16),
        _buildActivityTimeline(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialMetrics() {
    final totalSpent = widget.invoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);
    final totalBalance = widget.invoices.fold(0.0, (sum, inv) => sum + inv.balance);
    final avgOrderValue = widget.invoices.isNotEmpty ? totalSpent / widget.invoices.length : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                NumberFormatter.formatCurrency(totalSpent),
                Icons.trending_up,
                Colors.green,
                subtitle: 'Lifetime value',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Outstanding',
                NumberFormatter.formatCurrency(totalBalance),
                Icons.account_balance_wallet,
                Colors.orange,
                subtitle: 'Total balance',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Average Order',
                NumberFormatter.formatCurrency(avgOrderValue),
                Icons.analytics,
                Colors.blue,
                subtitle: 'Per invoice',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Orders',
                widget.invoices.length.toString(),
                Icons.receipt_long,
                Colors.purple,
                subtitle: 'All time',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderStatusGrid() {
    final pendingDeliveries = widget.invoices.where(
      (inv) => !inv.isDelivered && inv.deliveryDate.isAfter(DateTime.now())
    ).length;
    final overdueDeliveries = widget.invoices.where(
      (inv) => !inv.isDelivered && inv.deliveryDate.isBefore(DateTime.now())
    ).length;
    final completedDeliveries = widget.invoices.where((inv) => inv.isDelivered).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            'Pending',
            pendingDeliveries.toString(),
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Overdue',
            overdueDeliveries.toString(),
            Icons.warning_amber,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Completed',
            completedDeliveries.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    // Combine and sort all activities
    final activities = [
      ...widget.invoices.map((e) => (
        'Invoice #${e.invoiceNumber}',
        e.date,
        'Amount: ${NumberFormatter.formatCurrency(e.amountIncludingVat)}',
        Icons.receipt_long,
        Colors.blue,
        () => _showInvoiceDetails(context, e),
      )),
      ...widget.measurements.map((e) => (
        'New Measurement',
        e.date,
        'Style: ${e.style}',
        Icons.straighten,
        Colors.purple,
        () => _showMeasurementDetails(context, e),
      )),
      ...widget.complaints.map((e) => (
        e.title,
        e.createdAt,
        'Status: ${e.status}',
        Icons.warning_amber,
        Colors.red,
        () => _showComplaintDetails(context, e),
      )),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            activities.length.clamp(0, 5),
            (index) => _buildTimelineItem(
              title: activities[index].$1,
              date: activities[index].$2,
              subtitle: activities[index].$3,
              icon: activities[index].$4,
              color: activities[index].$5,
              onTap: activities[index].$6,
              isLast: index == activities.length.clamp(0, 5) - 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required DateTime date,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: Colors.grey.withOpacity(0.2),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    final theme = Theme.of(context);
    
    if (widget.invoices.isEmpty) {
      return _buildEmptyState('No orders found for this customer', Icons.receipt_long);
    }
    
    // Sort invoices by date, newest first
    final sortedInvoices = [...widget.invoices]..sort((a, b) => b.date.compareTo(a.date));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedInvoices.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Order History',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        }
        
        final invoice = sortedInvoices[index - 1];
        return _buildOrderCard(invoice);
      },
    );
  }
  
  Widget _buildMeasurementsTab() {
    final theme = Theme.of(context);
    
    if (widget.measurements.isEmpty) {
      return _buildEmptyState('No measurements found for this customer', Icons.straighten);
    }
    
    // Sort measurements by date, newest first
    final sortedMeasurements = [...widget.measurements]..sort((a, b) => b.date.compareTo(a.date));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMeasurements.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Measurement History',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        }
        
        final measurement = sortedMeasurements[index - 1];
        return _buildMeasurementCard(measurement);
      },
    );
  }
  
  Widget _buildSupportTab() {
    final theme = Theme.of(context);
    
    if (widget.complaints.isEmpty) {
      return _buildEmptyState('No support history found for this customer', Icons.support_agent);
    }
    
    // Sort complaints by date, newest first
    final sortedComplaints = [...widget.complaints]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedComplaints.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Support History',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        }
        
        final complaint = sortedComplaints[index - 1];
        return _buildComplaintCard(complaint);
      },
    );
  }
  
  Widget _buildEmptyState(String message, IconData icon) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Invoice invoice) {
    final theme = Theme.of(context);
    
    Color getStatusColor(String status) {
      switch (status) {
        case 'pending':
          return Colors.orange;
        case 'delivered':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice #${invoice.invoiceNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(invoice.deliveryStatus.toString()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    invoice.deliveryStatus.toString(),
                    style: TextStyle(
                      color: getStatusColor(invoice.deliveryStatus.toString()),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Amount', NumberFormatter.formatCurrency(invoice.amountIncludingVat)),
                ),
                Expanded(
                  child: _buildInfoRow('Date', DateFormat('MMM d, yyyy').format(invoice.date)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Delivery Date', DateFormat('MMM d, yyyy').format(invoice.deliveryDate)),
                ),
                Expanded(
                  child: _buildInfoRow('Payment', invoice.paymentStatus.toString()),
                ),
              ],
            ),
            if (invoice.balance > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Balance due: ${NumberFormatter.formatCurrency(invoice.balance)}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(Measurement measurement) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.straighten, color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        measurement.style,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(measurement.date),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Key Measurements',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildMeasurementBadge('Length', '${measurement.lengthArabi}'),
                _buildMeasurementBadge('Chest', '${measurement.chest}'),
                _buildMeasurementBadge('Width', '${measurement.width}'),
                _buildMeasurementBadge('Sleeve', '${measurement.sleeve}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Design Type', measurement.designType),
                ),
                Expanded(
                  child: _buildInfoRow('Fabric', measurement.fabricName),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMeasurementBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.purple,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final theme = Theme.of(context);
    
    Color getStatusColor(String status) {
      switch (status) {
        case 'pending':
          return Colors.orange;
        case 'resolved':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }
    
    Color getPriorityColor(String priority) {
      switch (priority) {
        case 'high':
          return Colors.red;
        case 'medium':
          return Colors.orange;
        case 'low':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    complaint.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(complaint.status.toString()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    complaint.status.toString(),
                    style: TextStyle(
                      color: getStatusColor(complaint.status.toString()),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: getPriorityColor(complaint.priority.toString()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Priority: ${complaint.priority.toString()}',
                    style: TextStyle(
                      color: getPriorityColor(complaint.priority.toString()),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy').format(complaint.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Description:',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              complaint.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (complaint.refundAmount != null && complaint.refundAmount! > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.money_off, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Refund: ${NumberFormatter.formatCurrency(complaint.refundAmount!)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLastActivity() {
    List<DateTime> allDates = [];
    
    // Add invoice dates
    for (final invoice in widget.invoices) {
      allDates.add(invoice.date);
    }
    
    // Add measurement dates
    for (final measurement in widget.measurements) {
      allDates.add(measurement.date);
    }
    
    // Add complaint dates
    for (final complaint in widget.complaints) {
      allDates.add(complaint.createdAt);
    }
    
    if (allDates.isEmpty) {
      return 'No activity';
    }
    
    // Find the most recent date
    allDates.sort((a, b) => b.compareTo(a));
    final mostRecentDate = allDates.first;
    
    // Format the date
    return DateFormat('MMM d, yyyy').format(mostRecentDate);
  }

  void _showInvoiceDetails(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => InvoiceDetailsDialog(
        invoice: invoice,
      ),
    );
  }

  void _showMeasurementDetails(BuildContext context, Measurement measurement) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Measurement Details',
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              // Basic measurement info
              ListTile(
                title: Text('Style'),
                subtitle: Text(measurement.style),
              ),
              ListTile(
                title: Text('Design Type'),
                subtitle: Text(measurement.designType),
              ),
              // Measurements grid
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                children: [
                  _buildMeasurementGridItem('Length', measurement.lengthArabi.toString()),
                  _buildMeasurementGridItem('Chest', measurement.chest.toString()),
                  _buildMeasurementGridItem('Width', measurement.width.toString()),
                  _buildMeasurementGridItem('Sleeve', measurement.sleeve.toString()),
                  _buildMeasurementGridItem('Collar', measurement.collar.toString()),
                  _buildMeasurementGridItem('Shoulder', measurement.shoulder.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementGridItem(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplaintDetails(BuildContext context, Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => ComplaintDetailDialog(
        complaint: complaint,
      ),
    );
  }

  Widget _buildFinancialTab() {
    final theme = Theme.of(context);
    final totalSpent = widget.invoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);
    final totalAdvance = widget.invoices.fold(0.0, (sum, inv) => sum + inv.advance);
    final totalBalance = widget.invoices.fold(0.0, (sum, inv) => sum + inv.balance);
    final totalRefunds = widget.invoices.fold(0.0, (sum, inv) => sum + (inv.refundAmount ?? 0.0));
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Financial Overview',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Financial Summary Cards
        Column(
          children: [
            _buildFinancialCard(
              'Total Spent',
              NumberFormatter.formatCurrency(totalSpent),
              Icons.monetization_on,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildFinancialCard(
              'Total Advanced',
              NumberFormatter.formatCurrency(totalAdvance),
              Icons.payments,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildFinancialCard(
              'Outstanding Balance',
              NumberFormatter.formatCurrency(totalBalance),
              Icons.account_balance_wallet,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildFinancialCard(
              'Total Refunds',
              NumberFormatter.formatCurrency(totalRefunds),
              Icons.money_off,
              Colors.red,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Payment History Section
        Text(
          'Payment History',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Payment History Cards
        ...widget.invoices.map((invoice) => _buildPaymentHistoryCard(invoice)).toList(),
      ],
    );
  }

  Widget _buildFinancialCard(String title, String amount, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard(Invoice invoice) {
    final theme = Theme.of(context);
    Color statusColor;
    
    switch (invoice.paymentStatus) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice #${invoice.invoiceNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    invoice.paymentStatus.toString(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPaymentDetail('Total', invoice.amountIncludingVat),
                const SizedBox(width: 24),
                _buildPaymentDetail('Advance', invoice.advance),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPaymentDetail('Balance', invoice.balance),
                const SizedBox(width: 24),
                Text(
                  DateFormat('MMM d, yyyy').format(invoice.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetail(String label, double amount) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          NumberFormatter.formatCurrency(amount),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
