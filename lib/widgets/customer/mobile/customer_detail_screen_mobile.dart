import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/customer.dart';
import '../../../models/invoice.dart';
import '../../../models/measurement.dart';
import '../../../models/new_complaint_model.dart';
import '../../../services/customer_service.dart';
import '../../../services/invoice_service.dart';
import '../../../services/measurement_service.dart';
import '../../../services/new_complaint_service.dart';
import '../../../utils/number_formatter.dart';
import '../../../theme/inventory_design_config.dart';
import 'add_customer_mobile_sheet.dart';
import '../../measurement/desktop/add_measurement_dialog.dart';
import '../../invoice/desktop/add_edit_invoice_desktop_dialog.dart';
import '../../complaint/new_complaint_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerDetailScreenMobile extends StatefulWidget {
  final Customer customer;
  final VoidCallback? onCustomerUpdated;

  const CustomerDetailScreenMobile({
    super.key,
    required this.customer,
    this.onCustomerUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Customer customer,
    VoidCallback? onCustomerUpdated,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CustomerDetailScreenMobile(
              customer: customer,
              onCustomerUpdated: onCustomerUpdated,
            ),
      ),
    );
  }

  @override
  State<CustomerDetailScreenMobile> createState() =>
      _CustomerDetailScreenMobileState();
}

