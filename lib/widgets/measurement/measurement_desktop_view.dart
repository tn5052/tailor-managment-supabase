import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/customer.dart';
import '../../models/measurement.dart';
import '../../models/measurement_filter.dart';
import '../../services/measurement_service.dart';
import '../../services/customer_service.dart';
import '../../theme/inventory_design_config.dart';
import 'desktop/add_measurement_dialog.dart';
import 'desktop/measurement_detail_dialog.dart';
import 'desktop/measurement_filters_dailog.dart';

class MeasurementDesktopView extends StatefulWidget {
  final MeasurementFilter filter;
  final Function(MeasurementFilter)? onFilterChanged;

  const MeasurementDesktopView({
    super.key,
    required this.filter,
    this.onFilterChanged,
  });

  @override
  State<MeasurementDesktopView> createState() => _MeasurementDesktopViewState();
}

class _MeasurementDesktopViewState extends State<MeasurementDesktopView> {
  final MeasurementService _measurementService = MeasurementService();
  final SupabaseService _customerService = SupabaseService();
  final _searchController = TextEditingController();

  List<Measurement> _measurements = [];
  List<Customer> _customers = [];
  MeasurementFilter _currentFilter = const MeasurementFilter();
  String _searchQuery = '';
  bool _isLoading = false;
  String _sortColumn = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filter;
    _searchQuery = _currentFilter.searchQuery;
    _searchController.text = _searchQuery;
    _loadData();
  }

  @override
  void didUpdateWidget(covariant MeasurementDesktopView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter != oldWidget.filter) {
      _currentFilter = widget.filter;
      _searchQuery = _currentFilter.searchQuery;
      if (_searchController.text != _searchQuery) {
        _searchController.text = _searchQuery;
      }
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _customerService.getAllCustomers();
      final measurements = await _measurementService.getAllMeasurements();

      var filteredMeasurements = _applyAllFilters(measurements, _currentFilter, _customers);

      // Apply sorting
      filteredMeasurements.sort((a, b) {
        int comparison;
        switch (_sortColumn) {
          case 'customer':
            final customerA = _getCustomer(a.customerId)?.name ?? '';
            final customerB = _getCustomer(b.customerId)?.name ?? '';
            comparison = customerA.compareTo(customerB);
            break;
          case 'style':
            comparison = a.style.compareTo(b.style);
            break;
          case 'designType':
            comparison = a.designType.compareTo(b.designType);
            break;
          case 'date':
          default:
            comparison = a.date.compareTo(b.date);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });

      setState(() {
        _customers = customers;
        _measurements = filteredMeasurements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading measurements: $e'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  Customer? _getCustomer(String customerId) {
    try {
      return _customers.firstWhere((c) => c.id == customerId);
    } catch (_) {
      return null;
    }
  }

  void _onSearchChanged(String text) {
    setState(() {
      _searchQuery = text;
      _currentFilter = _currentFilter.copyWith(searchQuery: text);
    });
    widget.onFilterChanged?.call(_currentFilter);
    _loadData();
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
    _loadData();
  }

  List<Measurement> _applyAllFilters(
    List<Measurement> measurements,
    MeasurementFilter filter,
    List<Customer> customers,
  ) {
    return measurements.where((measurement) {
      final customer = customers.firstWhere(
        (c) => c.id == measurement.customerId,
        orElse: () => Customer(
          id: '',
          billNumber: '',
          name: 'Unknown',
          phone: '',
          address: '',
          gender: Gender.male,
        ),
      );

      // Text search
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        if (!customer.name.toLowerCase().contains(query) &&
            !measurement.style.toLowerCase().contains(query) &&
            !measurement.designType.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Style filter
      if (filter.style != null && measurement.style != filter.style) {
        return false;
      }

      // Design Type filter
      if (filter.designType != null &&
          measurement.designType != filter.designType) {
        return false;
      }

      // Tarboosh Type filter
      if (filter.tarbooshType != null &&
          measurement.tarbooshType != filter.tarbooshType) {
        return false;
      }

      // Date Range filter
      if (filter.dateRange != null) {
        final date = measurement.date;
        if (date.isBefore(filter.dateRange!.start) ||
            date.isAfter(filter.dateRange!.end)) {
          return false;
        }
      }

      // Length range filter
      if (filter.lengthRange != null) {
        final length = measurement.style == 'Emirati'
            ? measurement.lengthArabi
            : measurement.lengthKuwaiti;
        if (length < filter.lengthRange!.start ||
            length > filter.lengthRange!.end) {
          return false;
        }
      }

      // Chest range filter
      if (filter.chestRange != null) {
        if (measurement.chest < filter.chestRange!.start ||
            measurement.chest > filter.chestRange!.end) {
          return false;
        }
      }

      // Sleeve range filter
      if (filter.sleeveRange != null) {
        if (measurement.sleeve < filter.sleeveRange!.start ||
            measurement.sleeve > filter.sleeveRange!.end) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _applyFilters(MeasurementFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    _loadData();
  }

  void _showAddMeasurementDialog() {
    AddMeasurementDialog.show(context);
    // Reload after adding
    Future.delayed(const Duration(milliseconds: 500), _loadData);
  }

  void _showMeasurementDetails(Measurement measurement) {
    DetailDialog.show(
      context,
      measurement: measurement,
      customerId: measurement.customerId,
    );
  }

  void _showFilterDialog() {
    MeasurementFilterDialog.show(
      context,
      currentFilter: _currentFilter,
      onFilterApplied: (filter) {
        setState(() {
          _currentFilter = filter;
          _searchQuery = filter.searchQuery;
          if (_searchController.text != _searchQuery) {
            _searchController.text = _searchQuery;
          }
        });
        widget.onFilterChanged?.call(_currentFilter);
        _loadData();
      },
      onClearFilters: () {
        setState(() {
          _currentFilter = const MeasurementFilter();
          _searchQuery = '';
          _searchController.clear();
        });
        widget.onFilterChanged?.call(_currentFilter);
        _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.backgroundColor,
      ),
      child: Column(
        children: [
          // Header section matching inventory/customer design
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
                            PhosphorIcons.ruler(),
                            size: 22,
                            color: InventoryDesignConfig.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Measurement Management',
                              style: InventoryDesignConfig.headlineLarge
                                  .copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                            Text(
                              'Manage customer measurements',
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
                        // Filter button with active indicator
                        Stack(
                          children: [
                            _buildModernSecondaryButton(
                              icon: PhosphorIcons.funnel(),
                              label: 'Filter & Group',
                              onPressed: _showFilterDialog,
                            ),
                            if (_hasActiveFilters())
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
                        const SizedBox(width: 12),
                        _buildModernPrimaryButton(
                          icon: PhosphorIcons.plus(),
                          label: 'Add Measurement',
                          onPressed: _showAddMeasurementDialog,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats row with grouping indicator
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
                        : _buildMeasurementTable(),
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
          hintText: 'Search by customer, style, or design...',
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
    final totalMeasurements = _measurements.length;
    final emiratiCount =
        _measurements.where((m) => m.style == 'Emirati').length;
    final kuwaitiCount =
        _measurements.where((m) => m.style == 'Kuwaiti').length;
    final recentCount =
        _measurements.where((m) {
          final today = DateTime.now();
          final weekAgo = today.subtract(const Duration(days: 7));
          return m.date.isAfter(weekAgo);
        }).length;

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Row(
        children: [
          _buildModernStatCard(
            title: 'Total Measurements',
            value: totalMeasurements.toString(),
            icon: PhosphorIcons.ruler(),
            color: InventoryDesignConfig.primaryAccent,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Emirati Style',
            value: emiratiCount.toString(),
            icon: PhosphorIcons.star(),
            color: InventoryDesignConfig.infoColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Kuwaiti Style',
            value: kuwaitiCount.toString(),
            icon: PhosphorIcons.crown(),
            color: InventoryDesignConfig.successColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Recent (7 days)',
            value: recentCount.toString(),
            icon: PhosphorIcons.clockClockwise(),
            color: InventoryDesignConfig.warningColor,
          ),
          const Spacer(),

          // Filter status indicator
          if (_hasActiveFilters()) ...[
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
                border: Border.all(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.funnel(),
                    size: 14,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingXS),
                  Text(
                    _getActiveFiltersText(),
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingL),
          ],

          // Group indicator
          if (_currentFilter.groupBy != MeasurementGroupBy.none)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: InventoryDesignConfig.spacingM,
                vertical: InventoryDesignConfig.spacingXS,
              ),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusS,
                ),
                border: Border.all(
                  color: InventoryDesignConfig.successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.stack(),
                    size: 14,
                    color: InventoryDesignConfig.successColor,
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingXS),
                  Text(
                    'Grouped by ${_getGroupLabel(_currentFilter.groupBy)}',
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.successColor,
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

  bool _hasActiveFilters() {
    return _currentFilter.searchQuery.isNotEmpty ||
        _currentFilter.style != null ||
        _currentFilter.designType != null ||
        _currentFilter.tarbooshType != null ||
        _currentFilter.dateRange != null ||
        _currentFilter.groupBy != MeasurementGroupBy.none ||
        _currentFilter.sortBy != MeasurementSortBy.date ||
        !_currentFilter.sortAscending;
  }

  String _getActiveFiltersText() {
    final activeCount =
        [
          _currentFilter.searchQuery.isNotEmpty,
          _currentFilter.style != null,
          _currentFilter.designType != null,
          _currentFilter.tarbooshType != null,
          _currentFilter.dateRange != null,
        ].where((filter) => filter).length;

    return '$activeCount Filter${activeCount != 1 ? 's' : ''} Active';
  }

  String _getGroupLabel(MeasurementGroupBy groupBy) {
    switch (groupBy) {
      case MeasurementGroupBy.none:
        return 'None';
      case MeasurementGroupBy.style:
        return 'Style';
      case MeasurementGroupBy.designType:
        return 'Design Type';
      case MeasurementGroupBy.tarbooshType:
        return 'Tarboosh Type';
      case MeasurementGroupBy.date:
        return 'Date';
      case MeasurementGroupBy.month:
        return 'Month';
      case MeasurementGroupBy.customer:
        return 'Customer';
    }
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
            'Loading measurements...',
            style: InventoryDesignConfig.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementTable() {
    if (_measurements.isEmpty) {
      return _buildEmptyState();
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(
            InventoryDesignConfig.surfaceAccent,
          ),
          dataRowColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.hovered))
              return InventoryDesignConfig.surfaceLight;
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
              _buildDataColumn('Customer', 'customer'),
              _buildDataColumn('Style', 'style'),
              _buildDataColumn('Design Type', 'designType'),
              _buildDataColumn('Date', 'date'),
              _buildDataColumn('Length', 'length'),
              _buildDataColumn('Chest', 'chest'),
              _buildDataColumn('Width', 'width'),
              _buildDataColumn('Sleeve', 'sleeve'),
              const DataColumn(label: Text('')), // Actions
            ],
            rows:
                _measurements
                    .map((measurement) => _buildMeasurementRow(measurement))
                    .toList(),
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
              PhosphorIcons.ruler(),
              size: 48,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          Text(
            'No measurements found',
            style: InventoryDesignConfig.headlineMedium,
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search criteria'
                : 'Add your first measurement to get started',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          if (_searchQuery.isNotEmpty)
            _buildModernPrimaryButton(
              icon: PhosphorIcons.arrowClockwise(),
              label: 'Clear Search',
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            )
          else
            _buildModernPrimaryButton(
              icon: PhosphorIcons.plus(),
              label: 'Add Measurement',
              onPressed: _showAddMeasurementDialog,
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

  DataRow _buildMeasurementRow(Measurement measurement) {
    final customer = _getCustomer(measurement.customerId);
    return DataRow(
      cells: [
        DataCell(_buildCustomerCell(customer)),
        DataCell(_buildStyleCell(measurement.style)),
        DataCell(_buildDesignTypeCell(measurement.designType)),
        DataCell(_buildDateCell(measurement.date)),
        DataCell(_buildLengthCell(measurement)),
        DataCell(_buildMeasurementValueCell(measurement.chest)),
        DataCell(_buildMeasurementValueCell(measurement.width)),
        DataCell(_buildMeasurementValueCell(measurement.sleeve)),
        DataCell(_buildActionsCell(measurement)),
      ],
      onSelectChanged: (selected) {
        if (selected == true) _showMeasurementDetails(measurement);
      },
    );
  }

  Widget _buildCustomerCell(Customer? customer) {
    if (customer == null) {
      return Text(
        'Unknown Customer',
        style: InventoryDesignConfig.bodyLarge.copyWith(
          color: InventoryDesignConfig.textTertiary,
        ),
      );
    }

    final genderColor =
        customer.gender == Gender.male
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: genderColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
            border: Border.all(color: genderColor, width: 1),
          ),
          child: Center(
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: genderColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        Expanded(
          child: Text(
            customer.name,
            style: InventoryDesignConfig.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStyleCell(String style) {
    final color =
        style == 'Emirati'
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      ),
      child: Text(
        style,
        style: InventoryDesignConfig.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDesignTypeCell(String designType) {
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
        designType,
        style: InventoryDesignConfig.bodySmall.copyWith(
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

  Widget _buildLengthCell(Measurement measurement) {
    final length =
        measurement.style == 'Emirati'
            ? measurement.lengthArabi
            : measurement.lengthKuwaiti;
    return _buildMeasurementValueCell(length);
  }

  Widget _buildMeasurementValueCell(double? value) {
    return Text(
      value != null && value > 0 ? value.toString() : '-',
      style: InventoryDesignConfig.bodyLarge,
    );
  }

  Widget _buildActionsCell(Measurement measurement) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionIcon(
          icon: PhosphorIcons.eye(),
          onTap: () => _showMeasurementDetails(measurement),
          color: InventoryDesignConfig.infoColor,
          tooltip: 'View Details',
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        _buildActionIcon(
          icon: PhosphorIcons.trash(),
          onTap: () => _confirmDeleteMeasurement(measurement),
          color: InventoryDesignConfig.errorColor,
          tooltip: 'Delete Measurement',
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

  Future<void> _confirmDeleteMeasurement(Measurement measurement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: InventoryDesignConfig.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          ),
          title: Row(
            children: [
              Icon(
                PhosphorIcons.warning(),
                color: InventoryDesignConfig.errorColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Delete Measurement',
                style: InventoryDesignConfig.titleLarge,
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this measurement?',
            style: InventoryDesignConfig.bodyLarge,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: InventoryDesignConfig.errorColor,
                foregroundColor: InventoryDesignConfig.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                ),
              ),
              icon: Icon(PhosphorIcons.trash()),
              label: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _measurementService.deleteMeasurement(measurement.id);
        _loadData(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Measurement deleted successfully.'),
              backgroundColor: InventoryDesignConfig.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
              ),
              margin: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting measurement: ${e.toString()}'),
              backgroundColor: InventoryDesignConfig.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
              ),
              margin: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            ),
          );
        }
      }
    }
  }
}
