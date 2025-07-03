import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/customer.dart';
import '../../../models/measurement.dart';
import '../../invoice/desktop/add_edit_invoice_desktop_dialog.dart';
import '../../invoice/desktop/invoice_detail_dialog_desktop.dart';
import '../../measurement/desktop/add_measurement_dialog.dart';
import '../../measurement/desktop/measurement_detail_dialog.dart';
import '../../complaint/desktop/complaint_detail_dialog_desktop.dart';
import '../../../models/new_complaint_model.dart';

class CustomerDetailDialogDesktop extends StatefulWidget {
  final Customer customer;
  final VoidCallback? onCustomerUpdated;

  const CustomerDetailDialogDesktop({
    super.key,
    required this.customer,
    this.onCustomerUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Customer customer,
    VoidCallback? onCustomerUpdated,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => CustomerDetailDialogDesktop(
            customer: customer,
            onCustomerUpdated: onCustomerUpdated,
          ),
    );
  }

  @override
  State<CustomerDetailDialogDesktop> createState() =>
      _CustomerDetailDialogDesktopState();
}

class _CustomerDetailDialogDesktopState
    extends State<CustomerDetailDialogDesktop>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;

  // Data containers
  List<Map<String, dynamic>> _invoices = [];
  List<Measurement> _measurements = [];
  List<Map<String, dynamic>> _complaints = [];

  // Statistics
  double _totalSpent = 0.0;
  double _pendingPayments = 0.0;
  int _completedOrders = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchCustomerData();
  }

  Future<void> _fetchCustomerData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch all customer-related data concurrently
      await Future.wait([
        _fetchInvoices(),
        _fetchMeasurements(),
        _fetchComplaints(),
      ]);

      _calculateStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching customer data: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchInvoices() async {
    try {
      final response = await _supabase
          .from('invoices')
          .select('*')
          .eq('customer_id', widget.customer.id)
          .order('date', ascending: false);

      setState(() {
        _invoices = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching invoices: $e');
    }
  }

  Future<void> _fetchMeasurements() async {
    try {
      final response = await _supabase
          .from('measurements')
          .select('*')
          .eq('customer_id', widget.customer.id)
          .order('date', ascending: false);

      setState(() {
        _measurements =
            response.map((item) => Measurement.fromMap(item)).toList();
      });
    } catch (e) {
      print('Error fetching measurements: $e');
    }
  }

  Future<void> _fetchComplaints() async {
    try {
      final response = await _supabase
          .from('complaints')
          .select('*')
          .eq('customer_id', widget.customer.id)
          .order('created_at', ascending: false);

      setState(() {
        _complaints = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching complaints: $e');
    }
  }

  void _calculateStats() {
    _totalSpent = _invoices
        .where((inv) => inv['payment_status'] == 'Paid')
        .fold(
          0.0,
          (sum, inv) => sum + (inv['amount_including_vat'] as num).toDouble(),
        );

    _pendingPayments = _invoices
        .where((inv) => inv['payment_status'] != 'Paid')
        .fold(0.0, (sum, inv) => sum + (inv['balance'] as num).toDouble());

    _completedOrders =
        _invoices.where((inv) => inv['delivery_status'] == 'Delivered').length;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.92;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1100, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildInvoicesTab(),
                          _buildMeasurementsTab(),
                          _buildComplaintsTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(
            color: InventoryDesignConfig.borderSecondary.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  InventoryDesignConfig.primaryColor,
                  InventoryDesignConfig.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.customer.name.isNotEmpty
                    ? widget.customer.name[0].toUpperCase()
                    : 'C',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
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
                  style: InventoryDesignConfig.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildCompactChip(
                      '#${widget.customer.billNumber}',
                      InventoryDesignConfig.primaryColor,
                      PhosphorIcons.hash(PhosphorIconsStyle.bold),
                    ),
                    const SizedBox(width: 8),
                    _buildCompactChip(
                      widget.customer.phone,
                      InventoryDesignConfig.textSecondary,
                      PhosphorIcons.phone(PhosphorIconsStyle.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: InventoryDesignConfig.borderSecondary.withOpacity(0.5),
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                PhosphorIcons.x(PhosphorIconsStyle.bold),
                size: 16,
              ),
              tooltip: 'Close',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              InventoryDesignConfig.primaryColor,
              InventoryDesignConfig.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelStyle: InventoryDesignConfig.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: InventoryDesignConfig.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: [
          _buildModernTab('Overview', PhosphorIcons.user(PhosphorIconsStyle.bold)),
          _buildModernTab('Invoices', PhosphorIcons.receipt(PhosphorIconsStyle.bold)),
          _buildModernTab('Measurements', PhosphorIcons.ruler(PhosphorIconsStyle.bold)),
          _buildModernTab('Complaints', PhosphorIcons.warningCircle(PhosphorIconsStyle.bold)),
        ],
      ),
    );
  }

  Widget _buildModernTab(String text, IconData icon) {
    return Tab(
      height: 48,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: InventoryDesignConfig.borderSecondary.withOpacity(0.5),
              ),
            ),
            child: SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  InventoryDesignConfig.primaryColor,
                ),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading customer data...',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Cards with enhanced design
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: InventoryDesignConfig.borderPrimary.withOpacity(0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        PhosphorIcons.chartLine(PhosphorIconsStyle.bold),
                        size: 16,
                        color: InventoryDesignConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Financial Overview',
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildEnhancedStatsCard(
                        'Total Spent',
                        NumberFormat.currency(symbol: 'AED ').format(_totalSpent),
                        PhosphorIcons.trendUp(PhosphorIconsStyle.bold),
                        InventoryDesignConfig.successColor,
                        'All completed payments',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEnhancedStatsCard(
                        'Pending',
                        NumberFormat.currency(symbol: 'AED ').format(_pendingPayments),
                        PhosphorIcons.clock(PhosphorIconsStyle.bold),
                        InventoryDesignConfig.warningColor,
                        'Outstanding balance',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEnhancedStatsCard(
                        'Orders',
                        _completedOrders.toString(),
                        PhosphorIcons.package(PhosphorIconsStyle.bold),
                        InventoryDesignConfig.primaryColor,
                        'Delivered items',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Content Row with enhanced cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information
              Expanded(
                flex: 3,
                child: _buildEnhancedInfoSection(),
              ),
              const SizedBox(width: 16),
              // Quick Actions
              Expanded(
                flex: 2,
                child: _buildEnhancedQuickActionsSection(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Icon(
                PhosphorIcons.trendUp(PhosphorIconsStyle.bold),
                size: 12,
                color: color.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: InventoryDesignConfig.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            subtitle,
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: InventoryDesignConfig.borderPrimary.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIcons.info(PhosphorIconsStyle.bold),
                  size: 16,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Personal Information',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedInfoRow(
            'Address',
            widget.customer.address,
            PhosphorIcons.mapPin(PhosphorIconsStyle.bold),
          ),
          _buildEnhancedInfoRow(
            'Phone',
            widget.customer.phone,
            PhosphorIcons.phone(PhosphorIconsStyle.bold),
          ),
          _buildEnhancedInfoRow(
            'Gender',
            widget.customer.gender.name.toUpperCase(),
            PhosphorIcons.user(PhosphorIconsStyle.bold),
          ),
          _buildEnhancedInfoRow(
            'Member Since',
            DateFormat('MMMM d, yyyy').format(widget.customer.createdAt),
            PhosphorIcons.calendar(PhosphorIconsStyle.bold),
          ),
          
          // Customer stats
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.star(PhosphorIconsStyle.bold),
                  size: 14,
                  color: InventoryDesignConfig.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Customer ID: #${widget.customer.billNumber}',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 12,
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: InventoryDesignConfig.borderPrimary.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIcons.lightning(PhosphorIconsStyle.bold),
                  size: 16,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Quick Actions',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedActionButton(
            'Add Measurement',
            'Create new body measurements',
            PhosphorIcons.ruler(PhosphorIconsStyle.bold),
            InventoryDesignConfig.successColor,
            () {
              AddMeasurementDialog.show(
                context,
                customer: widget.customer,
                onMeasurementAdded: _fetchCustomerData,
              );
            },
          ),
          const SizedBox(width: 12),
          _buildEnhancedActionButton(
            'Create Invoice',
            'Generate new invoice',
            PhosphorIcons.receipt(PhosphorIconsStyle.bold),
            InventoryDesignConfig.primaryColor,
            () {
              AddEditInvoiceDesktopDialog.show(
                context,
                customer: widget.customer,
                onInvoiceSaved: _fetchCustomerData,
              );
            },
          ),
          const SizedBox(width: 12),
          _buildEnhancedActionButton(
            'Add Complaint',
            'Log customer complaint',
            PhosphorIcons.warning(PhosphorIconsStyle.bold),
            InventoryDesignConfig.warningColor,
            () {
              // TODO: Implement Add Complaint
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Add complaint feature coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: color.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                  size: 16,
                  color: color.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: InventoryDesignConfig.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: InventoryDesignConfig.borderSecondary.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.info(PhosphorIconsStyle.bold),
                size: 14,
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Personal Information',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCompactInfoRow('Address', widget.customer.address),
          _buildCompactInfoRow('Phone', widget.customer.phone),
          _buildCompactInfoRow('Gender', widget.customer.gender.name.toUpperCase()),
          _buildCompactInfoRow(
            'Member Since',
            DateFormat('MMM d, yyyy').format(widget.customer.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: InventoryDesignConfig.borderSecondary.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.lightning(PhosphorIconsStyle.bold),
                size: 14,
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Quick Actions',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            'Add Measurement',
            PhosphorIcons.ruler(PhosphorIconsStyle.bold),
            () {
              AddMeasurementDialog.show(
                context,
                customer: widget.customer,
                onMeasurementAdded: _fetchCustomerData,
              );
            },
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            'Create Invoice',
            PhosphorIcons.receipt(PhosphorIconsStyle.bold),
            () {
              AddEditInvoiceDesktopDialog.show(
                context,
                customer: widget.customer,
                onInvoiceSaved: _fetchCustomerData,
              );
            },
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            'Add Complaint',
            PhosphorIcons.warning(PhosphorIconsStyle.bold),
            () {
              // TODO: Implement Add Complaint
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: InventoryDesignConfig.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: InventoryDesignConfig.primaryColor.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: InventoryDesignConfig.primaryColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildInvoicesTab() {
    if (_invoices.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.receipt(PhosphorIconsStyle.bold),
        title: 'No Invoices Found',
        message: 'This customer does not have any invoices yet.',
        actionLabel: 'Create Invoice',
        onAction: () => AddEditInvoiceDesktopDialog.show(
          context,
          customer: widget.customer,
          onInvoiceSaved: _fetchCustomerData,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 320).floor().clamp(1, 4);
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.4,
          ),
          itemCount: _invoices.length,
          itemBuilder: (context, index) => _buildCleanInvoiceCard(_invoices[index]),
        );
      },
    );
  }

  Widget _buildCleanInvoiceCard(Map<String, dynamic> invoice) {
    final paymentStatus = invoice['payment_status'] ?? 'Pending';
    final deliveryStatus = invoice['delivery_status'] ?? 'Pending';
    final balance = invoice['balance'] ?? 0.0;
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          InvoiceDetailDialogDesktop.show(
            context,
            invoice: invoice,
            onInvoiceUpdated: () {
              _fetchCustomerData();
              widget.onCustomerUpdated?.call();
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIcons.receipt(PhosphorIconsStyle.bold),
                      size: 16,
                      color: InventoryDesignConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${invoice['invoice_number']}',
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d').format(DateTime.parse(invoice['date'])),
                          style: InventoryDesignConfig.bodySmall.copyWith(
                            color: InventoryDesignConfig.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: 'AED ').format(
                        (invoice['amount_including_vat'] as num).toDouble(),
                      ),
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        color: InventoryDesignConfig.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Status row
              Row(
                children: [
                  Expanded(
                    child: _buildCleanStatusChip(paymentStatus, _getStatusColor(paymentStatus)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCleanStatusChip(deliveryStatus, _getStatusColor(deliveryStatus)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatusChip(String status, Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: color.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPaymentProgress(double paidAmount, double totalAmount) {
    final percentage = (paidAmount / totalAmount).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Progress',
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      InventoryDesignConfig.primaryColor,
                      InventoryDesignConfig.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusChip(String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              status,
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProgress(double paidAmount, double totalAmount) {
    final percentage = (paidAmount / totalAmount).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Progress',
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: InventoryDesignConfig.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'delivered':
        return InventoryDesignConfig.successColor;
      case 'pending':
        return InventoryDesignConfig.warningColor;
      case 'overdue':
      case 'cancelled':
        return InventoryDesignConfig.errorColor;
      default:
        return InventoryDesignConfig.textSecondary;
    }
  }

  Widget _buildMeasurementsTab() {
    if (_measurements.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.ruler(PhosphorIconsStyle.bold),
        title: 'No Measurements Found',
        message: 'This customer does not have any measurements yet.',
        actionLabel: 'Add Measurement',
        onAction: () => AddMeasurementDialog.show(
          context,
          customer: widget.customer,
          onMeasurementAdded: _fetchCustomerData,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 280).floor().clamp(1, 5);
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemCount: _measurements.length,
          itemBuilder: (context, index) => _buildCleanMeasurementCard(_measurements[index]),
        );
      },
    );
  }

  Widget _buildCleanMeasurementCard(Measurement measurement) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          DetailDialog.show(
            context,
            measurement: measurement,
            customerId: widget.customer.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: InventoryDesignConfig.successColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: InventoryDesignConfig.successColor.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIcons.ruler(PhosphorIconsStyle.bold),
                      size: 16,
                      color: InventoryDesignConfig.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          measurement.style,
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('MMM d').format(measurement.lastUpdated),
                          style: InventoryDesignConfig.bodySmall.copyWith(
                            color: InventoryDesignConfig.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Measurement Set',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintsTab() {
    if (_complaints.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
        title: 'No Complaints Found',
        message: 'This customer does not have any complaints.',
        actionLabel: 'Add Complaint',
        onAction: () {
          // TODO: Implement Add Complaint
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 300).floor().clamp(1, 4);
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: _complaints.length,
          itemBuilder: (context, index) => _buildCleanComplaintCard(_complaints[index]),
        );
      },
    );
  }

  Widget _buildCleanComplaintCard(Map<String, dynamic> complaint) {
    final priority = complaint['priority'] ?? 'Medium';
    final status = complaint['status'] ?? 'Open';
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Complaint "${complaint['title'] ?? 'Untitled'}" details - Coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: InventoryDesignConfig.errorColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: InventoryDesignConfig.errorColor.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                      size: 16,
                      color: InventoryDesignConfig.errorColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint['title'] ?? 'Untitled',
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (complaint['created_at'] != null)
                          Text(
                            DateFormat('MMM d').format(DateTime.parse(complaint['created_at'])),
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color: InventoryDesignConfig.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              if (complaint['description'] != null)
                Text(
                  complaint['description'],
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const Spacer(),
              
              // Status row
              Row(
                children: [
                  Expanded(
                    child: _buildCleanStatusChip(status, _getComplaintStatusColor(status)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCleanStatusChip(priority, _getPriorityColor(priority)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: InventoryDesignConfig.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return InventoryDesignConfig.errorColor;
      case 'medium':
        return InventoryDesignConfig.warningColor;
      case 'low':
        return InventoryDesignConfig.successColor;
      default:
        return InventoryDesignConfig.textSecondary;
    }
  }

  Color _getComplaintStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return InventoryDesignConfig.successColor;
      case 'in progress':
      case 'investigating':
        return InventoryDesignConfig.warningColor;
      case 'open':
      case 'pending':
        return InventoryDesignConfig.primaryColor;
      default:
        return InventoryDesignConfig.textSecondary;
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.textTertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 40,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: InventoryDesignConfig.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    InventoryDesignConfig.primaryColor,
                    InventoryDesignConfig.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(
                  PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  size: 14,
                ),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: InventoryDesignConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
