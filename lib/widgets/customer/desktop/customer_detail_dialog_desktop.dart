import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/customer.dart';
import '../../../models/invoice.dart';
import '../../../models/measurement.dart';
import '../../../models/complaint.dart';
import '../../../services/customer_service.dart';
import '../../../services/invoice_service.dart';
import '../../../services/measurement_service.dart';
import '../../../services/complaint_service.dart';
import '../../../utils/number_formatter.dart';
import '../../../theme/inventory_design_config.dart';
import 'add_customer_dialog.dart';
import '../../measurement/add_measurement_dialog.dart';
import '../../invoice/add_invoice_dailog.dart';
import '../../complaint/complaint_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final SupabaseService _customerService = SupabaseService();
  final InvoiceService _invoiceService = InvoiceService();
  final MeasurementService _measurementService = MeasurementService();
  final ComplaintService _complaintService = ComplaintService(
    Supabase.instance.client,
  );

  late TabController _tabController;
  bool _isLoading = true;

  // Data
  List<Customer> _familyMembers = [];
  List<Customer> _referrals = [];
  List<Measurement> _measurements = [];
  List<Invoice> _invoices = [];
  List<Complaint> _complaints = [];
  Customer? _referredBy;
  Customer? _familyHead;

  // Financial summary
  double _totalSpent = 0;
  double _pendingPayments = 0;
  int _completedOrders = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadFamilyData(),
        _loadReferralData(),
        _loadCustomerActivity(),
      ]);

      _calculateFinancialSummary();
    } catch (e) {
      debugPrint('Error loading customer data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFamilyData() async {
    _familyMembers = await _customerService.getFamilyMembers(
      widget.customer.id,
    );

    if (widget.customer.familyId != null) {
      _familyHead = await _customerService.getCustomerById(
        widget.customer.familyId!,
      );
    }
  }

  Future<void> _loadReferralData() async {
    _referrals = await _customerService.getReferredCustomers(
      widget.customer.id,
    );

    if (widget.customer.referredBy != null) {
      _referredBy = await _customerService.getCustomerById(
        widget.customer.referredBy!,
      );
    }
  }

  Future<void> _loadCustomerActivity() async {
    final results = await Future.wait([
      _measurementService.getMeasurementsByCustomerId(widget.customer.id),
      _invoiceService.getInvoicesByCustomerId(widget.customer.id),
      _complaintService.getComplaintsByCustomerId(widget.customer.id),
    ]);

    _measurements = results[0] as List<Measurement>;
    _invoices = results[1] as List<Invoice>;
    _complaints = results[2] as List<Complaint>;
  }

  void _calculateFinancialSummary() {
    _totalSpent = 0;
    _pendingPayments = 0;
    _completedOrders = 0;

    for (final invoice in _invoices) {
      _totalSpent += invoice.amountIncludingVat;

      if (invoice.paymentStatus == 'pending' ||
          invoice.paymentStatus == 'partial') {
        _pendingPayments += invoice.balance;
      }

      if (invoice.deliveryStatus == 'delivered') {
        _completedOrders++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Reduced multipliers for overall dialog; width reduced further
    final maxWidth = screenSize.width * 0.65;
    final maxHeight = screenSize.height * 0.75;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth > 1200 ? 1200 : maxWidth,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
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
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXXL,
        vertical: InventoryDesignConfig.spacingL, // reduced height
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          topRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 48, // slightly smaller
            height: 48,
            decoration: BoxDecoration(
              color:
                  widget.customer.gender == Gender.male
                      ? InventoryDesignConfig.infoColor.withOpacity(0.08)
                      : InventoryDesignConfig.successColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    widget.customer.gender == Gender.male
                        ? InventoryDesignConfig.infoColor
                        : InventoryDesignConfig.successColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                widget.customer.name.isNotEmpty
                    ? widget.customer.name[0].toUpperCase()
                    : '?',
                style: InventoryDesignConfig.headlineMedium.copyWith(
                  color:
                      widget.customer.gender == Gender.male
                          ? InventoryDesignConfig.infoColor
                          : InventoryDesignConfig.successColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),

          // Name, badge, and contact chips (compact column)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + gender badge row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.customer.name,
                        style: InventoryDesignConfig.headlineLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: InventoryDesignConfig.spacingM,
                        vertical: InventoryDesignConfig.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color:
                            widget.customer.gender == Gender.male
                                ? InventoryDesignConfig.infoColor.withOpacity(
                                  0.12,
                                )
                                : InventoryDesignConfig.successColor
                                    .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.customer.gender.name.toUpperCase(),
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color:
                              widget.customer.gender == Gender.male
                                  ? InventoryDesignConfig.infoColor
                                  : InventoryDesignConfig.successColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: InventoryDesignConfig.spacingS),
                // Contact chips row
                Wrap(
                  spacing: InventoryDesignConfig.spacingM,
                  runSpacing: InventoryDesignConfig.spacingXS,
                  children: [
                    _buildInfoChip(
                      icon: PhosphorIcons.receipt(),
                      label: '#${widget.customer.billNumber}',
                      onTap: _copyBillNumber,
                    ),
                    _buildInfoChip(
                      icon: PhosphorIcons.phone(),
                      label: widget.customer.phone,
                      onTap: _callCustomer,
                    ),
                    if (widget.customer.whatsapp.isNotEmpty)
                      _buildInfoChip(
                        icon: PhosphorIcons.whatsappLogo(),
                        label: 'WhatsApp',
                        color: InventoryDesignConfig.successColor,
                        onTap: _sendWhatsApp,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons (horizontal, right-aligned)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderButton(
                icon: PhosphorIcons.pencilSimple(),
                label: 'Edit',
                onPressed: _editCustomer,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              _buildHeaderButton(
                icon: PhosphorIcons.x(),
                label: 'Close',
                isSecondary: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    final effectiveColor = color ?? InventoryDesignConfig.textSecondary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingM,
            vertical: InventoryDesignConfig.spacingS,
          ),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: effectiveColor),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                label,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration:
              isSecondary
                  ? InventoryDesignConfig.buttonSecondaryDecoration
                  : InventoryDesignConfig.buttonPrimaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isSecondary
                        ? InventoryDesignConfig.textSecondary
                        : Colors.white,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color:
                      isSecondary
                          ? InventoryDesignConfig.textSecondary
                          : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXXL,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: InventoryDesignConfig.primaryAccent,
        indicatorWeight: 2,
        labelColor: InventoryDesignConfig.primaryAccent,
        unselectedLabelColor: InventoryDesignConfig.textSecondary,
        labelStyle: InventoryDesignConfig.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: InventoryDesignConfig.bodyMedium,
        tabs: [
          _buildTab(PhosphorIcons.chartPie(), 'Overview'),
          _buildTab(PhosphorIcons.receipt(), 'Invoices', _invoices.length),
          _buildTab(
            PhosphorIcons.ruler(),
            'Measurements',
            _measurements.length,
          ),
          _buildTab(PhosphorIcons.users(), 'Family & Referrals'),
          _buildTab(PhosphorIcons.warning(), 'Complaints', _complaints.length),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, [int? count]) {
    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: InventoryDesignConfig.spacingXS),
          Text(label),
          if (count != null && count > 0) ...[
            const SizedBox(width: InventoryDesignConfig.spacingXS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.primaryAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildInvoicesTab(),
        _buildMeasurementsTab(),
        _buildFamilyTab(),
        _buildComplaintsTab(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                InventoryDesignConfig.primaryAccent,
              ),
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          Text(
            'Loading customer data...',
            style: InventoryDesignConfig.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Spent',
                  value: NumberFormatter.formatCurrency(_totalSpent),
                  icon: PhosphorIcons.currencyDollar(),
                  color: InventoryDesignConfig.successColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingL),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Pending Payments',
                  value: NumberFormatter.formatCurrency(_pendingPayments),
                  icon: PhosphorIcons.clock(),
                  color: InventoryDesignConfig.warningColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingL),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Completed Orders',
                  value: _completedOrders.toString(),
                  icon: PhosphorIcons.checkCircle(),
                  color: InventoryDesignConfig.infoColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Personal Information
          _buildSection(
            title: 'Personal Information',
            icon: PhosphorIcons.user(),
            child: _buildPersonalInfo(),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Quick Actions
          _buildSection(
            title: 'Quick Actions',
            icon: PhosphorIcons.lightning(),
            child: _buildQuickActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          Text(
            value,
            style: InventoryDesignConfig.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXS),
          Text(
            title,
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: InventoryDesignConfig.primaryAccent,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  title,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      children: [
        _buildInfoRow(
          'Address',
          widget.customer.address,
          PhosphorIcons.mapPin(),
        ),
        _buildInfoRow('Phone', widget.customer.phone, PhosphorIcons.phone()),
        if (widget.customer.whatsapp.isNotEmpty)
          _buildInfoRow(
            'WhatsApp',
            widget.customer.whatsapp,
            PhosphorIcons.whatsappLogo(),
          ),
        _buildInfoRow(
          'Customer Since',
          DateFormat.yMMMd().format(widget.customer.createdAt),
          PhosphorIcons.calendar(),
        ),
        if (_referredBy != null)
          _buildInfoRow(
            'Referred By',
            _referredBy!.name,
            PhosphorIcons.userPlus(),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: InventoryDesignConfig.spacingS,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: InventoryDesignConfig.textSecondary),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: InventoryDesignConfig.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: InventoryDesignConfig.spacingM,
      runSpacing: InventoryDesignConfig.spacingM,
      children: [
        _buildActionButton(
          icon: PhosphorIcons.ruler(),
          label: 'Add Measurement',
          onPressed: _addMeasurement,
        ),
        _buildActionButton(
          icon: PhosphorIcons.receipt(),
          label: 'Create Invoice',
          onPressed: _addInvoice,
        ),
        _buildActionButton(
          icon: PhosphorIcons.warning(),
          label: 'Add Complaint',
          color: InventoryDesignConfig.errorColor,
          onPressed: _addComplaint,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final effectiveColor = color ?? InventoryDesignConfig.primaryAccent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(color: effectiveColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: effectiveColor),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoicesTab() {
    if (_invoices.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.receipt(),
        title: 'No Invoices',
        description: 'Create the first invoice for this customer.',
        actionLabel: 'Create Invoice',
        onAction: _addInvoice,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      itemCount: _invoices.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: InventoryDesignConfig.spacingL),
      itemBuilder: (context, index) => _buildInvoiceCard(_invoices[index]),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                ),
                child: Icon(
                  PhosphorIcons.receipt(),
                  size: 16,
                  color: InventoryDesignConfig.infoColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice #${invoice.invoiceNumber}',
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(invoice.date),
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                NumberFormatter.formatCurrency(invoice.amountIncludingVat),
                style: InventoryDesignConfig.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: InventoryDesignConfig.spacingM),

          Row(
            children: [
              _buildStatusChip(
                invoice.paymentStatus.toString().split('.').last.toUpperCase(),
                _getPaymentStatusColor(
                  invoice.paymentStatus.toString().split('.').last,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              _buildStatusChip(
                invoice.deliveryStatus.toString().split('.').last.toUpperCase(),
                _getDeliveryStatusColor(
                  invoice.deliveryStatus.toString().split('.').last,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    if (_measurements.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.ruler(),
        title: 'No Measurements',
        description: 'Add the first measurement for this customer.',
        actionLabel: 'Add Measurement',
        onAction: _addMeasurement,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      itemCount: _measurements.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: InventoryDesignConfig.spacingL),
      itemBuilder:
          (context, index) => _buildMeasurementCard(_measurements[index]),
    );
  }

  Widget _buildMeasurementCard(Measurement measurement) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                ),
                child: Icon(
                  PhosphorIcons.ruler(),
                  size: 16,
                  color: InventoryDesignConfig.successColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Style: ${measurement.style}',
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Design: ${measurement.designType}',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat.yMMMd().format(measurement.date),
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ],
          ),

          if (measurement.fabricName.isNotEmpty) ...[
            const SizedBox(height: InventoryDesignConfig.spacingM),
            Text(
              'Fabric: ${measurement.fabricName}',
              style: InventoryDesignConfig.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple overview cards
          Row(
            children: [
              Expanded(
                child: _buildSimpleInfoCard(
                  title: 'Referral Status',
                  value:
                      _referredBy != null
                          ? 'Referred Customer'
                          : 'Direct Customer',
                  subtitle:
                      _referredBy != null
                          ? 'Referred by ${_referredBy!.name}'
                          : 'Joined directly',
                  icon: PhosphorIcons.userPlus(),
                  color:
                      _referredBy != null
                          ? InventoryDesignConfig.infoColor
                          : InventoryDesignConfig.primaryColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingL),
              Expanded(
                child: _buildSimpleInfoCard(
                  title: 'Referrals Made',
                  value: '${_referrals.length} Customers',
                  subtitle:
                      _referrals.isEmpty
                          ? 'No referrals yet'
                          : 'Has referred customers',
                  icon: PhosphorIcons.users(),
                  color:
                      _referrals.isNotEmpty
                          ? InventoryDesignConfig.successColor
                          : InventoryDesignConfig.textSecondary,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingL),
              Expanded(
                child: _buildSimpleInfoCard(
                  title: 'Family Network',
                  value:
                      '${_familyMembers.length + (_familyHead != null ? 1 : 0)} Members',
                  subtitle:
                      _familyMembers.isEmpty && _familyHead == null
                          ? 'No family links'
                          : 'Connected family',
                  icon: PhosphorIcons.houseLine(),
                  color:
                      (_familyMembers.isNotEmpty || _familyHead != null)
                          ? InventoryDesignConfig.warningColor
                          : InventoryDesignConfig.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Who referred this customer
          if (_referredBy != null) ...[
            _buildSimpleSection(
              title: 'Who Referred This Customer',
              icon: PhosphorIcons.arrowDown(),
              child: _buildSimpleCustomerCard(_referredBy!, 'Referrer'),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
          ],

          // Customers this person referred
          if (_referrals.isNotEmpty) ...[
            _buildSimpleSection(
              title: 'Customers They Referred (${_referrals.length})',
              icon: PhosphorIcons.arrowUp(),
              child: Column(
                children:
                    _referrals
                        .map(
                          (customer) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: InventoryDesignConfig.spacingM,
                            ),
                            child: _buildSimpleCustomerCard(
                              customer,
                              'Referred',
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
          ],

          // Family connections
          if (_familyHead != null || _familyMembers.isNotEmpty) ...[
            _buildSimpleSection(
              title: 'Family Connections',
              icon: PhosphorIcons.houseLine(),
              child: Column(
                children: [
                  if (_familyHead != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: InventoryDesignConfig.spacingM,
                      ),
                      child: _buildSimpleCustomerCard(
                        _familyHead!,
                        'Family Head',
                      ),
                    ),
                  ..._familyMembers
                      .map(
                        (customer) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: InventoryDesignConfig.spacingM,
                          ),
                          child: _buildSimpleCustomerCard(
                            customer,
                            customer.familyRelation?.toString().toUpperCase() ??
                                'FAMILY MEMBER',
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ],

          // Empty state
          if (_referredBy == null &&
              _referrals.isEmpty &&
              _familyHead == null &&
              _familyMembers.isEmpty)
            _buildEmptyConnectionsState(),
        ],
      ),
    );
  }

  Widget _buildSimpleInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          Text(
            value,
            style: InventoryDesignConfig.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXS),
          Text(
            subtitle,
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: InventoryDesignConfig.primaryAccent,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  title,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCustomerCard(Customer customer, String relationship) {
    final genderColor =
        customer.gender == Gender.male
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: genderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              border: Border.all(color: genderColor, width: 2),
            ),
            child: Center(
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: InventoryDesignConfig.titleLarge.copyWith(
                  color: genderColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),

          // Customer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingXS),
                Text(
                  '#${customer.billNumber} • ${customer.phone}',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: InventoryDesignConfig.spacingM,
                    vertical: InventoryDesignConfig.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                  ),
                  child: Text(
                    relationship,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSimpleActionButton(
                icon: PhosphorIcons.eye(),
                tooltip: 'View Details',
                onPressed: () {
                  Navigator.of(context).pop();
                  CustomerDetailDialogDesktop.show(
                    context,
                    customer: customer,
                    onCustomerUpdated: widget.onCustomerUpdated,
                  );
                },
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              _buildSimpleActionButton(
                icon: PhosphorIcons.phone(),
                tooltip: 'Call Customer',
                onPressed: () async {
                  final phoneNumber = 'tel:${customer.phone}';
                  if (await canLaunch(phoneNumber)) {
                    await launch(phoneNumber);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        child: Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.primaryAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 16,
              color: InventoryDesignConfig.primaryAccent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyConnectionsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
            ),
            child: Icon(
              PhosphorIcons.users(),
              size: 48,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Text(
            'No Connections Yet',
            style: InventoryDesignConfig.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            'This customer has no family or referral connections.',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods for status colors
  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return InventoryDesignConfig.successColor;
      case 'partial':
        return InventoryDesignConfig.warningColor;
      case 'pending':
      default:
        return InventoryDesignConfig.errorColor;
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return InventoryDesignConfig.successColor;
      case 'in_progress':
        return InventoryDesignConfig.warningColor;
      case 'pending':
      default:
        return InventoryDesignConfig.infoColor;
    }
  }

  Color _getComplaintStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return InventoryDesignConfig.successColor;
      case 'in_progress':
        return InventoryDesignConfig.warningColor;
      case 'pending':
      default:
        return InventoryDesignConfig.errorColor;
    }
  }

  // Action methods
  Future<void> _editCustomer() async {
    await AddCustomerDialog.show(
      context,
      customer: widget.customer,
      isEditing: true,
      onCustomerAdded: () {
        widget.onCustomerUpdated?.call();
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _addMeasurement() async {
    await AddMeasurementDialog.show(context, customer: widget.customer);
    await _loadCustomerActivity();
  }

  Future<void> _addInvoice() async {
    await InvoiceScreen.show(context, customer: widget.customer);
    await _loadCustomerActivity();
    _calculateFinancialSummary();
  }

  Future<void> _addComplaint() async {
    await ComplaintDialog.show(
      context,
      customerId: widget.customer.id,
      customerName: widget.customer.name,
    );
    await _loadCustomerActivity();
  }

  Future<void> _callCustomer() async {
    final phoneNumber = 'tel:${widget.customer.phone}';
    if (await canLaunch(phoneNumber)) {
      await launch(phoneNumber);
    }
  }

  Future<void> _sendWhatsApp() async {
    final whatsappNumber =
        widget.customer.whatsapp.isNotEmpty
            ? widget.customer.whatsapp
            : widget.customer.phone;
    final whatsappUrl = 'https://wa.me/$whatsappNumber';
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    }
  }

  Widget _buildComplaintsTab() {
    if (_complaints.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.warning(),
        title: 'No Complaints',
        description: 'This customer has not filed any complaints.',
        actionLabel: 'Add Complaint',
        onAction: _addComplaint,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      itemCount: _complaints.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: InventoryDesignConfig.spacingL),
      itemBuilder: (context, index) => _buildComplaintCard(_complaints[index]),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                ),
                child: Icon(
                  PhosphorIcons.warning(),
                  size: 16,
                  color: InventoryDesignConfig.errorColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.title,
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(complaint.createdAt),
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(
                complaint.status.toString().split('.').last.toUpperCase(),
                _getComplaintStatusColor(
                  complaint.status.toString().split('.').last,
                ),
              ),
            ],
          ),

          const SizedBox(height: InventoryDesignConfig.spacingM),

          Text(
            complaint.description,
            style: InventoryDesignConfig.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: InventoryDesignConfig.spacingM),

          Row(
            children: [
              Text(
                'Priority: ',
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
              _buildStatusChip(
                complaint.priority.toString().split('.').last.toUpperCase(),
                _getPriorityColor(
                  complaint.priority.toString().split('.').last,
                ),
              ),
              const Spacer(),
              Text(
                'Assigned to: ${complaint.assignedTo}',
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingM,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: InventoryDesignConfig.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
            ),
            child: Icon(
              icon,
              size: 48,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXL),
          Text(
            title,
            style: InventoryDesignConfig.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          Text(
            description,
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: InventoryDesignConfig.spacingXL,
                    vertical: InventoryDesignConfig.spacingM,
                  ),
                  decoration: InventoryDesignConfig.buttonPrimaryDecoration,
                  child: Text(
                    actionLabel,
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return InventoryDesignConfig.errorColor;
      case 'medium':
        return InventoryDesignConfig.warningColor;
      case 'low':
      default:
        return InventoryDesignConfig.successColor;
    }
  }

  void _copyBillNumber() {
    Clipboard.setData(ClipboardData(text: widget.customer.billNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bill number copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: InventoryDesignConfig.successColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        ),
      ),
    );
  }
}
