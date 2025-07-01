import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/inventory_design_config.dart';
import '../../models/invoice_filter.dart';
import '../../models/invoice.dart';
import 'desktop/add_edit_invoice_desktop_dialog.dart';
import 'desktop/invoice_detail_dialog_desktop.dart';
import 'desktop/invoice_filter_dialog.dart';

class InvoiceDesktopView extends StatefulWidget {
  const InvoiceDesktopView({super.key});

  @override
  State<InvoiceDesktopView> createState() => _InvoiceDesktopViewState();
}

class _InvoiceDesktopViewState extends State<InvoiceDesktopView> {
  final _supabase = Supabase.instance.client;
  String _sortColumn = 'created_at';
  bool _sortAscending = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _invoices = [];
  InvoiceFilter _filter = InvoiceFilter();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);

    try {
      var query = _supabase
          .from('invoices')
          .select('''
            *,
            customers(id, name, phone)
          ''')
          .eq('tenant_id', _supabase.auth.currentUser!.id);

      if (_searchQuery.isNotEmpty) {
        query = query.or(
          'invoice_number.ilike.%$_searchQuery%,customer_name.ilike.%$_searchQuery%,customer_phone.ilike.%$_searchQuery%',
        );
      }

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
      if (_filter.modifiedDateRange != null) {
        final startDate = _filter.modifiedDateRange!.start;
        final endDate = _filter.modifiedDateRange!.end;
        query = query.gte('last_modified_at', startDate.toIso8601String());
        query = query.lte('last_modified_at', endDate.toIso8601String());
      }

      // Apply payment status filter
      if (_filter.paymentStatus.isNotEmpty) {
        final statusNames = _filter.paymentStatus.map((e) {
          switch (e.name) {
            case 'paid':
              return 'Paid';
            case 'unpaid':
              return 'Unpaid';
            case 'partial':
              return 'Partially Paid';
            case 'refunded':
              return 'Refunded';
            default:
              return e.name;
          }
        }).toList();
        query = query.inFilter('payment_status', statusNames);
      }

      // Apply delivery status filter
      if (_filter.deliveryStatus.isNotEmpty) {
        final statusNames = _filter.deliveryStatus.map((e) {
          switch (e.name) {
            case 'pending':
              return 'Pending';
            case 'inProgress':
              return 'Processing';
            case 'delivered':
              return 'Delivered';
            case 'cancelled':
              return 'Cancelled';
            default:
              return e.name;
          }
        }).toList();
        query = query.inFilter('delivery_status', statusNames);
      }

      // Apply amount range filter
      if (_filter.amountRange != null) {
        query = query.gte('amount_including_vat', _filter.amountRange!.start);
        query = query.lte('amount_including_vat', _filter.amountRange!.end);
      }

      // Apply overdue filter
      if (_filter.showOverdue) {
        final now = DateTime.now().toIso8601String();
        query = query.lt('delivery_date', now);
        query = query.neq('delivery_status', 'Delivered');
      }

      final response = await query.order(_sortColumn, ascending: _sortAscending);

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
          // Compact header section with title and controls
          Container(
            decoration: const BoxDecoration(
              color: InventoryDesignConfig.backgroundColor,
            ),
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
            child: Column(
              children: [
                // Main header row - compact design
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
                            PhosphorIcons.receipt(),
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
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: InventoryDesignConfig.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Manage customer invoices and orders',
                              style: GoogleFonts.inter(
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

                    // Right side controls - in a single row
                    Row(
                      children: [
                        _buildSearchField(),
                        const SizedBox(width: 12),
                        _buildModernFilterButton(),
                        const SizedBox(width: 12),
                        _buildModernPrimaryButton(
                          icon: PhosphorIcons.plus(),
                          label: 'Create Invoice',
                          onPressed: () {
                            AddEditInvoiceDesktopDialog.show(
                              context,
                              onInvoiceSaved: _loadInvoices,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Active filters display
                if (_filter.hasActiveFilters) _buildActiveFiltersDisplay(),
                if (_filter.hasActiveFilters) const SizedBox(height: 16),

                // Stats row - more compact
                _buildModernStatsRow(),
              ],
            ),
          ),

          // Table container with matching background
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
      height: 40, // Match button height
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: InventoryDesignConfig.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search invoices...',
          hintStyle: GoogleFonts.inter(
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
          suffixIcon: _searchQuery.isNotEmpty
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
          // Implement actual search logic here, possibly debounce
          _loadInvoices();
        },
      ),
    );
  }

  Widget _buildModernFilterButton() {
    final bool hasActiveFilters = _filter.hasActiveFilters;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: () async {
          final newFilter = await showDialog<InvoiceFilter>(
            context: context,
            builder: (context) => InvoiceFilterDialog(
              initialFilter: _filter,
              onFilterApplied: (filter) {
                setState(() {
                  _filter = filter;
                });
                _loadInvoices();
              },
            ),
          );
          if (newFilter != null) {
            setState(() {
              _filter = newFilter;
            });
            _loadInvoices();
          }
        },
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          height: 40, // Match other elements height
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: hasActiveFilters
              ? InventoryDesignConfig.buttonPrimaryDecoration.copyWith(
                  color: InventoryDesignConfig.primaryAccent.withOpacity(0.1),
                  border: Border.all(color: InventoryDesignConfig.primaryAccent),
                )
              : InventoryDesignConfig.buttonSecondaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.funnel(),
                size: 16,
                color: hasActiveFilters ? InventoryDesignConfig.primaryAccent : InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                'Filter',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: hasActiveFilters ? InventoryDesignConfig.primaryAccent : InventoryDesignConfig.textSecondary,
                ),
              ),
              if (hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.only(left: InventoryDesignConfig.spacingXS),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: InventoryDesignConfig.primaryAccent,
                  ),
                ),
            ],
          ),
        ),
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
          height: 40, // Match other elements height
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

  Widget _buildActiveFiltersDisplay() {
    final activeFilters = <Widget>[];

    // Date filters
    if (_filter.creationDateRange != null) {
      activeFilters.add(_buildActiveFilterChip(
        'Creation: ${DateFormat('MMM d, yyyy').format(_filter.creationDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_filter.creationDateRange!.end)}',
        () {
          setState(() {
            _filter = _filter.copyWith(creationDateRange: null);
          });
          _loadInvoices();
        },
      ));
    }
    if (_filter.dueDateRange != null) {
      activeFilters.add(_buildActiveFilterChip(
        'Due: ${DateFormat('MMM d, yyyy').format(_filter.dueDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_filter.dueDateRange!.end)}',
        () {
          setState(() {
            _filter = _filter.copyWith(dueDateRange: null);
          });
          _loadInvoices();
        },
      ));
    }

    // Payment status filters
    for (final status in _filter.paymentStatus) {
      activeFilters.add(_buildActiveFilterChip(
        'Payment: ${status.name}',
        () {
          setState(() {
            final newPaymentStatus = List<PaymentStatus>.from(_filter.paymentStatus);
            newPaymentStatus.remove(status);
            _filter = _filter.copyWith(paymentStatus: newPaymentStatus);
          });
          _loadInvoices();
        },
      ));
    }

    // Delivery status filters
    for (final status in _filter.deliveryStatus) {
      activeFilters.add(_buildActiveFilterChip(
        'Delivery: ${status.name}',
        () {
          setState(() {
            final newDeliveryStatus = List<InvoiceStatus>.from(_filter.deliveryStatus);
            newDeliveryStatus.remove(status);
            _filter = _filter.copyWith(deliveryStatus: newDeliveryStatus);
          });
          _loadInvoices();
        },
      ));
    }

    // Amount range filter
    if (_filter.amountRange != null) {
      activeFilters.add(_buildActiveFilterChip(
        'Amount: \$${_filter.amountRange!.start.round()} - \$${_filter.amountRange!.end.round()}',
        () {
          setState(() {
            _filter = _filter.copyWith(amountRange: null);
          });
          _loadInvoices();
        },
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXL,
        vertical: InventoryDesignConfig.spacingM,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(
          color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.funnel(),
                size: 16,
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Active Filters',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _filter = InvoiceFilter();
                    });
                    _loadInvoices();
                  },
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                  child: Padding(
                    padding: const EdgeInsets.all(InventoryDesignConfig.spacingXS),
                    child: Text(
                      'Clear All',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Wrap(
            spacing: InventoryDesignConfig.spacingS,
            runSpacing: InventoryDesignConfig.spacingS,
            children: activeFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingM,
        vertical: InventoryDesignConfig.spacingS,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        border: Border.all(
          color: InventoryDesignConfig.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingS),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
              child: Icon(
                PhosphorIcons.x(),
                size: 12,
                color: InventoryDesignConfig.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatsRow() {
    final totalInvoices = _invoices.length;
    final pendingPayment = _invoices.where((inv) => inv['payment_status'] != 'Paid').length;
    final totalRevenue = _invoices.fold<double>(0.0, (sum, inv) => sum + (inv['amount_including_vat'] as num).toDouble());

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
            title: 'Pending Payment',
            value: pendingPayment.toString(),
            icon: PhosphorIcons.hourglass(),
            color: InventoryDesignConfig.warningColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Total Revenue',
            value: NumberFormat.currency(symbol: '\$').format(totalRevenue),
            icon: PhosphorIcons.currencyDollar(),
            color: InventoryDesignConfig.successColor,
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

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: InventoryDesignConfig.primaryAccent,
      ),
    );
  }

  Widget _buildInvoiceTable() {
    if (_invoices.isEmpty) {
      return _buildEmptyState();
    }

    final List<DataColumn> columns = [
      _buildDataColumn('Invoice No.', 'invoice_number'),
      _buildDataColumn('Customer', 'customer_name'),
      _buildDataColumn('Date', 'date'),
      _buildDataColumn('Delivery Date', 'delivery_date'),
      _buildDataColumn('Amount', 'amount_including_vat'),
      _buildDataColumn('Payment Status', 'payment_status'),
      _buildDataColumn('Delivery Status', 'delivery_status'),
      const DataColumn(label: Text('')), // Actions column
    ];

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
        ),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          child: DataTable(
            columnSpacing: InventoryDesignConfig.spacingXXXL,
            horizontalMargin: InventoryDesignConfig.spacingXXL,
            headingRowHeight: 52,
            dataRowMaxHeight: 60,
            dataRowMinHeight: 60,
            showCheckboxColumn: false,
            dividerThickness: 1,
            border: TableBorder(
              horizontalInside: BorderSide(
                color: InventoryDesignConfig.borderSecondary,
              ),
            ),
            columns: columns,
            rows: _invoices.map((invoice) => _buildInvoiceRow(invoice)).toList(),
          ),
        ),
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
          Text('No invoices found', style: InventoryDesignConfig.headlineMedium),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            'Create your first invoice to get started',
            style: InventoryDesignConfig.bodyMedium,
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          _buildModernPrimaryButton(
            icon: PhosphorIcons.plus(),
            label: 'Create New Invoice',
            onPressed: () {
              AddEditInvoiceDesktopDialog.show(
                context,
                onInvoiceSaved: _loadInvoices,
              );
            },
          ),
        ],
      ),
    );
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

  DataRow _buildInvoiceRow(Map<String, dynamic> invoice) {
    final paymentStatus = invoice['payment_status'] ?? 'Pending';
    final deliveryStatus = invoice['delivery_status'] ?? 'Pending';

    return DataRow(
      cells: [
        DataCell(_buildHighlightedCell(invoice['invoice_number'], _searchQuery)),
        DataCell(_buildHighlightedCell(invoice['customer_name'], _searchQuery)),
        DataCell(_buildDateCell(invoice['date'])),
        DataCell(_buildDateCell(invoice['delivery_date'])),
        DataCell(_buildPriceCell(invoice['amount_including_vat'])),
        DataCell(_buildStatusCell(paymentStatus, _getPaymentStatusColor(paymentStatus))),
        DataCell(_buildStatusCell(deliveryStatus, _getDeliveryStatusColor(deliveryStatus))),
        DataCell(_buildActionsCell(invoice)),
      ],
      onSelectChanged: (selected) {
        if (selected == true) {
          InvoiceDetailDialogDesktop.show(
            context,
            invoice: invoice,
            onInvoiceUpdated: _loadInvoices,
            onInvoiceDeleted: _loadInvoices,
          );
        }
      },
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return InventoryDesignConfig.successColor;
      case 'Partially Paid':
        return InventoryDesignConfig.warningColor;
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
      case 'Pending':
      default:
        return InventoryDesignConfig.warningColor;
    }
  }

  Widget _buildHighlightedCell(String? text, String query) {
    if (text == null || text.isEmpty || query.isEmpty) {
      return Text(text ?? '');
    }

    final style = InventoryDesignConfig.titleMedium;
    final highlightStyle = style.copyWith(
      backgroundColor: InventoryDesignConfig.primaryColor.withOpacity(0.2),
      fontWeight: FontWeight.bold,
    );

    final spans = <TextSpan>[];
    int start = 0;
    while (start < text.length) {
      final startIndex = text.toLowerCase().indexOf(query.toLowerCase(), start);
      if (startIndex == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (startIndex > start) {
        spans.add(TextSpan(text: text.substring(start, startIndex), style: style));
      }
      final endIndex = startIndex + query.length;
      spans.add(TextSpan(text: text.substring(startIndex, endIndex), style: highlightStyle));
      start = endIndex;
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildDateCell(String? dateString) {
    if (dateString == null) return Text('N/A', style: InventoryDesignConfig.bodyLarge);
    try {
      final dateTime = DateTime.parse(dateString);
      return Text(DateFormat('MMM d, yyyy').format(dateTime), style: InventoryDesignConfig.bodyLarge);
    } catch (e) {
      return Text('Invalid Date', style: InventoryDesignConfig.bodyLarge.copyWith(color: InventoryDesignConfig.errorColor));
    }
  }

  Widget _buildPriceCell(dynamic price) {
    final numericPrice = _toDouble(price);
    return Text(
      NumberFormat.currency(symbol: '\$').format(numericPrice),
      style: InventoryDesignConfig.titleMedium,
    );
  }

  Widget _buildStatusCell(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
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

  Widget _buildActionsCell(Map<String, dynamic> invoice) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionIcon(
          icon: PhosphorIcons.pencilSimple(),
          onTap: () => _handleEditInvoice(invoice),
          color: InventoryDesignConfig.primaryAccent,
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        _buildActionIcon(
          icon: PhosphorIcons.trash(),
          onTap: () => _handleDeleteInvoice(invoice),
          color: InventoryDesignConfig.errorColor,
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
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
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Future<void> _handleEditInvoice(Map<String, dynamic> invoice) async {
    await AddEditInvoiceDesktopDialog.show(
      context,
      invoice: invoice,
      onInvoiceSaved: _loadInvoices,
    );
  }

  Future<void> _handleDeleteInvoice(Map<String, dynamic> invoice) async {
    final confirm = await _showDeleteConfirmationDialog(invoice);
    if (confirm != true) return;

    try {
      await _supabase
          .from('invoices')
          .delete()
          .eq('id', invoice['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice ${invoice['invoice_number']} deleted successfully',
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

  Future<bool?> _showDeleteConfirmationDialog(Map<String, dynamic> invoice) {
    final theme = Theme.of(context);
    final invoiceNumber = invoice['invoice_number'];

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
              'Are you sure you want to delete invoice number "$invoiceNumber"?',
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
                      invoiceNumber ?? 'Unknown Invoice',
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

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
