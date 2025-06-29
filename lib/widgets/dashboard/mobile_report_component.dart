import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/measurement.dart';
import '../../models/complaint.dart';
import '../../utils/number_formatter.dart';
import '../complaint/complaint_detail_dialog.dart';
import '../measurement/desktop/measurement_detail_dialog.dart'; // Add this import for the measurement detail dialog

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

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
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
    final baseColor =
        widget.baseColor ??
        (theme.brightness == Brightness.light
            ? Colors.grey[300]!
            : Colors.grey[700]!);
    final highlightColor =
        widget.highlightColor ??
        (theme.brightness == Brightness.light
            ? Colors.grey[100]!
            : Colors.grey[600]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback:
              (bounds) => LinearGradient(
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
  State<CustomerFullReportScreen> createState() =>
      _CustomerFullReportScreenState();
}

class _CustomerFullReportScreenState extends State<CustomerFullReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
    ); // Change from 5 to 4 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurface
                          .withOpacity(0.7),
                      indicator: UnderlineTabIndicator(
                        borderSide: BorderSide(
                          width: 3,
                          color: theme.colorScheme.primary,
                        ),
                        insets: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Financial & Orders'), // Updated tab name
                        Tab(text: 'Measurements'),
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
            _buildFinancialTab(), // Now contains both financial and orders
            _buildMeasurementsTab(),
            _buildSupportTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + inv.amountIncludingVat,
    );
    final lastOrder =
        widget.invoices.isNotEmpty
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
                    padding: const EdgeInsets.only(
                      left: 58,
                    ), // Aligned with name below back button
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 16,
                      ),
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
    final totalSpent = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + inv.amountIncludingVat,
    );
    final totalBalance = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + inv.balance,
    );
    final avgOrderValue =
        widget.invoices.isNotEmpty ? totalSpent / widget.invoices.length : 0.0;

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
                style: TextStyle(color: color.withOpacity(0.8), fontSize: 13),
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
    final pendingDeliveries =
        widget.invoices
            .where(
              (inv) =>
                  !inv.isDelivered && inv.deliveryDate.isAfter(DateTime.now()),
            )
            .length;
    final overdueDeliveries =
        widget.invoices
            .where(
              (inv) =>
                  !inv.isDelivered && inv.deliveryDate.isBefore(DateTime.now()),
            )
            .length;
    final completedDeliveries =
        widget.invoices.where((inv) => inv.isDelivered).length;

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

  Widget _buildStatusCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    // Combine and sort all activities
    final activities = [
      ...widget.invoices.map(
        (e) => (
          'Invoice #${e.invoiceNumber}',
          e.date,
          'Amount: ${NumberFormatter.formatCurrency(e.amountIncludingVat)}',
          Icons.receipt_long,
          Colors.blue,
          () => _showInvoiceDetails(context, e),
        ),
      ),
      ...widget.measurements.map(
        (e) => (
          'New Measurement',
          e.date,
          'Style: ${e.style}',
          Icons.straighten,
          Colors.purple,
          () => _showMeasurementDetails(context, e),
        ),
      ),
      ...widget.complaints.map(
        (e) => (
          e.title,
          e.createdAt,
          'Status: ${e.status}',
          Icons.warning_amber,
          Colors.red,
          () => _showComplaintDetails(context, e),
        ),
      ),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    final theme = Theme.of(context);

    if (widget.measurements.isEmpty) {
      return _buildEmptyState(
        'No measurements found for this customer',
        Icons.straighten,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header section with action button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Measurements',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _showMeasurementsList(context),
              icon: const Icon(Icons.list),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent measurements preview
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: widget.measurements.length.clamp(0, 4),
          itemBuilder: (context, index) {
            final measurement = widget.measurements[index];
            return _buildMeasurementPreviewCard(measurement);
          },
        ),

        if (widget.measurements.length > 4) ...[
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () => _showMeasurementsList(context),
              icon: const Icon(Icons.visibility),
              label: Text(
                'View All ${widget.measurements.length} Measurements',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMeasurementPreviewCard(Measurement measurement) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.purple.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _showMeasurementDetails(context, measurement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.straighten,
                      color: Colors.purple,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      measurement.style,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM d, yyyy').format(measurement.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chest: ${measurement.chest}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Length: ${measurement.lengthArabi}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMeasurementsList(BuildContext context) {
    final theme = Theme.of(context);
    final sortedMeasurements = [...widget.measurements]
      ..sort((a, b) => b.date.compareTo(a.date));

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        child: const Icon(
                          Icons.straighten,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Measurements',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.measurements.length} measurements found',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: sortedMeasurements.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final measurement = sortedMeasurements[index];
                        return _buildMeasurementListItem(measurement);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMeasurementListItem(Measurement measurement) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close the list dialog
          _showMeasurementDetails(context, measurement);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.straighten, color: Colors.purple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      measurement.style,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Design: ${measurement.designType}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(measurement.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, color: Colors.purple, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'View',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildSupportTab() {
    final theme = Theme.of(context);

    if (widget.complaints.isEmpty) {
      return _buildEmptyState(
        'No support history found for this customer',
        Icons.support_agent,
      );
    }

    // Sort complaints by date, newest first
    final sortedComplaints = [...widget.complaints]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedComplaints.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Support History',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(
                      invoice.deliveryStatus.toString(),
                    ).withOpacity(0.1),
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
                  child: _buildInfoRow(
                    'Amount',
                    NumberFormatter.formatCurrency(invoice.amountIncludingVat),
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'Date',
                    DateFormat('MMM d, yyyy').format(invoice.date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'Delivery Date',
                    DateFormat('MMM d, yyyy').format(invoice.deliveryDate),
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'Payment',
                    invoice.paymentStatus.toString(),
                  ),
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
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 20,
                    ),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(
                      complaint.status.toString(),
                    ).withOpacity(0.1),
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
                    color: getPriorityColor(
                      complaint.priority.toString(),
                    ).withOpacity(0.1),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
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
            if (complaint.refundAmount != null &&
                complaint.refundAmount! > 0) ...[
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


  void _showInvoiceDetails(BuildContext context, Invoice invoice) {

  }

  void _showMeasurementDetails(BuildContext context, Measurement measurement) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    // If there's only one measurement or we're on a small device, show the detail dialog directly
    if (widget.measurements.length <= 1 ||
        MediaQuery.of(context).size.width < 360) {
      DetailDialog.show(
        context,
        measurement: measurement,
        customerId: widget.customer.id,
      );
      return;
    }

    // Otherwise, show a custom dialog with a list of all measurements
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width:
                  isTablet
                      ? MediaQuery.of(context).size.width * 0.8
                      : MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.purple.withOpacity(0.2),
                        child: const Icon(
                          Icons.straighten,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Measurements',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.measurements.length} measurements found',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  Expanded(child: _buildMeasurementsList(context)),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMeasurementsList(BuildContext context) {
    Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    // Sort measurements by date (newest first)
    final sortedMeasurements = [...widget.measurements]
      ..sort((a, b) => b.date.compareTo(a.date));

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isTablet ? 1.2 : 0.88,
      ),
      itemCount: sortedMeasurements.length,
      itemBuilder: (context, index) {
        final measurement = sortedMeasurements[index];
        return _buildMeasurementGridCard(context, measurement);
      },
    );
  }

  Widget _buildMeasurementGridCard(
    BuildContext context,
    Measurement measurement,
  ) {
    final theme = Theme.of(context);

    // Format the date nicely
    final formattedDate = DateFormat('MMM d, yyyy').format(measurement.date);

    // Calculate which measurements to highlight

    return InkWell(
      onTap: () {
        // Close the list dialog and open the detail dialog
        Navigator.pop(context);
        DetailDialog.show(
          context,
          measurement: measurement,
          customerId: widget.customer.id,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 1,
        shadowColor: Colors.purple.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.purple.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with style and date
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      measurement.style,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Key measurements
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMeasurementItemRow(
                      'Length',
                      measurement.lengthArabi.toString(),
                      highlight: measurement.style == 'Emirati',
                    ),
                    _buildMeasurementItemRow(
                      'Chest',
                      measurement.chest.toString(),
                      highlight: measurement.chest > 50,
                    ),
                    _buildMeasurementItemRow(
                      'Width',
                      measurement.width.toString(),
                    ),
                  ],
                ),
              ),

              // Button-like area at bottom
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility, color: Colors.purple, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementItemRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: highlight ? Colors.purple : null,
          ),
        ),
      ],
    );
  }

  void _showComplaintDetails(BuildContext context, Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => ComplaintDetailDialog(complaint: complaint),
    );
  }

  Widget _buildFinancialTab() {
    final theme = Theme.of(context);
    final totalSpent = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + inv.amountIncludingVat,
    );
    final totalAdvance = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + inv.advance,
    );
    final totalBalance = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + inv.balance,
    );
    final totalRefunds = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + (inv.refundAmount ?? 0.0),
    );

    // Sort invoices by date, newest first
    final sortedInvoices = [...widget.invoices]
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Financial Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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

        // Orders Section Header
        Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Order History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Show empty state if no invoices
        if (widget.invoices.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No orders found for this customer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // Orders List - Make it clickable
          ...sortedInvoices
              .map(
                (invoice) => InkWell(
                  onTap: () => _showInvoiceDetails(context, invoice),
                  borderRadius: BorderRadius.circular(12),
                  child: _buildOrderCard(invoice),
                ),
              )
              ,

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFinancialCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
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


}
