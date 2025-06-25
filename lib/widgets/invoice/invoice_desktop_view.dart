import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../theme/inventory_design_config.dart';
import 'invoice_details_dialog.dart';
import 'desktop/add_invoice_desktop_dialog.dart';

enum ViewType { grid, table }

class InvoiceDesktopView extends StatefulWidget {
  const InvoiceDesktopView({super.key});

  @override
  State<InvoiceDesktopView> createState() => _InvoiceDesktopViewState();
}

class _InvoiceDesktopViewState extends State<InvoiceDesktopView> {
  final InvoiceService _invoiceService = InvoiceService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Invoice> _invoices = [];
  String _sortColumn = 'date';
  bool _sortAscending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final invoicesStream = _invoiceService.getInvoicesStream();
      final invoices = await invoicesStream.first;

      setState(() {
        _invoices = _filterInvoices(invoices);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading invoices: $e'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
    _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.backgroundColor,
      ),
      child: Column(
        children: [
          // Header section matching inventory/measurement design
          Container(
            decoration: const BoxDecoration(
              color: InventoryDesignConfig.backgroundColor,
            ),
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
            child: Column(
              children: [
                // Main header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: InventoryDesignConfig.primaryColor
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            PhosphorIcons.receipt(PhosphorIconsStyle.fill),
                            size: 22,
                            color: InventoryDesignConfig.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice Management',
                              style: InventoryDesignConfig.headlineLarge
                                  .copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                            Text(
                              'Manage your invoice records',
                              style: InventoryDesignConfig.bodyMedium.copyWith(
                                fontSize: 13,
                                color: InventoryDesignConfig.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Right side controls
                    Row(
                      children: [
                        _buildSearchField(),
                        const SizedBox(width: 12),
                        _buildModernSecondaryButton(
                          icon: PhosphorIcons.funnel(),
                          label: 'Filter',
                          onPressed: _showFilterDialog,
                        ),
                        const SizedBox(width: 12),
                        _buildModernPrimaryButton(
                          icon: PhosphorIcons.plus(),
                          label: 'Create Invoice',
                          onPressed: () {
                            AddInvoiceDesktopDialog.show(
                              context,
                              onInvoiceAdded: _loadInvoices,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats row
                _buildModernStatsRow(),
              ],
            ),
          ),

          // Table container
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: InventoryDesignConfig.backgroundColor,
              ),
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Container(
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceColor,
                  border: Border.all(
                    color: InventoryDesignConfig.borderPrimary,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isLoading ? _buildLoadingState() : _buildInvoiceTable(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 280,
      height: 40,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: InventoryDesignConfig.bodyLarge.copyWith(
          fontSize: 14,
          color: InventoryDesignConfig.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search invoices...',
          hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
            color: InventoryDesignConfig.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              PhosphorIcons.magnifyingGlass(),
              size: 16,
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      PhosphorIcons.x(),
                      size: 14,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadInvoices();
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _loadInvoices();
        },
      ),
    );
  }

  Widget _buildModernPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: InventoryDesignConfig.buttonPrimaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: InventoryDesignConfig.buttonSecondaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: InventoryDesignConfig.textSecondary),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatsRow() {
    final totalInvoices = _invoices.length;
    final paidInvoices =
        _invoices
            .where((i) => i.paymentStatus.name.toLowerCase() == 'paid')
            .length;
    final pendingInvoices =
        _invoices
            .where((i) => i.paymentStatus.name.toLowerCase() == 'pending')
            .length;
    final totalAmount = _invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.netTotal,
    );

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Row(
        children: [
          _buildModernStatCard(
            title: 'Total Invoices',
            value: totalInvoices.toString(),
            icon: PhosphorIcons.receipt(),
            color: InventoryDesignConfig.primaryAccent,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Paid',
            value: paidInvoices.toString(),
            icon: PhosphorIcons.checkCircle(),
            color: InventoryDesignConfig.successColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Pending',
            value: pendingInvoices.toString(),
            icon: PhosphorIcons.clock(),
            color: InventoryDesignConfig.warningColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Total Value',
            value: 'AED ${totalAmount.toStringAsFixed(0)}',
            icon: PhosphorIcons.currencyDollar(),
            color: InventoryDesignConfig.infoColor,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingM,
              vertical: InventoryDesignConfig.spacingXS,
            ),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.receipt(),
                  size: 14,
                  color: InventoryDesignConfig.primaryColor,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingXS),
                Text(
                  'Invoice Management',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: InventoryDesignConfig.headlineMedium),
            Text(title, style: InventoryDesignConfig.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceTable() {
    if (_invoices.isEmpty) {
      return _buildEmptyState();
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(
            InventoryDesignConfig.surfaceAccent,
          ),
          dataRowColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.hovered)) {
              return InventoryDesignConfig.surfaceLight;
            }
            return InventoryDesignConfig.surfaceColor;
          }),
          headingTextStyle: InventoryDesignConfig.labelLarge,
          dataTextStyle: InventoryDesignConfig.bodyLarge,
          dividerThickness: 1,
          horizontalMargin: InventoryDesignConfig.spacingXXL,
          columnSpacing: InventoryDesignConfig.spacingXXXL,
          headingRowHeight: 52,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
        ),
      ),
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            showCheckboxColumn: false,
            border: TableBorder(
              horizontalInside: BorderSide(
                color: InventoryDesignConfig.borderSecondary,
              ),
            ),
            columns: [
              _buildDataColumn('Invoice', 'invoice_number'),
              _buildDataColumn('Customer', 'customer_name'),
              _buildDataColumn('Amount', 'net_total'),
              _buildDataColumn('Payment', 'payment_status'),
              _buildDataColumn('Delivery', 'delivery_status'),
              _buildDataColumn('Date', 'date'),
              const DataColumn(label: Text('')), // Actions
            ],
            rows:
                _invoices.map((invoice) => _buildInvoiceRow(invoice)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildInvoiceRow(Invoice invoice) {
    return DataRow(
      cells: [
        DataCell(_buildInvoiceCell(invoice)),
        DataCell(_buildCustomerCell(invoice)),
        DataCell(_buildAmountCell(invoice.netTotal)),
        DataCell(_buildStatusBadge(invoice.paymentStatus)),
        DataCell(_buildDeliveryStatusBadge(invoice.deliveryStatus)),
        DataCell(_buildDateCell(invoice.date)),
        DataCell(_buildActionsCell(invoice)),
      ],
      onSelectChanged: (selected) {
        if (selected == true) _showInvoiceDetails(invoice);
      },
    );
  }

  Widget _buildInvoiceCell(Invoice invoice) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      ),
      child: Text(
        'INV-${invoice.invoiceNumber}',
        style: InventoryDesignConfig.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCustomerCell(Invoice invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          invoice.customerName,
          style: InventoryDesignConfig.bodyLarge,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Bill #${invoice.customerBillNumber}',
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCell(double amount) {
    return Text(
      NumberFormat.currency(symbol: 'AED ').format(amount),
      style: InventoryDesignConfig.titleMedium.copyWith(
        color: InventoryDesignConfig.primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStatusBadge(dynamic status) {
    String statusStr = status is Enum ? status.name : status.toString();
    Color color;
    Color backgroundColor;

    switch (statusStr.toLowerCase()) {
      case 'paid':
        color = InventoryDesignConfig.successColor;
        backgroundColor = InventoryDesignConfig.successColor.withOpacity(0.1);
        break;
      case 'partial':
        color = InventoryDesignConfig.warningColor;
        backgroundColor = InventoryDesignConfig.warningColor.withOpacity(0.1);
        break;
      case 'pending':
        color = InventoryDesignConfig.errorColor;
        backgroundColor = InventoryDesignConfig.errorColor.withOpacity(0.1);
        break;
      default:
        color = InventoryDesignConfig.textSecondary;
        backgroundColor = InventoryDesignConfig.surfaceAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      ),
      child: Text(
        statusStr.toUpperCase(),
        style: InventoryDesignConfig.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDeliveryStatusBadge(dynamic status) {
    String statusStr = status is Enum ? status.name : status.toString();
    Color color;
    Color backgroundColor;

    switch (statusStr.toLowerCase()) {
      case 'delivered':
        color = InventoryDesignConfig.successColor;
        backgroundColor = InventoryDesignConfig.successColor.withOpacity(0.1);
        break;
      case 'ready':
        color = InventoryDesignConfig.infoColor;
        backgroundColor = InventoryDesignConfig.infoColor.withOpacity(0.1);
        break;
      case 'in_progress':
        color = InventoryDesignConfig.warningColor;
        backgroundColor = InventoryDesignConfig.warningColor.withOpacity(0.1);
        break;
      default:
        color = InventoryDesignConfig.textSecondary;
        backgroundColor = InventoryDesignConfig.surfaceAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      ),
      child: Text(
        statusStr.replaceAll('_', ' ').toUpperCase(),
        style: InventoryDesignConfig.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateCell(DateTime date) {
    return Text(
      DateFormat('MMM d, y').format(date),
      style: InventoryDesignConfig.bodyLarge,
    );
  }

  Widget _buildActionsCell(Invoice invoice) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionIcon(
          icon: PhosphorIcons.eye(),
          onTap: () => _showInvoiceDetails(invoice),
          color: InventoryDesignConfig.infoColor,
          tooltip: 'View Details',
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        _buildActionIcon(
          icon: PhosphorIcons.pencilSimple(),
          onTap: () => _handleEditInvoice(invoice),
          color: InventoryDesignConfig.primaryAccent,
          tooltip: 'Edit Invoice',
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        _buildActionIcon(
          icon: PhosphorIcons.trash(),
          onTap: () => _handleDeleteInvoice(invoice),
          color: InventoryDesignConfig.errorColor,
          tooltip: 'Delete Invoice',
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    String? tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        child: Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          ),
          child: Tooltip(
            message: tooltip ?? '',
            child: Icon(icon, size: 16, color: color),
          ),
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
                InventoryDesignConfig.radiusXL,
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
            'Loading invoices...',
            style: InventoryDesignConfig.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          Text(
            'No invoices found',
            style: InventoryDesignConfig.headlineMedium,
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search criteria'
                : 'Get started by creating your first invoice',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          _buildModernPrimaryButton(
            icon: PhosphorIcons.plus(),
            label: 'Create Invoice',
            onPressed: () {
              // TODO: Implement create invoice
            },
          ),
        ],
      ),
    );
  }

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    var filtered = invoices;

    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (invoice) =>
                    invoice.customerName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    invoice.invoiceNumber.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    invoice.customerBillNumber.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    return filtered;
  }

  DataColumn _buildDataColumn(String label, String column) {
    final isSorted = _sortColumn == column;
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase()),
          if (isSorted) ...[
            const SizedBox(width: InventoryDesignConfig.spacingXS),
            Icon(
              _sortAscending
                  ? PhosphorIcons.caretUp()
                  : PhosphorIcons.caretDown(),
              size: 12,
              color: InventoryDesignConfig.primaryAccent,
            ),
          ],
        ],
      ),
      onSort: (_, __) => _onSort(column),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    InvoiceDetailsDialog.show(context, invoice);
  }

  void _handleEditInvoice(Invoice invoice) {
    // TODO: Implement edit invoice
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit invoice functionality coming soon!')),
    );
  }

  void _handleDeleteInvoice(Invoice invoice) {
    // TODO: Implement delete invoice with confirmation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delete invoice functionality coming soon!'),
      ),
    );
  }

  void _showFilterDialog() {
    // TODO: Implement filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter functionality coming soon!')),
    );
  }
}
