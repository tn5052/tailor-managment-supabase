import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../theme/inventory_design_config.dart';
import 'desktop/add_invoice_desktop_dialog.dart';
import 'desktop/invoice_details_dialog_desktop.dart';
import 'invoice_card.dart';

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
  ViewType _viewType = ViewType.table;

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
      // If using stream
      final invoices = await _invoiceService.getInvoicesStream().first;

      // Alternative if using regular method
      // final invoices = await _invoiceService.getAllInvoices();

      // Apply filters if search query exists
      final filtered = _filterInvoices(invoices);

      // Safely check if mounted before setting state
      if (!mounted) return;
      setState(() {
        _invoices = filtered;
        _isLoading = false;
      });
    } catch (e) {
      // Safety check before setting state
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading invoices: $e'),
          backgroundColor: InventoryDesignConfig.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                        _buildViewSwitcher(),
                        const SizedBox(width: 12),
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
                child:
                    _isLoading
                        ? _buildLoadingState()
                        : _viewType == ViewType.table
                        ? _buildInvoiceTable()
                        : _buildInvoiceGrid(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 320, // Increased width for better usability
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
          hintText: 'Search by invoice #, customer, phone, bill #...',
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
                      _onSearchChanged('');
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  void _onSearchChanged(String text) {
    setState(() {
      _searchQuery = text;
    });
    _loadInvoices();
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

  Widget _buildInvoiceGrid() {
    if (_invoices.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 4;
        if (width < 1200) {
          crossAxisCount = 3;
        }
        if (width < 900) {
          crossAxisCount = 2;
        }
        if (width < 600) {
          crossAxisCount = 1;
        }
        return GridView.builder(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.2,
            mainAxisSpacing: InventoryDesignConfig.spacingL,
            crossAxisSpacing: InventoryDesignConfig.spacingL,
          ),
          itemCount: _invoices.length,
          itemBuilder: (context, index) {
            final invoice = _invoices[index];
            return InvoiceCard(
              invoice: invoice,
              onTap: () => _showInvoiceDetails(invoice),
              onEdit: () => _handleEditInvoice(invoice),
              onDelete: () => _handleDeleteInvoice(invoice),
              isGridView: true,
            );
          },
        );
      },
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
      final query = _searchQuery.toLowerCase().trim();
      filtered =
          filtered.where((invoice) {
            // Search by invoice number
            if (invoice.invoiceNumber.toLowerCase().contains(query)) {
              return true;
            }

            // Search by customer name
            if (invoice.customerName.toLowerCase().contains(query)) {
              return true;
            }

            // Search by customer phone
            if (invoice.customerPhone.toLowerCase().contains(query)) {
              return true;
            }

            // Search by customer bill number
            if (invoice.customerBillNumber.toLowerCase().contains(query)) {
              return true;
            }

            // Search by measurement name (if exists)
            if (invoice.measurementName != null &&
                invoice.measurementName!.toLowerCase().contains(query)) {
              return true;
            }

            // Search by delivery status
            if (invoice.deliveryStatus
                .toString()
                .split('.')
                .last
                .toLowerCase()
                .contains(query)) {
              return true;
            }

            // Search by payment status
            if (invoice.paymentStatus
                .toString()
                .split('.')
                .last
                .toLowerCase()
                .contains(query)) {
              return true;
            }

            // Search by details (if exists)
            if (invoice.details.toLowerCase().contains(query)) {
              return true;
            }

            return false;
          }).toList();
    }

    // Apply other filters here (status, date range, etc.)
    // ...existing filter logic...

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
    InvoiceDetailsDialogDesktop.show(
      context,
      invoice,
      onUpdated: _loadInvoices,
    );
  }

  void _handleEditInvoice(Invoice invoice) {
    AddInvoiceDesktopDialog.show(
      context,
      invoice: invoice,
      onInvoiceAdded: _loadInvoices,
    );
  }

  void _handleDeleteInvoice(Invoice invoice) async {
    final confirm = await _showDeleteConfirmationDialog(invoice);
    if (confirm != true) return;

    try {
      await _invoiceService.deleteInvoice(invoice.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice #${invoice.invoiceNumber} deleted successfully',
          ),
          backgroundColor: InventoryDesignConfig.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadInvoices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting invoice: ${e.toString()}'),
          backgroundColor: InventoryDesignConfig.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(Invoice invoice) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  PhosphorIcons.warning(PhosphorIconsStyle.fill),
                  color: InventoryDesignConfig.errorColor,
                  size: 24,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  'Confirm Deletion',
                  style: InventoryDesignConfig.titleLarge,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this invoice?',
                  style: InventoryDesignConfig.bodyLarge,
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.errorColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color: InventoryDesignConfig.errorColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.receipt(),
                        color: InventoryDesignConfig.errorColor,
                        size: 16,
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingS),
                      Expanded(
                        child: Text(
                          '#${invoice.invoiceNumber}',
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            color: InventoryDesignConfig.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                Text(
                  'This action cannot be undone.',
                  style: InventoryDesignConfig.bodyMedium,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: InventoryDesignConfig.bodyMedium),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(PhosphorIcons.trash()),
                label: const Text('Delete'),
                style: FilledButton.styleFrom(
                  backgroundColor: InventoryDesignConfig.errorColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  void _showFilterDialog() {
    // TODO: Implement filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter functionality coming soon!')),
    );
  }

  Widget _buildViewSwitcher() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: InventoryDesignConfig.borderPrimary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewButton(ViewType.table, PhosphorIcons.table(), 'Table'),
          _buildViewButton(ViewType.grid, PhosphorIcons.gridFour(), 'Grid'),
        ],
      ),
    );
  }

  Widget _buildViewButton(ViewType viewType, IconData icon, String label) {
    final isSelected = _viewType == viewType;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _viewType = viewType),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? InventoryDesignConfig.surfaceColor
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isSelected
                        ? InventoryDesignConfig.primaryColor
                        : InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected
                          ? InventoryDesignConfig.textPrimary
                          : InventoryDesignConfig.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
