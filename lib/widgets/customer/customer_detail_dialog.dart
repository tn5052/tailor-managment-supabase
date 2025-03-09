import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/measurement.dart';
import '../../models/complaint.dart';
import '../../services/customer_service.dart';
import '../../services/invoice_service.dart';
import '../../services/measurement_service.dart';
import '../../services/complaint_service.dart';
import '../../utils/number_formatter.dart';
import 'add_customer_dialog.dart';
import '../measurement/detail_dialog.dart';
import '../measurement/add_measurement_dialog.dart';
import '../invoice/invoice_details_dialog.dart';
import '../invoice/add_invoice_dailog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../complaint/complaint_dialog.dart';
class CustomerDetailDialog extends StatefulWidget {
  final Customer customer;

  const CustomerDetailDialog({
    super.key,
    required this.customer,
  });

  // Static method to show the dialog
  static Future<void> show(BuildContext context, Customer customer) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      // Desktop sized dialog
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 1000,
            constraints: BoxConstraints(
              maxWidth: 1000,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: CustomerDetailDialog(customer: customer),
          ),
        ),
      );
    } else {
      // Mobile full screen
      return Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CustomerDetailDialog(customer: customer),
        ),
      ).then((_) {}); // Convert Future<Object?> to Future<void>
    }
  }

  @override
  State<CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<CustomerDetailDialog> with SingleTickerProviderStateMixin {
  final SupabaseService _customerService = SupabaseService();
  final InvoiceService _invoiceService = InvoiceService();
  final MeasurementService _measurementService = MeasurementService();
  final ComplaintService _complaintService = ComplaintService(Supabase.instance.client); // Fix: Pass Supabase client

  late TabController _tabController;
  bool _isLoading = true;
  List<Customer> _familyMembers = [];
  List<Customer> _referrals = [];
  List<Measurement> _measurements = [];
  List<Invoice> _invoices = [];
  List<Complaint> _complaints = [];
  
  Customer? _referredBy;
  Customer? _familyHead;
  
  int _totalSpent = 0;
  int _pendingPayments = 0;

  @override
  void initState() {
    super.initState();
    // Create TabController with 6 tabs (including the new Overview tab)
    _tabController = TabController(length: 6, vsync: this);
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
      // Load all data in parallel for efficiency
      await Future.wait([
        _loadFamilyData(),
        _loadReferralData(),
        _loadCustomerActivity(),
      ]);
      
      // Calculate financial summary
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
    // Load family members
    _familyMembers = await _customerService.getFamilyMembers(widget.customer.id);
    
    // If customer is part of a family, load family head
    if (widget.customer.familyId != null) {
      _familyHead = await _customerService.getCustomerById(widget.customer.familyId!);
    }
  }

  Future<void> _loadReferralData() async {
    // Load customers referred by this customer
    _referrals = await _customerService.getReferredCustomers(widget.customer.id);
    
    // If customer was referred by someone, load that customer
    if (widget.customer.referredBy != null) {
      _referredBy = await _customerService.getCustomerById(widget.customer.referredBy!);
    }
  }

  Future<void> _loadCustomerActivity() async {
    // Load customer activity data
    final measurementsFuture = _measurementService.getMeasurementsByCustomerId(widget.customer.id);
    final invoicesFuture = _invoiceService.getInvoicesByCustomerId(widget.customer.id);
    final complaintsFuture = _complaintService.getComplaintsByCustomerId(widget.customer.id);
    
    // Wait for all futures to complete
    final results = await Future.wait([
      measurementsFuture, 
      invoicesFuture, 
      complaintsFuture
    ]);
    
    // Update state with results
    _measurements = results[0] as List<Measurement>;
    _invoices = results[1] as List<Invoice>;
    _complaints = results[2] as List<Complaint>;
  }

  void _calculateFinancialSummary() {
    _totalSpent = 0;
    _pendingPayments = 0;
    
    for (final invoice in _invoices) {
      _totalSpent += invoice.amountIncludingVat.toInt();
      if (invoice.paymentStatus == 'pending' || invoice.paymentStatus == 'partial') {
        _pendingPayments += invoice.balance.toInt();
      }
    }
  }

  Future<void> _editCustomer() async {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    if (isDesktop) {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: Container(
            width: 600,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: AddCustomerDialog(
                customer: widget.customer,
                isEditing: true,
              ),
            ),
          ),
        ),
      );
    } else {
      // Full screen dialog for mobile
      await showDialog(
        context: context,
        builder: (context) => AddCustomerDialog(
          customer: widget.customer,
          isEditing: true,
        ),
        barrierDismissible: false,
        useSafeArea: true,
      );
    }
    
    // Reload data after edit
    await _loadData();
  }

  Future<void> _addMeasurement() async {
    await AddMeasurementDialog.show(
      context,
      customer: widget.customer,
    );
    
    // Reload measurements
    final measurements = await _measurementService.getMeasurementsByCustomerId(widget.customer.id);
    setState(() => _measurements = measurements);
  }

  Future<void> _addInvoice() async {
    await InvoiceScreen.show(
      context,
      customer: widget.customer,
    );
    
    // Reload invoices and financial summary
    final invoices = await _invoiceService.getInvoicesByCustomerId(widget.customer.id);
    setState(() => _invoices = invoices);
    _calculateFinancialSummary();
  }
  
  Future<void> _viewMeasurement(Measurement measurement) async {
    await DetailDialog.show(
      context,
      measurement: measurement,
      customerId: widget.customer.id,
    );
  }

  Future<void> _viewInvoice(Invoice invoice) async {
    await InvoiceDetailsDialog.show(
      context,
      invoice,
    );
    
    // Reload invoices in case any changes were made
    final invoices = await _invoiceService.getInvoicesByCustomerId(widget.customer.id);
    setState(() => _invoices = invoices);
    _calculateFinancialSummary();
  }

  Future<void> _viewComplaint(Complaint complaint) async {
    // Open complaint detail dialog (to be implemented)
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 800,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text('Complaint Detail Dialog'), // To be replaced with actual complaint dialog
          ),
        ),
      ),
    );
  }

  Future<void> _callCustomer() async {
    final phoneNumber = 'tel:${widget.customer.phone}';
    if (await canLaunch(phoneNumber)) {
      await launch(phoneNumber);
    }
  }

  Future<void> _sendWhatsApp() async {
    final whatsappNumber = widget.customer.whatsapp.isNotEmpty 
        ? widget.customer.whatsapp 
        : widget.customer.phone;
    final whatsappUrl = 'https://wa.me/$whatsappNumber';
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    }
  }

  void _copyPhone() {
    Clipboard.setData(ClipboardData(text: widget.customer.phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone number copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyBillNumber() {
    Clipboard.setData(ClipboardData(text: widget.customer.billNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bill number copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final brightness = theme.brightness;
  
  return Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Simplified Top header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Reduced vertical padding
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20, // Reduced radius
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Text(
                  widget.customer.name[0].toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Reduced font size
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.customer.name,
                  style: theme.textTheme.titleLarge?.copyWith( // Use titleLarge for better consistency
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Compact action buttons
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  IconButton(
                    onPressed: _addMeasurement,
                    icon: const Icon(Icons.straighten),
                    tooltip: 'Add Measurement',
                  ),
                  IconButton(
                    onPressed: _addInvoice,
                    icon: const Icon(Icons.receipt),
                    tooltip: 'Create Invoice',
                  ),
                  IconButton(
                    onPressed: _addComplaint,
                    icon: const Icon(Icons.report_problem_outlined),
                    tooltip: 'Add Complaint',
                    color: colorScheme.error,
                  ),
                  IconButton(
                    onPressed: _editCustomer,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Customer',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Tab bar at the top
        Container(
          decoration: BoxDecoration(
            color: brightness == Brightness.light
                ? colorScheme.surfaceContainerLowest
                : colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: [
              _buildTab(Icons.dashboard_outlined, 'Overview'),
              _buildTab(Icons.straighten_rounded, 'Measurements'),
              _buildTab(Icons.receipt_long_rounded, 'Invoices'),
              _buildTab(Icons.family_restroom_rounded, 'Family'),
              _buildTab(Icons.people_alt_rounded, 'Referrals'),
              _buildTab(Icons.report_problem_rounded, 'Complaints'),
            ],
            isScrollable: true,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            dividerColor: Colors.transparent,
          ),
        ),
        
        // Tab content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(theme),
                    _buildMeasurementsTab(theme),
                    _buildInvoicesTab(theme),
                    _buildFamilyTab(theme),
                    _buildReferralsTab(theme),
                    _buildComplaintsTab(theme),
                  ],
                ),
        ),
      ],
    ),
  );
}

Widget _buildMobileLayout(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  return Scaffold(
    backgroundColor: colorScheme.background,
    appBar: AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: colorScheme.surface,
      centerTitle: false,
      title: Text(
        widget.customer.name,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _editCustomer,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit',
        ),
        IconButton(
          onPressed: () => _showActions(context),
          icon: const Icon(Icons.more_vert_outlined),
          tooltip: 'More',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Measurements'),
          Tab(text: 'Invoices'),
          Tab(text: 'Family'),
          Tab(text: 'Referrals'),
          Tab(text: 'Complaints'),
        ],
      ),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(theme),
              _buildMeasurementsTab(theme),
              _buildInvoicesTab(theme),
              _buildFamilyTab(theme),
              _buildReferralsTab(theme),
              _buildComplaintsTab(theme),
            ],
          ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showActionSheet(context),
      child: const Icon(Icons.add),
    ),
  );
}


