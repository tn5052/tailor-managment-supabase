import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/measurement.dart';
import '../../models/complaint.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/invoice/invoice_details_dialog.dart';
import '../../widgets/complaint/complaint_detail_dialog.dart';
import '../../widgets/measurement/detail_dialog.dart';
import 'desktop_report_component.dart';

class DesktopCustomerSearchDialog extends StatefulWidget {
  final Customer customer;
  final List<Measurement> measurements;
  final List<Invoice> invoices;
  final List<Complaint> complaints;

  const DesktopCustomerSearchDialog({
    super.key,
    required this.customer,
    required this.measurements,
    required this.invoices,
    required this.complaints,
  });

  static Future<void> show(
    BuildContext context, {
    required Customer customer,
    required List<Measurement> measurements,
    required List<Invoice> invoices,
    required List<Complaint> complaints,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder:
          (context) => DesktopCustomerSearchDialog(
            customer: customer,
            measurements: measurements,
            invoices: invoices,
            complaints: complaints,
          ),
    );
  }

  @override
  State<DesktopCustomerSearchDialog> createState() =>
      _DesktopCustomerSearchDialogState();
}

class _DesktopCustomerSearchDialogState
    extends State<DesktopCustomerSearchDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: size.width * 0.85,
        height: size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left sidebar with customer info and quick actions
            _buildSidebar(context),

            // Main content area
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Custom top navigation tabs
                  _buildTabBar(context),

                  // Content area with tab views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(context),
                        _buildMeasurementsTab(context),
                        _buildInvoicesTab(context),
                        _buildComplaintsTab(context),
                      ],
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

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + inv.amountIncludingVat,
    );
    final pendingOrders =
        widget.invoices
            .where((inv) => inv.deliveryStatus == InvoiceStatus.pending)
            .length;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha(220),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer profile header
          _buildCustomerProfile(context),

          const Divider(color: Colors.white24, height: 32),

          // Customer stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Customer Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            context,
            'Total Spent',
            NumberFormatter.formatCurrency(totalSpent),
            Icons.monetization_on,
            Colors.greenAccent,
          ),
          _buildStatItem(
            context,
            'Pending Orders',
            '$pendingOrders',
            Icons.pending_actions,
            Colors.orangeAccent,
          ),
          _buildStatItem(
            context,
            'Total Orders',
            '${widget.invoices.length}',
            Icons.receipt_long,
            Colors.blueAccent,
          ),
          _buildStatItem(
            context,
            'Measurements',
            '${widget.measurements.length}',
            Icons.straighten,
            Colors.purpleAccent,
          ),
          _buildStatItem(
            context,
            'Complaints',
            '${widget.complaints.length}',
            Icons.warning_amber,
            Colors.redAccent,
          ),

          const Spacer(),

          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildCustomerProfile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                child: Text(
                  widget.customer.name.isNotEmpty
                      ? widget.customer.name[0].toUpperCase()
                      : '',
                  style: const TextStyle(
                    fontSize: 28,
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
                      widget.customer.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Bill #${widget.customer.billNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Contact information
          _buildContactRow(context, Icons.phone, widget.customer.phone),
          if (widget.customer.whatsapp.isNotEmpty)
            _buildContactRow(
              context,
              FontAwesomeIcons.whatsapp,
              widget.customer.whatsapp,
            ),
          _buildContactRow(
            context,
            Icons.location_on,
            widget.customer.address,
            maxLines: 2,
          ),
          _buildContactRow(
            context,
            Icons.person,
            widget.customer.gender.toString().split('.').last,
          ),
          const SizedBox(height: 20),
          // Referrals and Family
          _buildReferralsAndFamily(context),
        ],
      ),
    );
  }

  Widget _buildReferralsAndFamily(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.customer.referralCount > 0 ||
            widget.customer.referredBy != null) ...[
          Text(
            'Referral Network',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.customer.referredBy != null)
            Text(
              'Referred by another customer',
              style: TextStyle(color: Colors.white70),
            ),
          if (widget.customer.referralCount > 0)
            Text(
              'Has referred ${widget.customer.referralCount} customers',
              style: TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 20),
        ],
        if (widget.customer.familyId != null) ...[
          Text(
            'Family Member',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Relationship: ${widget.customer.familyRelation ?? 'Unknown'}',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ],
    );
  }






  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Removed Edit Customer Button

          // Emphasized Full Report Button
          ElevatedButton.icon(
            onPressed: () => _showFullReport(context),
            icon: const Icon(Icons.analytics, color: Colors.white),
            label: const Text(
              'View Full Report',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _shareCustomerInfo,
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text(
              'Share Info',
              style: TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
              minimumSize: const Size(double.infinity, 52),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final tabItems = [
      (Icons.dashboard_customize, 'Overview'),
      (Icons.straighten, 'Measurements'),
      (Icons.receipt_long, 'Orders'),
      (Icons.warning_amber, 'Complaints'),
    ];

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        splashBorderRadius: BorderRadius.circular(12),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        indicatorWeight: 3,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs:
            tabItems.map((item) {
              final index = tabItems.indexOf(item);
              return Tab(
                icon: Icon(
                  item.$1,
                  color:
                      _currentIndex == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                text: item.$2,
                height: 60,
              );
            }).toList(),
      ),
    );
  }

  // Tab content builders
  Widget _buildOverviewTab(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + inv.amountIncludingVat,
    );
    final avgOrderValue =
        widget.invoices.isEmpty ? 0.0 : totalSpent / widget.invoices.length;
    final lastOrderDate =
        widget.invoices.isNotEmpty
            ? widget.invoices
                .reduce((a, b) => a.date.isAfter(b.date) ? a : b)
                .date
            : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Text(
            'Customer Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Summary of customer activity and key metrics',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),

          // KPI cards in a row
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  context,
                  title: 'Lifetime Value',
                  value: NumberFormatter.formatCurrency(totalSpent),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  context,
                  title: 'Average Order',
                  value: NumberFormatter.formatCurrency(avgOrderValue),
                  icon: Icons.analytics,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  context,
                  title: 'Pending Orders',
                  value:
                      '${widget.invoices.where((inv) => inv.deliveryStatus == InvoiceStatus.pending).length}',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  context,
                  title: 'Last Order',
                  value:
                      lastOrderDate != null
                          ? _formatDate(lastOrderDate)
                          : 'No orders',
                  icon: Icons.calendar_today,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Two-column layout for recent activity and quick actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent activity column
              Expanded(flex: 3, child: _buildRecentActivity(context)),
              const SizedBox(width: 24),
              // Quick actions column
              Expanded(flex: 2, child: _buildQuickActions(context)),
            ],
          ),

          const SizedBox(height: 24),

          // Related customers if any
          // This would show family members or referrals if available
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.measurements.isEmpty) {
      return _buildEmptyState(
        context,
        'No measurements found',
        'This customer has no measurements recorded yet.',
        Icons.straighten,
      );
    }

    // Sort measurements by date, newest first
    final sortedMeasurements = [...widget.measurements]
      ..sort((a, b) => b.date.compareTo(a.date));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Measurement History',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${sortedMeasurements.length} measurements recorded',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {}, // Add new measurement action
                  icon: const Icon(Icons.add),
                  label: const Text('Add Measurement'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.purple,
                    minimumSize: const Size(150, 46),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: sortedMeasurements.length,
            itemBuilder: (context, index) {
              final measurement = sortedMeasurements[index];
              return _buildMeasurementCard(context, measurement);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementCard(BuildContext context, Measurement measurement) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () => _showMeasurementDetails(context, measurement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      measurement.style,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
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
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDate(measurement.date),
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMeasurementRow(
                      context,
                      'Design',
                      measurement.designType,
                    ),
                    _buildMeasurementRow(
                      context,
                      'Length',
                      '${measurement.lengthArabi} (Arabi)',
                    ),
                    _buildMeasurementRow(
                      context,
                      'Chest',
                      '${measurement.chest}',
                    ),
                    _buildMeasurementRow(
                      context,
                      'Width',
                      '${measurement.width}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _showMeasurementDetails(context, measurement),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                ),
                child: const Text('View Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoicesTab(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.invoices.isEmpty) {
      return _buildEmptyState(
        context,
        'No invoices found',
        'This customer has no orders or invoices yet.',
        Icons.receipt_long,
      );
    }

    // Sort invoices by date, newest first
    final sortedInvoices = [...widget.invoices]
      ..sort((a, b) => b.date.compareTo(a.date));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order History',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${sortedInvoices.length} orders found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {}, // Add new invoice action
                  icon: const Icon(Icons.add),
                  label: const Text('Create Invoice'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.amber.shade700,
                    minimumSize: const Size(150, 46),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final invoice = sortedInvoices[index];
              return _buildInvoiceCard(context, invoice);
            }, childCount: sortedInvoices.length),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    final theme = Theme.of(context);

    // Determine status colors
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

    Color getPaymentStatusColor(String status) {
      switch (status) {
        case 'paid':
          return Colors.green;
        case 'pending':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () => _showInvoiceDetails(context, invoice),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice #${invoice.invoiceNumber}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Created: ${_formatDate(invoice.date)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    NumberFormatter.formatCurrency(invoice.amountIncludingVat),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Status',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: getStatusColor(
                                  invoice.deliveryStatus.toString(),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              invoice.deliveryStatus.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: getStatusColor(
                                  invoice.deliveryStatus.toString(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Status',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: getPaymentStatusColor(
                                  invoice.paymentStatus.toString(),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              invoice.paymentStatus.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: getPaymentStatusColor(
                                  invoice.paymentStatus.toString(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Date',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(invoice.deliveryDate),
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showInvoiceDetails(context, invoice),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 36),
                    ),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintsTab(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.complaints.isEmpty) {
      return _buildEmptyState(
        context,
        'No complaints found',
        'This customer has not filed any complaints yet.',
        Icons.warning_amber,
      );
    }

    // Sort complaints by date, newest first
    final sortedComplaints = [...widget.complaints]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complaint History',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${sortedComplaints.length} complaints found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {}, // Add new complaint action
                  icon: const Icon(Icons.add),
                  label: const Text('File Complaint'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red.shade700,
                    minimumSize: const Size(150, 46),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final complaint = sortedComplaints[index];
              return _buildComplaintCard(context, complaint);
            }, childCount: sortedComplaints.length),
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(BuildContext context, Complaint complaint) {
    final theme = Theme.of(context);

    // Determine status colors
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () => _showComplaintDetails(context, complaint),
        borderRadius: BorderRadius.circular(12),
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
                      color: Colors.red.shade700.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Submitted: ${_formatDate(complaint.createdAt)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(
                        complaint.status.toString(),
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priority',
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
                            color: getPriorityColor(
                              complaint.priority.toString(),
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            complaint.priority.toString().toUpperCase(),
                            style: TextStyle(
                              color: getPriorityColor(
                                complaint.priority.toString(),
                              ),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned To',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.assignedTo,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.update),
                    label: const Text('Update Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showComplaintDetails(context, complaint),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red.shade700,
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

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 72,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add New'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    String? trend,
    bool isPositive = true,
    IconData icon = Icons.trending_up,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.green : Colors.red)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final theme = Theme.of(context);

    // Combine all activities and sort by date
    final activities = [
      if (widget.invoices.isNotEmpty)
        _ActivityItem(
          title: 'Invoice Created',
          description: 'Invoice #${widget.invoices.first.invoiceNumber}',
          date: widget.invoices.first.date,
          icon: Icons.receipt_long,
          color: Colors.blue,
          onTap: () => _showInvoiceDetails(context, widget.invoices.first),
        ),
      if (widget.measurements.isNotEmpty)
        _ActivityItem(
          title: 'Measurement Taken',
          description: widget.measurements.first.style,
          date: widget.measurements.first.date,
          icon: Icons.straighten,
          color: Colors.purple,
          onTap:
              () => _showMeasurementDetails(context, widget.measurements.first),
        ),
      if (widget.complaints.isNotEmpty)
        _ActivityItem(
          title: 'Complaint Filed',
          description: widget.complaints.first.title,
          date: widget.complaints.first.createdAt,
          icon: Icons.warning_amber,
          color: Colors.red,
          onTap: () => _showComplaintDetails(context, widget.complaints.first),
        ),
    ];

    // Sort by date (newest first)
    activities.sort((a, b) => b.date.compareTo(a.date));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 32),
            if (activities.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No activity yet',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length.clamp(0, 5),
                separatorBuilder: (context, index) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _buildActivityRow(
                    context,
                    title: activity.title,
                    description: activity.description,
                    date: activity.date,
                    icon: activity.icon,
                    color: activity.color,
                    onTap: activity.onTap,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(
    BuildContext context, {
    required String title,
    required String description,
    required DateTime date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  _formatTime(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 32),
            _buildQuickActionButton(
              context,
              label: 'New Measurement',
              description: 'Record new measurements',
              icon: Icons.straighten,
              color: Colors.purple,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildQuickActionButton(
              context,
              label: 'Create Invoice',
              description: 'Generate new invoice',
              icon: Icons.receipt_long,
              color: Colors.amber.shade800,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildQuickActionButton(
              context,
              label: 'Schedule Call',
              description: 'Contact the customer',
              icon: Icons.call,
              color: Colors.blue,
              onTap: () => _makePhoneCall(widget.customer.phone),
            ),
            const SizedBox(height: 16),
            _buildQuickActionButton(
              context,
              label: 'WhatsApp',
              description: 'Send WhatsApp message',
              icon: FontAwesomeIcons.whatsapp,
              color: Colors.green,
              onTap: () => _openWhatsApp(widget.customer.whatsapp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  // Removed unused _buildRelatedCustomers method

  // Utility methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showInvoiceDetails(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => InvoiceDetailsDialog(invoice: invoice),
    );
  }

  void _showMeasurementDetails(BuildContext context, Measurement measurement) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    if (isMobile) {
      // Mobile view
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailDialog(
            measurement: measurement,
            customerId: widget.customer.id,
          ),
        ),
      );
    } else {
      // Desktop view
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: size.width * 0.75,
            height: size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: DetailDialog(
              measurement: measurement,
              customerId: widget.customer.id,
            ),
          ),
        ),
      );
    }
  }

  void _showComplaintDetails(BuildContext context, Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => ComplaintDetailDialog(complaint: complaint),
    );
  }



  void _showFullReport(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => CustomerInsightsReport(
            customer: widget.customer,
            measurements: widget.measurements,
            invoices: widget.invoices,
            complaints: widget.complaints,
          ),
    );
  }

  void _shareCustomerInfo() {
    // Format text for sharing
    final ordersCount = widget.invoices.length;
    final measurementsCount = widget.measurements.length;
    final complaintsCount = widget.complaints.length;
    final totalSpent = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + inv.amountIncludingVat,
    );

    final text = '''
Customer Information:
Name: ${widget.customer.name}
Bill Number: ${widget.customer.billNumber}
Phone: ${widget.customer.phone}
${widget.customer.whatsapp.isNotEmpty ? 'WhatsApp: ${widget.customer.whatsapp}' : ''}
Address: ${widget.customer.address}

Summary:
Total Orders: $ordersCount
Total Spent: ${NumberFormatter.formatCurrency(totalSpent)}
Measurements: $measurementsCount
Complaints: $complaintsCount
''';

    // Share text using share_plus package
    Share.share(text, subject: 'Customer: ${widget.customer.name}');
  }

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;

    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;

    // Format phone number (remove any non-digit characters)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Different URL schemes for iOS and Android
    String url;
    if (Platform.isAndroid) {
      url = "whatsapp://send?phone=$cleanPhone";
    } else {
      url = "https://api.whatsapp.com/send?phone=$cleanPhone";
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context,
    IconData icon,
    String text, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String description;
  final DateTime date;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
