import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/inventory_design_config.dart';
import '../../models/invoice_filter.dart';
import 'mobile/add_edit_invoice_mobile_sheet.dart';
import 'mobile/invoice_detail_mobile_sheet.dart';
import 'mobile/invoice_filter_mobile_sheet.dart';

class InvoiceMobileView extends StatefulWidget {
  const InvoiceMobileView({super.key});

  @override
  State<InvoiceMobileView> createState() => _InvoiceMobileViewState();
}

class _InvoiceMobileViewState extends State<InvoiceMobileView>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  String _sortBy = 'created_at';
  bool _sortAscending = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _invoices = [];

  InvoiceFilter _filter = InvoiceFilter();
  bool _hasActiveFilters = false;

  bool _isSearchExpanded = false;
  AnimationController? _searchAnimationController;
  Animation<double>? _searchAnimation;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController!,
      curve: Curves.easeInOut,
    );
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchAnimationController?.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });

    if (_isSearchExpanded) {
      _searchAnimationController!.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    } else {
      _searchAnimationController!.reverse();
      _searchController.clear();
      setState(() => _searchQuery = '');
      _loadInvoices();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);

    try {
      var query = _supabase.from('invoices').select('''
            *,
            customers(id, name, phone)
          ''').eq('tenant_id', _supabase.auth.currentUser!.id);

      if (_searchQuery.isNotEmpty) {
        query = query.or(
          'invoice_number.ilike.%$_searchQuery%,customer_name.ilike.%$_searchQuery%,customer_phone.ilike.%$_searchQuery%',
        );
      }

      // Apply filters from _filter object
      // This part will be expanded when the filter sheet is implemented
      if (_filter.hasActiveFilters) {
        // Apply date range filters
        if (_filter.creationDateRange != null) {
          final startDate = _filter.creationDateRange!.start;
          final endDate = _filter.creationDateRange!.end;
          query = query.gte('date', startDate.toIso8601String().split('T')[0]);
          query = query.lte('date', endDate.toIso8601String().split('T')[0]);
        }
        if (_filter.dueDateRange != null) {
          final startDate = _filter.dueDateRange!.start;
          final endDate = _filter.dueDateRange!.end;
          query = query.gte('delivery_date', startDate.toIso8601String().split('T')[0]);
          query = query.lte('delivery_date', endDate.toIso8601String().split('T')[0]);
        }
        // Apply payment status filter
        if (_filter.paymentStatus.isNotEmpty) {
          final statusNames = _filter.paymentStatus.map((e) => e.name).toList();
          query = query.inFilter('payment_status', statusNames);
        }
      }
      final response = await query.order(_sortBy, ascending: _sortAscending);

      if (!mounted) return;

      setState(() {
        _invoices = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading invoices: ${e.toString()}'),
          backgroundColor: InventoryDesignConfig.errorColor,
        ),
      );
    }
  }

  void _updateActiveFiltersStatus() {
    setState(() {
      _hasActiveFilters = _filter.hasActiveFilters || _searchQuery.isNotEmpty;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _filter = InvoiceFilter();
      _searchController.clear();
      _searchQuery = '';
      _sortBy = 'created_at';
      _sortAscending = false;
      _hasActiveFilters = false;
    });
    _loadInvoices();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: true,
      builder:
          (context) => InvoiceFilterMobileSheet(
        initialFilter: _filter,
        onFilterApplied: (updatedFilter) {
          setState(() {
            _filter = updatedFilter;
          });
          _updateActiveFiltersStatus();
          _loadInvoices();
        },
      ),
    );
  }

  Future<void> _handleDeleteItem(Map<String, dynamic> item) async {
    final confirm = await _showDeleteConfirmationDialog(item);
    if (confirm != true) return;

    try {
      await _supabase.from('invoices').delete().eq('id', item['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice #${item['invoice_number']} deleted successfully',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _loadInvoices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting invoice: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final invoiceNumber = item['invoice_number'];

    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  PhosphorIcons.warning(PhosphorIconsStyle.fill),
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text('Confirm Deletion'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete invoice #$invoiceNumber?',
                ),
                const SizedBox(height: 12),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(PhosphorIcons.trash()),
                label: const Text('Delete'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
              ),
            ],
          ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    InvoiceDetailMobileSheet.show(
      context,
      invoice: item,
      onInvoiceUpdated: _loadInvoices,
      onInvoiceDeleted: () => _handleDeleteItem(item),
    );
  }

  void _showActionBottomSheet(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final invoiceNumber = item['invoice_number'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.receipt(),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Invoice #$invoiceNumber',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(PhosphorIcons.eye()),
                  title: const Text('View Details'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showItemDetails(item);
                  },
                ),
                ListTile(
                  leading: Icon(PhosphorIcons.pencilSimple()),
                  title: const Text('Edit Invoice'),
                  onTap: () {
                    Navigator.of(context).pop();
                    AddEditInvoiceMobileSheet.show(
                      context,
                      invoice: item,
                      onInvoiceSaved: _loadInvoices,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.trash(),
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete Invoice',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleDeleteItem(item);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: InventoryDesignConfig.backgroundColor,
      child: Column(
        children: [
          _buildModernAppBar(),
          _buildQuickStatsBar(),
          Expanded(child: _buildInvoiceList()),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top:
            MediaQuery.of(context).padding.top + InventoryDesignConfig.spacingS,
        left: InventoryDesignConfig.spacingL,
        right: InventoryDesignConfig.spacingL,
        bottom: InventoryDesignConfig.spacingM,
      ),
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: AnimatedBuilder(
        animation: _searchAnimation!,
        builder: (context, child) {
          return Row(
            children: [
              if (!_isSearchExpanded)
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(
                          InventoryDesignConfig.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: InventoryDesignConfig.primaryColor
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusS,
                          ),
                        ),
                        child: Icon(
                          PhosphorIcons.receipt(),
                          size: 18,
                          color: InventoryDesignConfig.primaryColor,
                        ),
                      ),
                      const SizedBox(
                        width: InventoryDesignConfig.spacingM,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoices',
                              style: InventoryDesignConfig.headlineMedium,
                            ),
                            Text(
                              'Manage invoices',
                              style:
                                  InventoryDesignConfig.bodySmall.copyWith(
                                color: InventoryDesignConfig.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isSearchExpanded)
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      border: Border.all(
                        color: InventoryDesignConfig.borderPrimary,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: InventoryDesignConfig.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Search invoices...',
                        hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.textTertiary,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(
                            InventoryDesignConfig.spacingM,
                          ),
                          child: Icon(
                            PhosphorIcons.magnifyingGlass(),
                            size: 18,
                            color: InventoryDesignConfig.textSecondary,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: InventoryDesignConfig.spacingM,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _loadInvoices();
                      },
                    ),
                  ),
                ),
              Row(
                children: [
                  if (_isSearchExpanded) ...[
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    _buildHeaderIconButton(
                      icon: PhosphorIcons.x(),
                      onTap: _toggleSearch,
                    ),
                  ] else ...[
                    _buildHeaderIconButton(
                      icon: PhosphorIcons.magnifyingGlass(),
                      onTap: _toggleSearch,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Stack(
                      children: [
                        _buildHeaderIconButton(
                          icon: PhosphorIcons.funnel(),
                          onTap: _showFilterBottomSheet,
                        ),
                        if (_hasActiveFilters)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: InventoryDesignConfig.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    _buildHeaderIconButton(
                      icon: PhosphorIcons.plus(),
                      onTap: () => AddEditInvoiceMobileSheet.show(
                        context,
                        onInvoiceSaved: _loadInvoices,
                      ),
                      isPrimary: true,
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickStatsBar() {
    final totalInvoices = _invoices.length;
    final pendingPayment =
        _invoices.where((inv) => inv['payment_status'] != 'Paid').length;
    final totalRevenue = _invoices.fold<double>(
        0.0, (sum, inv) => sum + (inv['amount_including_vat'] as num).toDouble());

    return Container(
      color: InventoryDesignConfig.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingL,
        vertical: InventoryDesignConfig.spacingM,
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: PhosphorIcons.receipt(),
            label: 'Total',
            value: '$totalInvoices',
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          _buildStatItem(
            icon: PhosphorIcons.warning(),
            label: 'Pending',
            value: '$pendingPayment',
            color: pendingPayment > 0
                ? InventoryDesignConfig.errorColor
                : InventoryDesignConfig.successColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          _buildStatItem(
            icon: PhosphorIcons.currencyDollar(),
            label: 'Revenue',
            value:
                NumberFormat.compactCurrency(symbol: '\$').format(totalRevenue),
            color: InventoryDesignConfig.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: InventoryDesignConfig.spacingXS),
                Expanded(
                  child: Text(
                    label,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXS),
            Text(
              value,
              style: InventoryDesignConfig.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPrimary
                ? InventoryDesignConfig.primaryColor
                : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color: isPrimary
                  ? InventoryDesignConfig.primaryColor
                  : InventoryDesignConfig.borderPrimary,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isPrimary
                ? InventoryDesignConfig.surfaceColor
                : InventoryDesignConfig.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: InventoryDesignConfig.primaryColor,
        ),
      );
    }

    if (_invoices.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: InventoryDesignConfig.primaryColor,
      onRefresh: _loadInvoices,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          InventoryDesignConfig.spacingL,
          InventoryDesignConfig.spacingS,
          InventoryDesignConfig.spacingL,
          InventoryDesignConfig.spacingXL,
        ),
        itemCount: _invoices.length,
        itemBuilder: (context, index) {
          final invoice = _invoices[index];
          return _buildInvoiceCard(invoice);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final paymentStatus = invoice['payment_status'] ?? 'Pending';
    final deliveryStatus = invoice['delivery_status'] ?? 'Pending';
    final invoiceNumber = invoice['invoice_number'] ?? 'N/A';
    final customerName = invoice['customer_name'] ?? 'No Customer';
    final amount = (invoice['amount_including_vat'] ?? 0.0) as double;
    final date = invoice['date'] != null
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(invoice['date']))
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        child: InkWell(
          onTap: () => _showItemDetails(invoice),
          onLongPress: () => _showActionBottomSheet(invoice),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INV #$invoiceNumber',
                            style: InventoryDesignConfig.titleMedium,
                          ),
                          const SizedBox(
                              height: InventoryDesignConfig.spacingXS),
                          Row(
                            children: [
                              Icon(PhosphorIcons.user(),
                                  size: 14,
                                  color: InventoryDesignConfig.textSecondary),
                              const SizedBox(
                                  width: InventoryDesignConfig.spacingXS),
                              Expanded(
                                child: Text(
                                  customerName,
                                  style: InventoryDesignConfig.bodyMedium
                                      .copyWith(
                                          color: InventoryDesignConfig
                                              .textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: '\$').format(amount),
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            color: InventoryDesignConfig.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          date,
                          style: InventoryDesignConfig.bodySmall.copyWith(
                            color: InventoryDesignConfig.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                Row(
                  children: [
                    _buildStatusChip(paymentStatus, _getPaymentStatusColor(paymentStatus)),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    _buildStatusChip(deliveryStatus, _getDeliveryStatusColor(deliveryStatus)),
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                      child: InkWell(
                        onTap: () => _showActionBottomSheet(invoice),
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(
                            InventoryDesignConfig.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: InventoryDesignConfig.surfaceLight,
                            borderRadius: BorderRadius.circular(
                              InventoryDesignConfig.radiusS,
                            ),
                            border: Border.all(
                              color: InventoryDesignConfig.borderPrimary,
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.dotsThreeVertical(),
                            size: 16,
                            color: InventoryDesignConfig.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          InventoryDesignConfig.radiusS,
        ),
      ),
      child: Text(
        status,
        style: InventoryDesignConfig.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                PhosphorIcons.receipt(),
                size: 48,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            Text('No invoices found',
                style: InventoryDesignConfig.headlineMedium),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term or clear filters'
                  : 'Add your first invoice to get started',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            if (_searchQuery.isNotEmpty)
              _buildEmptyStateButton(
                icon: PhosphorIcons.arrowClockwise(),
                label: 'Clear Search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _loadInvoices();
                },
                isPrimary: false,
              )
            else
              _buildEmptyStateButton(
                icon: PhosphorIcons.plus(),
                label: 'Create Invoice',
                onPressed: () => AddEditInvoiceMobileSheet.show(
                  context,
                  onInvoiceSaved: _loadInvoices,
                ),
                isPrimary: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingXL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: isPrimary
              ? InventoryDesignConfig.buttonPrimaryDecoration
              : InventoryDesignConfig.buttonSecondaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary
                    ? InventoryDesignConfig.surfaceColor
                    : InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: isPrimary
                      ? InventoryDesignConfig.surfaceColor
                      : InventoryDesignConfig.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return InventoryDesignConfig.successColor;
      case 'Partially Paid':
        return InventoryDesignConfig.warningColor;
      case 'Unpaid':
      case 'Pending':
      default:
        return InventoryDesignConfig.errorColor;
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return InventoryDesignConfig.successColor;
      case 'Processing':
        return InventoryDesignConfig.infoColor;
      case 'Cancelled':
        return InventoryDesignConfig.errorColor;
      case 'Pending':
      default:
        return InventoryDesignConfig.warningColor;
    }
  }
}