void _showActions(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Options',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          
          // Divider
          Divider(color: colorScheme.outlineVariant.withOpacity(0.3)),
          
          // Options list
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetAction(
                  context: context,
                  icon: Icons.content_copy_outlined,
                  iconColor: colorScheme.primary,
                  label: 'Copy Phone Number',
                  onTap: () {
                    Navigator.pop(context);
                    _copyPhone();
                  },
                ),
                _buildSheetAction(
                  context: context,
                  icon: Icons.receipt_outlined,
                  iconColor: colorScheme.primary,
                  label: 'Copy Bill Number',
                  onTap: () {
                    Navigator.pop(context);
                    _copyBillNumber();
                  },
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: colorScheme.outlineVariant.withOpacity(0.3)),
                ),
                
                _buildSheetAction(
                  context: context,
                  icon: Icons.edit_outlined,
                  iconColor: colorScheme.primary,
                  label: 'Edit Customer',
                  onTap: () {
                    Navigator.pop(context);
                    _editCustomer();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSheetAction({
  required BuildContext context, 
  required IconData icon,
  required Color iconColor,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildOverviewTab(ThemeData theme) {
  final colorScheme = theme.colorScheme;
  
  return ListView(
    padding: const EdgeInsets.only(bottom: 24),
    children: [
      // Quick action buttons row for desktop
      if (MediaQuery.of(context).size.width >= 1024) 
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  theme,
                  icon: Icons.phone_outlined,
                  label: 'Call Customer',
                  description: widget.customer.phone,
                  onTap: _callCustomer,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              if (widget.customer.whatsapp.isNotEmpty)
                Expanded(
                  child: _buildQuickActionCard(
                    theme,
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    description: widget.customer.whatsapp,
                    onTap: _sendWhatsApp,
                    color: const Color(0xFF25D366), // WhatsApp green
                  ),
                )
              else
                Expanded(
                  child: _buildQuickActionCard(
                    theme,
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    description: 'Not available',
                    color: colorScheme.surfaceVariant,
                    textColor: colorScheme.onSurfaceVariant,
                    onTap: null,
                  ),
                ),
            ],
          ),
        ),

      // Customer Info Card
      Card(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Personal Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              // Contact information
              _buildInfoRow(
                theme,
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: widget.customer.phone,
                onTap: _callCustomer,
              ),
              if (widget.customer.whatsapp.isNotEmpty)
                _buildInfoRow(
                  theme,
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  value: widget.customer.whatsapp,
                  onTap: _sendWhatsApp,
                ),
              _buildInfoRow(
                theme,
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: widget.customer.address,
              ),
              _buildInfoRow(
                theme,
                icon: Icons.calendar_today_outlined,
                label: 'Customer Since',
                value: DateFormat.yMMMMd().format(widget.customer.createdAt),
              ),
              _buildInfoRow(
                theme,
                icon: Icons.receipt_outlined,
                label: 'Bill Number',
                value: '#' + widget.customer.billNumber,
                onTap: _copyBillNumber,
              ),
            ],
          ),
        ),
      ),
      
      // Financial Summary Card
      Card(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Financial Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Financial stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFinancialStat(
                    theme,
                    title: 'Total Spent',
                    value: NumberFormatter.formatCurrency(_totalSpent.toDouble()),
                    growth: _totalSpent > 0 ? '+100%' : '0%',
                    isPositive: true,
                  ),
                  if (_pendingPayments > 0)
                    _buildFinancialStat(
                      theme,
                      title: 'Due Payments',
                      value: NumberFormatter.formatCurrency(_pendingPayments.toDouble()),
                      badgeText: 'PENDING',
                      isPositive: false,
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActivityCount(
                            theme,
                            count: _invoices.length,
                            label: 'Invoices',
                            icon: Icons.receipt_long_outlined,
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActivityCount(
                            theme,
                            count: _measurements.length,
                            label: 'Measurements',
                            icon: Icons.straighten_outlined,
                            color: colorScheme.tertiary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActivityCount(
                            theme,
                            count: _complaints.length,
                            label: 'Complaints',
                            icon: Icons.report_problem_outlined,
                            color: _complaints.isEmpty ? colorScheme.onSurfaceVariant : colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Relationships Section (if any)
      if (_referredBy != null || _referrals.isNotEmpty || 
          _familyHead != null || _familyMembers.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Relationships',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        
        if (_referredBy != null)
          _buildRelationCard(
            theme,
            title: 'Referred By',
            icon: Icons.person_add_outlined,
            iconColor: colorScheme.secondary,
            customer: _referredBy!,
          ),
          
        if (_referrals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildActionLink(
              theme,
              title: '${_referrals.length} ${_referrals.length == 1 ? 'Customer' : 'Customers'} Referred',
              icon: Icons.people_outlined,
              onTap: () => _tabController.animateTo(4), // Navigate to Referrals tab
            ),
          ),
          
        if (_familyHead != null)
          _buildRelationCard(
            theme,
            title: 'Family Head',
            icon: Icons.family_restroom,
            iconColor: colorScheme.tertiary,
            customer: _familyHead!,
            subtitle: widget.customer.familyRelationDisplay,
          ),
          
        if (_familyMembers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildActionLink(
              theme,
              title: '${_familyMembers.length} Family ${_familyMembers.length == 1 ? 'Member' : 'Members'}',
              icon: Icons.groups_outlined, 
              onTap: () => _tabController.animateTo(3), // Navigate to Family tab
            ),
          ),
      ],
      
      // Recent Activity section
      if (_measurements.isNotEmpty || _invoices.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Recent Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        
        // Recent measurements and invoices in a minimalist list
        ..._buildRecentActivity(theme),
      ],
    ],
  );
}

Widget _buildQuickActionCard(
  ThemeData theme, {
  required IconData icon,
  required String label,
  required String description,
  Color? color,
  Color? textColor,
  VoidCallback? onTap,
}) {
  final colorScheme = theme.colorScheme;
  final effectiveColor = color ?? colorScheme.primary;
  final effectiveTextColor = textColor ?? effectiveColor;

  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: effectiveColor.withOpacity(0.2),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: effectiveTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: effectiveTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: effectiveTextColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// New helper method to build financial stats
Widget _buildFinancialStat(
  ThemeData theme, {
  required String title,
  required String value,
  String? growth,
  String? badgeText,
  required bool isPositive,
}) {
  final colorScheme = theme.colorScheme;
  final color = isPositive ? Colors.green : colorScheme.error;
  
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (growth != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              growth,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}

// New helper method to build activity counts
Widget _buildActivityCount(
  ThemeData theme, {
  required int count,
  required String label,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// New helper method to build more minimal relation cards
Widget _buildRelationCard(
  ThemeData theme, {
  required String title,
  required IconData icon,
  required Color iconColor,
  required Customer customer,
  String? subtitle,
}) {
  return Card(
    margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: theme.colorScheme.outlineVariant.withOpacity(0.2),
      ),
    ),
    child: InkWell(
      onTap: () => CustomerDetailDialog.show(context, customer),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    customer.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (subtitle != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ),
  );
}

// New helper method to build recent activity items
List<Widget> _buildRecentActivity(ThemeData theme) {
  final activityItems = <Widget>[];
  final colorScheme = theme.colorScheme;
  
  // Sort items by date (measurements and invoices combined)
  final allItems = <dynamic>[];
  allItems.addAll(_measurements);
  allItems.addAll(_invoices);
  
  allItems.sort((a, b) {
    final DateTime dateA = a is Measurement ? a.date : (a as Invoice).date;
    final DateTime dateB = b is Measurement ? b.date : (b as Invoice).date;
    return dateB.compareTo(dateA); // Sort newest to oldest
  });
  
  // Take only the 5 most recent items
  final recentItems = allItems.take(5).toList();
  
  // Build list items
  for (final item in recentItems) {
    if (item is Measurement) {
      activityItems.add(
        ListTile(
          onTap: () => _viewMeasurement(item),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.tertiary.withOpacity(0.1),
            child: Icon(Icons.straighten, color: colorScheme.tertiary, size: 18),
          ),
          title: Text(
            'Measurement: ${item.style}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Design: ${item.designType}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat.yMMMd().format(item.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (item is Invoice) {
      // Choose color based on payment status
      Color statusColor;
      if (item.paymentStatus == 'paid') {
        statusColor = Colors.green;
      } else if (item.paymentStatus == 'partial') {
        statusColor = Colors.orange;
      } else {
        statusColor = colorScheme.error;
      }
      
      activityItems.add(
        ListTile(
          onTap: () => _viewInvoice(item),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.secondary.withOpacity(0.1),
            child: Icon(Icons.receipt, color: colorScheme.secondary, size: 18),
          ),
          title: Row(
            children: [
              Text(
                'Invoice #${item.invoiceNumber}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.paymentStatus.toString().split('.').last.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            NumberFormatter.formatCurrency(item.amountIncludingVat),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat.yMMMd().format(item.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Add divider between items except after the last item
    if (item != recentItems.last) {
      activityItems.add(const Divider(height: 1, indent: 16, endIndent: 16));
    }
  }
  
  if (allItems.length > 5) {
    // Add "View All" button
    activityItems.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: OutlinedButton.icon(
          onPressed: () {
            // Navigate to first tab with measurements, since it's the most likely to be used
            _tabController.animateTo(1);
          },
          icon: const Icon(Icons.history),
          label: const Text('View All Activity'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ),
    );
  }
  
  return activityItems;
}

// ...existing code...

Widget _buildInfoRow(ThemeData theme, {
  required IconData icon,
  required String label,
  required String value,
  VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    ),
  );
}



  Widget _buildTagChip(
    ThemeData theme,
    String label,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionLink(ThemeData theme, {
  required String title,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    ),
  );
}



  Widget _buildHeaderSection(ThemeData theme, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isDesktop ? 28 : 0),
          topRight: Radius.circular(isDesktop ? 28 : 0),
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.customer.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isDesktop) ...[
                FilledButton.tonalIcon(
                  onPressed: _addMeasurement,
                  icon: const Icon(Icons.straighten),
                  label: const Text('Add Measurement'),
                ),
                const SizedBox(width: 16),
                FilledButton.tonalIcon(
                  onPressed: _addInvoice,
                  icon: const Icon(Icons.receipt),
                  label: const Text('Create Invoice'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                theme,
                label: 'Bill #${widget.customer.billNumber}',
                icon: Icons.receipt_outlined,
                onTap: _copyBillNumber,
              ),
              _buildInfoChip(
                theme,
                label: widget.customer.phone,
                icon: Icons.phone_outlined,
                onTap: _copyPhone,
              ),
              _buildInfoChip(
                theme,
                label: widget.customer.gender == Gender.male ? 'Male' : 'Female',
                icon: widget.customer.gender == Gender.male 
                    ? Icons.male_outlined 
                    : Icons.female_outlined,
              ),
              if (isDesktop && !_isLoading) ...[
                _buildInfoChip(
                  theme,
                  label: '${_measurements.length} Measurements',
                  icon: Icons.straighten_outlined,
                ),
                _buildInfoChip(
                  theme,
                  label: '${_invoices.length} Invoices',
                  icon: Icons.receipt_long_outlined,
                ),
                if (_totalSpent > 0)
                  _buildInfoChip(
                    theme,
                    label: NumberFormatter.formatCurrency(_totalSpent.toDouble()),
                    icon: Icons.payments_outlined,
                    color: theme.colorScheme.tertiary,
                  ),
                if (_pendingPayments > 0)
                  _buildInfoChip(
                    theme,
                    label: 'Due: ${NumberFormatter.formatCurrency(_pendingPayments.toDouble())}',
                    icon: Icons.pending_outlined,
                    color: theme.colorScheme.error,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(ThemeData theme) {
    final brightness = theme.brightness;
    
    return Container(
      color: brightness == Brightness.light
          ? theme.colorScheme.surfaceContainerLowest
          : theme.colorScheme.surfaceContainerLow,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Contact Information
          _buildInfoSection(
            theme,
            title: 'Contact Information',
            icon: Icons.contact_phone_outlined,
            children: [
              _buildContactItem(
                theme,
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: widget.customer.address,
              ),
              if (widget.customer.whatsapp.isNotEmpty)
                _buildContactItem(
                  theme,
                  icon: Icons.whatshot_outlined,
                  label: 'WhatsApp',
                  value: widget.customer.whatsapp,
                  onTap: _sendWhatsApp,
                ),
            ],
          ),
          
          // Financial Summary
          if (!_isLoading)
            _buildInfoSection(
              theme,
              title: 'Financial Summary',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                _buildInfoStat(
                  theme,
                  label: 'Total Spent',
                  value: NumberFormatter.formatCurrency(_totalSpent.toDouble()),
                  icon: Icons.payments_outlined,
                  color: theme.colorScheme.tertiary,
                ),
                _buildInfoStat(
                  theme,
                  label: 'Due Payments',
                  value: NumberFormatter.formatCurrency(_pendingPayments.toDouble()),
                  icon: Icons.pending_actions_outlined,
                  color: _pendingPayments > 0 ? theme.colorScheme.error : null,
                ),
                _buildInfoStat(
                  theme,
                  label: 'Total Invoices',
                  value: '${_invoices.length}',
                  icon: Icons.receipt_long_outlined,
                ),
                _buildInfoStat(
                  theme,
                  label: 'Measurements',
                  value: '${_measurements.length}',
                  icon: Icons.straighten_outlined,
                ),
              ],
            ),
            
          // Referral Information
          if (!_isLoading && (_referredBy != null || _referrals.isNotEmpty))
            _buildInfoSection(
              theme,
              title: 'Referral Information',
              icon: Icons.people_alt_outlined,
              children: [
                if (_referredBy != null)
                  _buildReferralItem(
                    theme,
                    title: 'Referred by',
                    customer: _referredBy!,
                  ),
                if (_referrals.isNotEmpty)
                  _buildInfoStat(
                    theme,
                    label: 'Referred Customers',
                    value: '${_referrals.length}',
                    icon: Icons.person_add_alt_outlined,
                  ),
              ],
            ),
            
          // Family Information
          if (!_isLoading && (_familyHead != null || _familyMembers.isNotEmpty))
            _buildInfoSection(
              theme,
              title: 'Family Information',
              icon: Icons.family_restroom_outlined,
              children: [
                if (_familyHead != null)
                  _buildFamilyItem(
                    theme,
                    title: 'Family Head',
                    customer: _familyHead!,
                    relation: widget.customer.familyRelationDisplay,
                  ),
                if (_familyMembers.isNotEmpty)
                  _buildInfoStat(
                    theme,
                    label: 'Family Members',
                    value: '${_familyMembers.length}',
                    icon: Icons.family_restroom_outlined,
                  ),
              ],
            ),
          
          // Quick Actions
          _buildQuickActionsSection(theme),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, {
    required String label,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final chipColor = color ?? theme.colorScheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: chipColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: chipColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: chipColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildActionButton(
                theme,
                label: 'Call',
                icon: Icons.phone,
                color: theme.colorScheme.primary,
                onTap: _callCustomer,
              ),
              _buildActionButton(
                theme,
                label: 'WhatsApp',
                icon: Icons.chat,
                color: const Color(0xFF25D366), // WhatsApp green
                onTap: _sendWhatsApp,
              ),
              _buildActionButton(
                theme,
                label: 'New Measurement',
                icon: Icons.straighten,
                color: theme.colorScheme.tertiary,
                onTap: _addMeasurement,
              ),
              _buildActionButton(
                theme,
                label: 'Create Invoice',
                icon: Icons.receipt,
                color: theme.colorScheme.secondary,
                onTap: _addInvoice,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      icon: Icon(icon, size: 20),
      text: label,
      iconMargin: const EdgeInsets.only(bottom: 4),
      height: 56,
    );
  }

  Widget _buildContactItem(ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStat(ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final displayColor = color ?? theme.colorScheme.onSurfaceVariant;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: displayColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: displayColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: displayColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralItem(ThemeData theme, {
    required String title,
    required Customer customer,
  }) {
    return InkWell(
      onTap: () => CustomerDetailDialog.show(context, customer),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.secondaryContainer,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                customer.name[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    customer.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '#${customer.billNumber} · ${customer.phone}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyItem(ThemeData theme, {
    required String title,
    required Customer customer,
    required String relation,
  }) {
    return InkWell(
      onTap: () => CustomerDetailDialog.show(context, customer),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.tertiaryContainer,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.tertiaryContainer,
              child: Text(
                customer.name[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          relation,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    customer.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '#${customer.billNumber} · ${customer.phone}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsTab(ThemeData theme) {
    if (_measurements.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.straighten_rounded,
        title: 'No Measurements',
        description: 'Add a measurement for this customer.',
        actionLabel: 'Add Measurement',
        onAction: _addMeasurement,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _measurements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final measurement = _measurements[index];
        return _buildMeasurementCard(theme, measurement);
      },
    );
  }

  Widget _buildMeasurementCard(ThemeData theme, Measurement measurement) {
    final formattedDate = DateFormat.yMMMd().format(measurement.date);
    final brightness = theme.brightness;
    final cardColor = brightness == Brightness.light
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHigh;
    
    return Card(
      margin: EdgeInsets.zero,
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewMeasurement(measurement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.tertiary.withOpacity(0.2),
                    child: Icon(
                      Icons.straighten,
                      color: theme.colorScheme.tertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Style: ${measurement.style}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Design: ${measurement.designType}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (measurement.fabricName.isNotEmpty)
                              Expanded(
                                child: Text(
                                  'Fabric: ${measurement.fabricName}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: _buildMeasurementDetails(theme, measurement),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMeasurementDetails(ThemeData theme, Measurement measurement) {
    final details = <Widget>[];
    
    // Only show the first 5 most important measurements
    if (measurement.style == 'Emirati') {
      details.add(_buildMeasurementDetail(theme, 'Length', '${measurement.lengthArabi}'));
    } else {
      details.add(_buildMeasurementDetail(theme, 'Length', '${measurement.lengthKuwaiti}'));
    }
    
    details.add(_buildMeasurementDetail(theme, 'Chest', '${measurement.chest}'));
    details.add(_buildMeasurementDetail(theme, 'Width', '${measurement.width}'));
    details.add(_buildMeasurementDetail(theme, 'Sleeve', '${measurement.sleeve}'));
    details.add(_buildMeasurementDetail(theme, 'Collar', '${measurement.collar}'));
    
    return details;
  }

  Widget _buildMeasurementDetail(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab(ThemeData theme) {
    if (_invoices.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.receipt_long_rounded,
        title: 'No Invoices',
        description: 'Create an invoice for this customer.',
        actionLabel: 'Create Invoice',
        onAction: _addInvoice,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        return _buildInvoiceCard(theme, invoice);
      },
    );
  }

  Widget _buildInvoiceCard(ThemeData theme, Invoice invoice) {
    final formattedDate = DateFormat.yMMMd().format(invoice.date);
    final formattedDeliveryDate = DateFormat.yMMMd().format(invoice.deliveryDate);
    final brightness = theme.brightness;
    final cardColor = brightness == Brightness.light
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHigh;
    
    // Choose color based on payment status
    Color statusColor;
    if (invoice.paymentStatus == 'paid') {
      statusColor = Colors.green;
    } else if (invoice.paymentStatus == 'partial') {
      statusColor = Colors.orange;
    } else {
      statusColor = theme.colorScheme.error;
    }

    // Choose color for delivery status
    Color deliveryStatusColor;
    if (invoice.deliveryStatus == 'delivered') {
      deliveryStatusColor = Colors.green;
    } else if (invoice.deliveryStatus == 'in_progress') {
      deliveryStatusColor = Colors.orange;
    } else {
      deliveryStatusColor = theme.colorScheme.primary;
    }
    
    return Card(
      margin: EdgeInsets.zero,
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewInvoice(invoice),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                    child: Icon(
                      Icons.receipt,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INV-${invoice.invoiceNumber}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormatter.formatCurrency(invoice.amountIncludingVat),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInvoiceStatusChip(
                    theme,
                    label: invoice.paymentStatus.toString().split('.').last.toUpperCase(),
                    color: statusColor,
                  ),
                  _buildInvoiceStatusChip(
                    theme,
                    label: invoice.deliveryStatus.toString().split('.').last.toUpperCase(),
                    color: deliveryStatusColor,
                  ),
                  Text(
                    'Delivery: $formattedDeliveryDate',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildInvoiceStatusChip(ThemeData theme, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFamilyTab(ThemeData theme) {
    if (_familyMembers.isEmpty && _familyHead == null) {
      return _buildEmptyState(
        theme,
        icon: Icons.family_restroom_rounded,
        title: 'No Family Connections',
        description: 'Edit the customer to add family relationships.',
        actionLabel: 'Edit Customer',
        onAction: _editCustomer,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_familyHead != null) ...[
          _buildFamilySection(
            theme, 
            title: 'Family Head', 
            members: [_familyHead!],
            relations: {_familyHead!.id: widget.customer.familyRelationDisplay},
          ),
        ],
        if (_familyMembers.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildFamilySection(
            theme, 
            title: 'Family Members', 
            members: _familyMembers,
            relations: {
              for (var member in _familyMembers) 
                member.id: member.familyRelationDisplay
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFamilySection(ThemeData theme, {
    required String title,
    required List<Customer> members,
    required Map<String, String> relations,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...members.map((member) => _buildFamilyMemberCard(theme, member, relations[member.id] ?? '')),
      ],
    );
  }

  Widget _buildFamilyMemberCard(ThemeData theme, Customer member, String relation) {
    final brightness = theme.brightness;
    final cardColor = brightness == Brightness.light
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHigh;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => CustomerDetailDialog.show(context, member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.tertiary.withOpacity(0.2),
                child: Text(
                  member.name[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${member.billNumber} · ${member.phone}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  relation,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralsTab(ThemeData theme) {
    final List<Widget> content = [];

    if (_referredBy != null) {
      content.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Referred By',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            _buildReferralCard(theme, _referredBy!),
          ],
        ),
      );
    }

    if (_referrals.isNotEmpty) {
      if (content.isNotEmpty) {
        content.add(const SizedBox(height: 24));
      }
      
      content.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Customers Referred',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._referrals.map((customer) => _buildReferralCard(theme, customer)),
          ],
        ),
      );
    }

    if (content.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.people_alt_rounded,
        title: 'No Referrals',
        description: 'Edit the customer to add referral relationships.',
        actionLabel: 'Edit Customer',
        onAction: _editCustomer,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: content,
    );
  }

  Widget _buildReferralCard(ThemeData theme, Customer customer) {
    final brightness = theme.brightness;
    final cardColor = brightness == Brightness.light
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHigh;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => CustomerDetailDialog.show(context, customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${customer.billNumber} · ${customer.phone}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildComplaintsTab(ThemeData theme) {
    if (_complaints.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.report_problem_rounded,
        title: 'No Complaints',
        description: 'This customer has no complaints.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _complaints.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final complaint = _complaints[index];
        return _buildComplaintCard(theme, complaint);
      },
    );
  }

  Widget _buildComplaintCard(ThemeData theme, Complaint complaint) {
    final formattedDate = DateFormat.yMMMd().format(complaint.createdAt);
    final brightness = theme.brightness;
    final cardColor = brightness == Brightness.light
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHigh;
    
    return Card(
      margin: EdgeInsets.zero,
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewComplaint(complaint),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.error.withOpacity(0.2),
                    child: Icon(
                      Icons.report_problem,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Complaint #${complaint.id}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildComplaintStatusChip(
                    theme,
                    label: complaint.status.toString().split('.').last.toUpperCase(),
                    color: theme.colorScheme.error,
                  ),
                  Text(
                    'Assigned to: ${complaint.assignedTo}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildComplaintStatusChip(ThemeData theme, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

void _showActionSheet(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Add New',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const Divider(),
          
          // Actions
          _buildActionItem(
            context,
            icon: Icons.straighten,
            iconColor: colorScheme.primary,
            label: 'New Measurement',
            description: 'Add customer measurements',
            onTap: () {
              Navigator.pop(context);
              _addMeasurement();
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.receipt_long,
            iconColor: colorScheme.secondary,
            label: 'Create Invoice',
            description: 'Generate new invoice',
            onTap: () {
              Navigator.pop(context);
              _addInvoice();
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.report_problem_outlined,
            iconColor: colorScheme.error,
            label: 'Register Complaint',
            description: 'Record customer complaint',
            onTap: () {
              Navigator.pop(context);
              _addComplaint(); // Update this line
            },
          ),
          
          // Bottom padding for safe area
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _buildActionItem(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String label,
  required String description,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    ),
  );
}

Future<void> _addComplaint() async {
  await ComplaintDialog.show(
    context,
    customerId: widget.customer.id,
    customerName: widget.customer.name,
  );
  
  // Reload complaints after adding
  final complaints = await _complaintService.getComplaintsByCustomerId(widget.customer.id);
  setState(() => _complaints = complaints);
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    }

    return _buildMobileLayout(context);
  }
}