class _CustomerDetailScreenMobileState extends State<CustomerDetailScreenMobile>
    with TickerProviderStateMixin {
  final SupabaseService _customerService = SupabaseService();
  final InvoiceService _invoiceService = InvoiceService();
  final MeasurementService _measurementService = MeasurementService();
  late final NewComplaintService _complaintService;

  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isLoading = true;
  bool _isAppBarCollapsed = false;

  // Data
  List<Customer> _familyMembers = [];
  List<Customer> _referrals = [];
  List<Measurement> _measurements = [];
  List<Invoice> _invoices = [];
  List<NewComplaint> _complaints = [];
  Customer? _referredBy;
  Customer? _familyHead;

  @override
  void initState() {
    super.initState();
    _complaintService = NewComplaintService(Supabase.instance.client);
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  void _onScroll() {
    final isCollapsed =
        _scrollController.hasClients && _scrollController.offset > 150;
    if (_isAppBarCollapsed != isCollapsed) {
      setState(() {
        _isAppBarCollapsed = isCollapsed;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
    _complaints = results[2] as List<NewComplaint>;
  }

  void _calculateFinancialSummary() {

    for (final invoice in _invoices) {
      if (invoice.paymentStatus == 'pending' ||
          invoice.paymentStatus == 'partial') {
      }
      if (invoice.deliveryStatus == 'delivered') {
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final genderColor =
        widget.customer.gender == Gender.male
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;

    return Scaffold(
      backgroundColor: InventoryDesignConfig.backgroundColor,
      body:
          _isLoading
              ? _buildLoadingState()
              : NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder:
                    (context, innerBoxIsScrolled) => [
                      SliverAppBar(
                        expandedHeight: 220.0,
                        floating: false,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: InventoryDesignConfig.surfaceColor,
                        surfaceTintColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        leading: null,
                        leadingWidth: 0,
                        titleSpacing: 0,
                        title: _buildCollapsedHeader(),
                        actions: [
                          _buildActionButton(
                            icon: PhosphorIcons.pencilSimple(),
                            onPressed: _editCustomer,
                            color: InventoryDesignConfig.primaryColor,
                          ),
                          _buildActionButton(
                            icon: PhosphorIcons.dotsThree(),
                            onPressed: () => _showOptions(context),
                            color: InventoryDesignConfig.textSecondary,
                          ),
                          const SizedBox(width: 16),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: _buildExpandedHeader(genderColor),
                          collapseMode: CollapseMode.parallax,
                        ),
                      ),
                      _buildTabsHeader(),
                    ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildInvoicesTab(),
                    _buildMeasurementsTab(),
                    _buildNetworkTab(),
                  ],
                ),
              ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildCollapsedHeader() {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        // Calculate collapse progress
        final scrollOffset =
            _scrollController.hasClients ? _scrollController.offset : 0.0;
        final maxOffset =
            220.0 - kToolbarHeight - MediaQuery.of(context).padding.top;
        final progress = (scrollOffset / maxOffset).clamp(0.0, 1.0);

        final genderColor =
            widget.customer.gender == Gender.male
                ? InventoryDesignConfig.infoColor
                : InventoryDesignConfig.successColor;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: progress > 0.5 ? 1.0 : 0.0,
          child: Row(
            children: [
              const SizedBox(width: 16),

              // Back button
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: InventoryDesignConfig.borderPrimary,
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      PhosphorIcons.arrowLeft(),
                      size: 16,
                      color: InventoryDesignConfig.textPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Customer avatar (collapsed)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: genderColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: genderColor, width: 1),
                ),
                child: Center(
                  child: Text(
                    widget.customer.name.isNotEmpty
                        ? widget.customer.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: genderColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Customer info (collapsed)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.customer.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: InventoryDesignConfig.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '#${widget.customer.billNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: InventoryDesignConfig.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandedHeader(Color genderColor) {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:
                MainAxisSize.min, // Add this to minimize vertical space
            children: [
              // Top navigation bar
              Row(
                children: [
                  // Back button (always visible in expanded state)
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: InventoryDesignConfig.borderPrimary,
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          PhosphorIcons.arrowLeft(),
                          size: 20,
                          color: InventoryDesignConfig.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 16), // Reduced from 24 to 16
              // Customer avatar and info (expanded)
              Row(
                children: [
                  // Large avatar
                  Hero(
                    tag: 'customer_avatar_${widget.customer.id}',
                    child: Container(
                      width: 72, // Slightly reduced from 80
                      height: 72, // Slightly reduced from 80
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: genderColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: genderColor.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.customer.name.isNotEmpty
                              ? widget.customer.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: genderColor,
                            fontSize: 32, // Slightly reduced from 36
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16), // Reduced from 20
                  // Customer details with tighter spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Add this
                      children: [
                        // Name
                        Hero(
                          tag: 'customer_name_${widget.customer.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.customer.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: InventoryDesignConfig.textPrimary,
                                letterSpacing: -0.5,
                                height: 1.1, // Add this to reduce text height
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4), // Reduced from 8
                        // Bill number and gender in a single row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: InventoryDesignConfig.primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${widget.customer.billNumber}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: InventoryDesignConfig.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: genderColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.customer.gender.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: genderColor,
                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                color == InventoryDesignConfig.primaryColor
                    ? color.withOpacity(0.1)
                    : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  color == InventoryDesignConfig.primaryColor
                      ? color.withOpacity(0.2)
                      : InventoryDesignConfig.borderPrimary,
              width: 0.5,
            ),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildTabsHeader() {
    return SliverPersistentHeader(
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: InventoryDesignConfig.primaryColor,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: InventoryDesignConfig.primaryColor,
          unselectedLabelColor: InventoryDesignConfig.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          dividerColor: InventoryDesignConfig.borderSecondary,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tabs: [
            Tab(
              icon: Icon(PhosphorIcons.chartPie(), size: 16),
              text: 'Overview',
            ),
            Tab(icon: Icon(PhosphorIcons.receipt(), size: 16), text: 'Orders'),
            Tab(
              icon: Icon(PhosphorIcons.ruler(), size: 16),
              text: 'Measurements',
            ),
            Tab(icon: Icon(PhosphorIcons.users(), size: 16), text: 'Network'),
          ],
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information section
          _buildSection(
            title: 'Contact Information',
            icon: PhosphorIcons.identificationCard(),
            child: Column(
              children: [
                _buildInfoRow(
                  'Phone',
                  widget.customer.phone,
                  PhosphorIcons.phone(),
                  onTap: _callCustomer,
                ),
                if (widget.customer.whatsapp.isNotEmpty)
                  _buildInfoRow(
                    'WhatsApp',
                    widget.customer.whatsapp,
                    PhosphorIcons.whatsappLogo(),
                    customColor: InventoryDesignConfig.successColor,
                    onTap: _sendWhatsApp,
                  ),
                _buildInfoRow(
                  'Address',
                  widget.customer.address,
                  PhosphorIcons.mapPin(),
                ),
                _buildInfoRow(
                  'Gender',
                  widget.customer.gender.name,
                  widget.customer.gender == Gender.male
                      ? PhosphorIcons.genderMale()
                      : PhosphorIcons.genderFemale(),
                  customColor:
                      widget.customer.gender == Gender.male
                          ? InventoryDesignConfig.infoColor
                          : InventoryDesignConfig.successColor,
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
                    onTap:
                        () => CustomerDetailScreenMobile.show(
                          context,
                          customer: _referredBy!,
                        ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Complaints section
          if (_complaints.isNotEmpty) ...[
            _buildSection(
              title: 'Recent Issues',
              icon: PhosphorIcons.warning(),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _complaints.length > 2 ? 2 : _complaints.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder:
                    (context, index) => _buildComplaintItem(_complaints[index]),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quick actions
          _buildSection(
            title: 'Quick Actions',
            icon: PhosphorIcons.lightning(),
            child: Column(
              children: [
                _buildQuickActionButton(
                  icon: PhosphorIcons.receipt(),
                  label: 'Create Order',
                  color: InventoryDesignConfig.infoColor,
                  onTap: _addInvoice,
                ),
                const SizedBox(height: 12),
                _buildQuickActionButton(
                  icon: PhosphorIcons.ruler(),
                  label: 'Add Measurement',
                  color: InventoryDesignConfig.successColor,
                  onTap: _addMeasurement,
                ),
                const SizedBox(height: 12),
                _buildQuickActionButton(
                  icon: PhosphorIcons.warning(),
                  label: 'Report Issue',
                  color: InventoryDesignConfig.errorColor,
                  onTap: _addComplaint,
                ),
              ],
            ),
          ),

          // Add space at bottom for FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Updated _buildInfoRow to improve label colors in the Overview tab
  Widget _buildInfoRow(String label, String value, IconData icon, {Color? customColor, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InventoryDesignConfig.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: customColor ?? InventoryDesignConfig.primaryColor),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.primaryColor, // brighter label color
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingXS),
                Text(
                  value,
                  style: InventoryDesignConfig.bodyLarge.copyWith(
                    color: InventoryDesignConfig.textPrimary,
                  ),
                ),
              ],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: InventoryDesignConfig.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildComplaintItem(NewComplaint complaint) {
    final statusColor = complaint.status.color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(PhosphorIcons.warning(), size: 16, color: statusColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                complaint.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      complaint.status.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, y').format(complaint.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(PhosphorIcons.caretRight(), size: 16, color: color),
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
        title: 'No Orders Yet',
        message: 'This customer hasn\'t placed any orders.',
        actionLabel: 'Create First Order',
        onAction: _addInvoice,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      itemCount: _invoices.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: InventoryDesignConfig.spacingM),
      itemBuilder:
          (context, index) => _buildInvoiceCard(_invoices[index], index),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice, int index) {
    final isRecent = index == 0;

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(
          color:
              isRecent
                  ? InventoryDesignConfig.primaryColor.withOpacity(0.3)
                  : InventoryDesignConfig.borderSecondary,
          width: isRecent ? 2 : 1,
        ),
      ),
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
                    Row(
                      children: [
                        Text(
                          'Invoice #${invoice.invoiceNumber}',
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isRecent) ...[
                          const SizedBox(width: InventoryDesignConfig.spacingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: InventoryDesignConfig.primaryColor,
                              borderRadius: BorderRadius.circular(
                                InventoryDesignConfig.radiusS,
                              ),
                            ),
                            child: Text(
                              'LATEST',
                              style: InventoryDesignConfig.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
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

          // Invoice Details
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  'Delivery Date',
                  DateFormat.yMMMd().format(invoice.deliveryDate),
                ),
                if (invoice.balance > 0)
                  _buildDetailRow(
                    'Outstanding',
                    NumberFormatter.formatCurrency(invoice.balance),
                  ),
                if (invoice.measurementName != null)
                  _buildDetailRow('Measurement', invoice.measurementName!),
              ],
            ),
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
        message: 'Add measurements to create custom fitted garments.',
        actionLabel: 'Add Measurement',
        onAction: _addMeasurement,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      itemCount: _measurements.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: InventoryDesignConfig.spacingM),
      itemBuilder:
          (context, index) =>
              _buildMeasurementCard(_measurements[index], index),
    );
  }

  Widget _buildMeasurementCard(Measurement measurement, int index) {
    final isCurrent = index == 0;

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(
          color:
              isCurrent
                  ? InventoryDesignConfig.successColor.withOpacity(0.3)
                  : InventoryDesignConfig.borderSecondary,
          width: isCurrent ? 2 : 1,
        ),
      ),
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
                    Row(
                      children: [
                        Text(
                          measurement.style,
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: InventoryDesignConfig.spacingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: InventoryDesignConfig.successColor,
                              borderRadius: BorderRadius.circular(
                                InventoryDesignConfig.radiusS,
                              ),
                            ),
                            child: Text(
                              'CURRENT',
                              style: InventoryDesignConfig.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      DateFormat.yMMMd().format(measurement.date),
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: InventoryDesignConfig.spacingM),

          // Key measurements
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMeasurementItem(
                        'Length (A)',
                        '${measurement.lengthArabi} cm',
                      ),
                    ),
                    Expanded(
                      child: _buildMeasurementItem(
                        'Length (K)',
                        '${measurement.lengthKuwaiti} cm',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: InventoryDesignConfig.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _buildMeasurementItem(
                        'Chest',
                        '${measurement.chest} cm',
                      ),
                    ),
                    Expanded(
                      child: _buildMeasurementItem(
                        'Width',
                        '${measurement.width} cm',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: InventoryDesignConfig.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _buildMeasurementItem(
                        'Sleeve',
                        '${measurement.sleeve} cm',
                      ),
                    ),
                    Expanded(
                      child: _buildMeasurementItem(
                        'Collar',
                        '${measurement.collar} cm',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingM),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingM,
                  vertical: InventoryDesignConfig.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                ),
                child: Text(
                  measurement.designType,
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingM,
                  vertical: InventoryDesignConfig.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                ),
                child: Text(
                  measurement.tarbooshType,
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.infoColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
        Text(
          value,
          style: InventoryDesignConfig.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkTab() {
    final hasConnections =
        _referredBy != null ||
        _referrals.isNotEmpty ||
        _familyHead != null ||
        _familyMembers.isNotEmpty;

    if (!hasConnections) {
      return _buildEmptyState(
        icon: PhosphorIcons.users(),
        title: 'No Network',
        message: 'This customer has no family or referral connections.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      children: [
        // Network Overview
        _buildNetworkOverview(),

        if (_referredBy != null) ...[
          const SizedBox(height: InventoryDesignConfig.spacingL),
          _buildNetworkSection('Referred By', PhosphorIcons.arrowDown(), [
            _buildNetworkCustomerCard(_referredBy!, 'Referrer'),
          ]),
        ],

        if (_referrals.isNotEmpty) ...[
          const SizedBox(height: InventoryDesignConfig.spacingL),
          _buildNetworkSection(
            'Customers Referred (${_referrals.length})',
            PhosphorIcons.arrowUp(),
            _referrals
                .map(
                  (customer) => _buildNetworkCustomerCard(customer, 'Referred'),
                )
                .toList(),
          ),
        ],

        if (_familyHead != null || _familyMembers.isNotEmpty) ...[
          const SizedBox(height: InventoryDesignConfig.spacingL),
          _buildNetworkSection('Family Network', PhosphorIcons.houseLine(), [
            if (_familyHead != null)
              _buildNetworkCustomerCard(_familyHead!, 'Family Head'),
            ..._familyMembers
                .map(
                  (customer) => _buildNetworkCustomerCard(
                    customer,
                    customer.familyRelation?.toString().toUpperCase() ??
                        'FAMILY MEMBER',
                  ),
                )
                .toList(),
          ]),
        ],
      ],
    );
  }

  Widget _buildNetworkOverview() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.treeStructure(),
                size: 18,
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Network Overview',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Row(
            children: [
              Expanded(
                child: _buildNetworkStat(
                  'Referral Source',
                  _referredBy != null ? 'Referred' : 'Direct',
                  _referredBy != null
                      ? InventoryDesignConfig.infoColor
                      : InventoryDesignConfig.primaryColor,
                ),
              ),
              Expanded(
                child: _buildNetworkStat(
                  'Referrals Made',
                  _referrals.length.toString(),
                  InventoryDesignConfig.successColor,
                ),
              ),
              Expanded(
                child: _buildNetworkStat(
                  'Family Members',
                  (_familyMembers.length + (_familyHead != null ? 1 : 0))
                      .toString(),
                  InventoryDesignConfig.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: InventoryDesignConfig.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNetworkSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: InventoryDesignConfig.primaryColor),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Text(
              title,
              style: InventoryDesignConfig.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        ...children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(
                  bottom: InventoryDesignConfig.spacingM,
                ),
                child: child,
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildNetworkCustomerCard(Customer customer, String relationship) {
    final genderColor =
        customer.gender == Gender.male
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: genderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              border: Border.all(color: genderColor, width: 1.5),
            ),
            child: Center(
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  color: genderColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
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
                Text(
                  '#${customer.billNumber} • ${customer.phone}',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingXS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: InventoryDesignConfig.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                  ),
                  child: Text(
                    relationship,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              PhosphorIcons.arrowSquareOut(),
              size: 16,
              color: InventoryDesignConfig.primaryColor,
            ),
            onPressed:
                () => CustomerDetailScreenMobile.show(
                  context,
                  customer: customer,
                  onCustomerUpdated: widget.onCustomerUpdated,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsTab() {
    if (_complaints.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.warning(),
        title: 'No Issues',
        message: 'This customer has not reported any issues.',
        actionLabel: 'Report Issue',
        onAction: _addComplaint,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      itemCount: _complaints.length,
      separatorBuilder:
          (context, index) => const SizedBox(height: InventoryDesignConfig.spacingM),
      itemBuilder: (context, index) => _buildComplaintCard(_complaints[index]),
    );
  }

  Widget _buildComplaintCard(NewComplaint complaint) {
    final statusColor = complaint.status.color;

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                ),
                child: Icon(
                  PhosphorIcons.warning(),
                  size: 16,
                  color: statusColor,
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
                complaint.status.displayName.toUpperCase(),
                statusColor,
              ),
            ],
          ),

          const SizedBox(height: InventoryDesignConfig.spacingM),

          if (complaint.description != null && complaint.description!.isNotEmpty)
            Text(complaint.description!, style: InventoryDesignConfig.bodyMedium),

          const SizedBox(height: InventoryDesignConfig.spacingM),

          Row(
            children: [
              _buildStatusChip(
                complaint.priority.displayName.toUpperCase(),
                complaint.priority.color,
              ),
              const Spacer(),
              if (complaint.assignedTo != null && complaint.assignedTo!.isNotEmpty)
                Text(
                  'Assigned to ${complaint.assignedTo}',
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusXL,
                ),
              ),
              child: Icon(
                icon,
                size: 48,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Text(
              title,
              style: InventoryDesignConfig.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              message,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: InventoryDesignConfig.spacingL),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(PhosphorIcons.plus(), size: 16),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: InventoryDesignConfig.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: InventoryDesignConfig.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
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
                InventoryDesignConfig.primaryColor,
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

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showQuickActions,
      backgroundColor: InventoryDesignConfig.primaryColor,
      child: Icon(PhosphorIcons.plus(), color: Colors.white),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(InventoryDesignConfig.radiusL),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: InventoryDesignConfig.spacingM,
                  ),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.borderPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
                  child: Text(
                    'Quick Actions',
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.receipt(),
                    color: InventoryDesignConfig.infoColor,
                  ),
                  title: Text(
                    'Create Order',
                    style: InventoryDesignConfig.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _addInvoice();
                  },
                ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.ruler(),
                    color: InventoryDesignConfig.successColor,
                  ),
                  title: Text(
                    'Add Measurement',
                    style: InventoryDesignConfig.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _addMeasurement();
                  },
                ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.warning(),
                    color: InventoryDesignConfig.errorColor,
                  ),
                  title: Text(
                    'Report Issue',
                    style: InventoryDesignConfig.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _addComplaint();
                  },
                ),
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom +
                      InventoryDesignConfig.spacingS,
                ),
              ],
            ),
          ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'call':
        _callCustomer();
        break;
      case 'whatsapp':
        _sendWhatsApp();
        break;
      case 'copy':
        _copyBillNumber();
        break;
    }
  }

  // Helper methods and action handlers
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

  // Action methods
  Future<void> _editCustomer() async {
    await AddCustomerMobileSheet.show(
      context,
      customer: widget.customer,
      isEditing: true,
      onCustomerAdded: () {
        widget.onCustomerUpdated?.call();
        _loadData();
      },
    );
  }

  Future<void> _addMeasurement() async {
    await AddMeasurementDialog.show(context, customer: widget.customer);
    await _loadCustomerActivity();
  }

  Future<void> _addInvoice() async {
    await AddEditInvoiceDesktopDialog.show(
      context,
      customer: widget.customer, // Pass the customer object
    );
    await _loadCustomerActivity();
    _calculateFinancialSummary(); // Keep this call
  }

  Future<void> _addComplaint() async {
    await NewComplaintDialog.show(
      context,
      customerId: widget.customer.id,
      customerName: widget.customer.name,
      onComplaintUpdated: _loadData,
    );
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

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(InventoryDesignConfig.radiusL),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: InventoryDesignConfig.spacingM,
                  ),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.borderPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
                  child: Text(
                    'Customer Options',
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.phone(),
                    color: InventoryDesignConfig.successColor,
                  ),
                  title: Text(
                    'Call Customer',
                    style: InventoryDesignConfig.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _callCustomer();
                  },
                ),
                if (widget.customer.whatsapp.isNotEmpty)
                  ListTile(
                    leading: Icon(
                      PhosphorIcons.whatsappLogo(),
                      color: InventoryDesignConfig.successColor,
                    ),
                    title: Text(
                      'Send WhatsApp',
                      style: InventoryDesignConfig.bodyLarge,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _sendWhatsApp();
                    },
                  ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.copy(),
                    color: InventoryDesignConfig.infoColor,
                  ),
                  title: Text(
                    'Copy Bill Number',
                    style: InventoryDesignConfig.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _copyBillNumber();
                  },
                ),
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom +
                      InventoryDesignConfig.spacingS,
                ),
              ],
            ),
          ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 0.5,
          ),
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
