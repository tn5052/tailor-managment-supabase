import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/measurement.dart';
import '../../models/measurement_filter.dart';
import '../../models/customer.dart';
import '../../services/measurement_service.dart';
import '../../services/customer_service.dart';
import '../../theme/inventory_design_config.dart';
import 'mobile/add_measurement_mobile_sheet.dart';
import 'mobile/measurement_detail_screen_mobile.dart';
import 'mobile/measurement_filter_sheet.dart';

class MeasurementMobileView extends StatefulWidget {
  final MeasurementFilter filter;
  final Function(MeasurementFilter)? onFilterChanged;

  const MeasurementMobileView({
    super.key,
    required this.filter,
    this.onFilterChanged,
  });

  @override
  State<MeasurementMobileView> createState() => _MeasurementMobileViewState();
}

class _MeasurementMobileViewState extends State<MeasurementMobileView>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _measurementService = MeasurementService();
  final _customerService = SupabaseService();

  String _searchQuery = '';
  bool _isLoading = false;
  List<Measurement> _measurements = [];
  List<Customer> _customers = [];
  MeasurementFilter _currentFilter = const MeasurementFilter();

  bool _isSearchExpanded = false;
  AnimationController? _searchAnimationController;
  Animation<double>? _searchAnimation;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filter;
    _searchQuery = _currentFilter.searchQuery;
    _searchController.text = _searchQuery;

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController!,
      curve: Curves.easeInOut,
    );

    _loadData();
  }

  @override
  void didUpdateWidget(covariant MeasurementMobileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter != oldWidget.filter) {
      _currentFilter = widget.filter;
      _searchQuery = _currentFilter.searchQuery;
      _searchController.text = _searchQuery;
      _loadData();
    }
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
    } else {
      _searchAnimationController!.reverse();
      _searchController.clear();
      _onSearchChanged('');
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final customers = await _customerService.getAllCustomers();
      final measurements = await _measurementService.getAllMeasurements();

      List<Measurement> filteredMeasurements =
          measurements.where((measurement) {
            // Search filter
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final customer = _getCustomer(measurement.customerId, customers);
              final customerName = customer?.name.toLowerCase() ?? '';
              final style = measurement.style.toLowerCase();
              final designType = measurement.designType.toLowerCase();

              if (!customerName.contains(query) &&
                  !style.contains(query) &&
                  !designType.contains(query) &&
                  !measurement.billNumber.toLowerCase().contains(query)) {
                return false;
              }
            }

            // Style filter
            if (_currentFilter.style != null &&
                measurement.style != _currentFilter.style) {
              return false;
            }

            // Design type filter
            if (_currentFilter.designType != null &&
                measurement.designType != _currentFilter.designType) {
              return false;
            }

            // Date range filter
            if (_currentFilter.dateRange != null) {
              final start = _currentFilter.dateRange!.start;
              final end = _currentFilter.dateRange!.end;
              if (measurement.date.isBefore(start) ||
                  measurement.date.isAfter(end)) {
                return false;
              }
            }

            return true;
          }).toList();

      // Apply sorting
      filteredMeasurements.sort((a, b) {
        switch (_currentFilter.sortBy) {
          case MeasurementSortBy.date:
            return _currentFilter.sortAscending
                ? a.date.compareTo(b.date)
                : b.date.compareTo(a.date);
          case MeasurementSortBy.customerName:
            final customerA = _getCustomer(a.customerId, customers)?.name ?? '';
            final customerB = _getCustomer(b.customerId, customers)?.name ?? '';
            return _currentFilter.sortAscending
                ? customerA.compareTo(customerB)
                : customerB.compareTo(customerA);
          case MeasurementSortBy.style:
            return _currentFilter.sortAscending
                ? a.style.compareTo(b.style)
                : b.style.compareTo(a.style);
          case MeasurementSortBy.designType:
            return _currentFilter.sortAscending
                ? a.designType.compareTo(b.designType)
                : b.designType.compareTo(a.designType);
        }
      });

      if (mounted) {
        setState(() {
          _customers = customers;
          _measurements = filteredMeasurements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading measurements: $e'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  Customer? _getCustomer(String customerId, List<Customer> customers) {
    try {
      return customers.firstWhere((c) => c.id == customerId);
    } catch (_) {
      return null;
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _currentFilter = _currentFilter.copyWith(searchQuery: query);
    widget.onFilterChanged?.call(_currentFilter);
    _loadData();
  }

  void _showFilterBottomSheet() {
    MeasurementFilterSheet.show(context, _currentFilter, (newFilter) {
      _currentFilter = newFilter;
      widget.onFilterChanged?.call(_currentFilter);
      _loadData();
    });
  }

  void _showAddMeasurementSheet() {
    AddMeasurementMobileSheet.show(context, onMeasurementAdded: _loadData);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: InventoryDesignConfig.backgroundColor,
      child: Column(
        children: [
          _buildModernAppBar(),
          _buildExpandableSearchSection(),
          _buildQuickStatsBar(),
          Expanded(child: _buildMeasurementList()),
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
              // Title Section - Animated
              Expanded(
                flex: _isSearchExpanded ? 0 : 1,
                child: AnimatedOpacity(
                  opacity: _isSearchExpanded ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child:
                      _isSearchExpanded
                          ? const SizedBox.shrink()
                          : Row(
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
                                  PhosphorIcons.ruler(),
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
                                      'Measurements',
                                      style:
                                          InventoryDesignConfig.headlineMedium,
                                    ),
                                    Text(
                                      'Manage customer measurements',
                                      style: InventoryDesignConfig.bodySmall
                                          .copyWith(
                                            color:
                                                InventoryDesignConfig
                                                    .textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                ),
              ),

              // Expandable Search Field
              if (_isSearchExpanded)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
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
                          hintText: 'Search measurements...',
                          hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
                            color: InventoryDesignConfig.textTertiary,
                          ),
                          prefixIcon: Container(
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
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                ),

              // Action Buttons
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
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    _buildHeaderIconButton(
                      icon: PhosphorIcons.plus(),
                      onTap: _showAddMeasurementSheet,
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

  Widget _buildExpandableSearchSection() {
    if (!_isSearchExpanded || !_hasActiveFilters()) {
      return const SizedBox.shrink();
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: InventoryDesignConfig.surfaceColor,
        padding: const EdgeInsets.fromLTRB(
          InventoryDesignConfig.spacingL,
          0,
          InventoryDesignConfig.spacingL,
          InventoryDesignConfig.spacingM,
        ),
        child: _buildActiveFiltersDisplay(),
      ),
    );
  }

  Widget _buildActiveFiltersDisplay() {
    if (!_hasActiveFilters()) return const SizedBox.shrink();

    final activeFilters = <String>[];
    if (_searchQuery.isNotEmpty) activeFilters.add('Search: $_searchQuery');
    if (_currentFilter.style != null)
      activeFilters.add('Style: ${_currentFilter.style}');
    if (_currentFilter.designType != null)
      activeFilters.add('Design: ${_currentFilter.designType}');

    return Row(
      children: [
        Text(
          'Active filters:',
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        Expanded(
          child: Text(
            activeFilters.join(', '),
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.primaryColor,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsBar() {
    final totalMeasurements = _measurements.length;
    final emiratiCount =
        _measurements.where((m) => m.style == 'Emirati').length;
    final kuwaitiCount =
        _measurements.where((m) => m.style == 'Kuwaiti').length;

    return Container(
      color: InventoryDesignConfig.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingL,
        vertical: InventoryDesignConfig.spacingM,
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: PhosphorIcons.ruler(),
            label: 'Total',
            value: '$totalMeasurements',
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          _buildStatItem(
            icon: PhosphorIcons.star(),
            label: 'Emirati',
            value: '$emiratiCount',
            color: InventoryDesignConfig.infoColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          _buildStatItem(
            icon: PhosphorIcons.crown(),
            label: 'Kuwaiti',
            value: '$kuwaitiCount',
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
            color:
                isPrimary
                    ? InventoryDesignConfig.primaryColor
                    : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color:
                  isPrimary
                      ? InventoryDesignConfig.primaryColor
                      : InventoryDesignConfig.borderPrimary,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color:
                isPrimary
                    ? InventoryDesignConfig.surfaceColor
                    : InventoryDesignConfig.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: InventoryDesignConfig.primaryColor,
        ),
      );
    }
    if (_measurements.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      color: InventoryDesignConfig.primaryColor,
      onRefresh: _loadData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          InventoryDesignConfig.spacingL,
          InventoryDesignConfig.spacingS,
          InventoryDesignConfig.spacingL,
          InventoryDesignConfig.spacingXL,
        ),
        itemCount: _measurements.length,
        itemBuilder:
            (context, index) => _buildMeasurementCard(_measurements[index]),
      ),
    );
  }

  Widget _buildMeasurementCard(Measurement measurement) {
    final customer = _getCustomer(measurement.customerId, _customers);
    final styleColor =
        measurement.style == 'Emirati'
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;

    return Container(
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        child: InkWell(
          onTap: () => _showMeasurementDetails(context, measurement),
          onLongPress: () => _showMeasurementActions(context, measurement),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Style Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: InventoryDesignConfig.spacingM,
                        vertical: InventoryDesignConfig.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: styleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            measurement.style == 'Emirati'
                                ? PhosphorIcons.star()
                                : PhosphorIcons.crown(),
                            size: 14,
                            color: styleColor,
                          ),
                          const SizedBox(
                            width: InventoryDesignConfig.spacingXS,
                          ),
                          Text(
                            measurement.style,
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color: styleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Bill Number
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: InventoryDesignConfig.spacingS,
                        vertical: InventoryDesignConfig.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.surfaceAccent,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                      ),
                      child: Text(
                        '#${measurement.billNumber}',
                        style: InventoryDesignConfig.code.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: InventoryDesignConfig.spacingM),

                // Customer Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: (customer?.gender == Gender.male
                              ? InventoryDesignConfig.infoColor
                              : InventoryDesignConfig.successColor)
                          .withOpacity(0.1),
                      child: Text(
                        customer?.name.isNotEmpty == true
                            ? customer!.name[0].toUpperCase()
                            : '?',
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color:
                              customer?.gender == Gender.male
                                  ? InventoryDesignConfig.infoColor
                                  : InventoryDesignConfig.successColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer?.name ?? 'Unknown Customer',
                            style: InventoryDesignConfig.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(
                            height: InventoryDesignConfig.spacingXS,
                          ),
                          Text(
                            '${measurement.designType} • ${_formatDate(measurement.date)}',
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

                // Key Measurements
                Row(
                  children: [
                    _buildMeasurementChip(
                      label: 'Length',
                      value:
                          measurement.style == 'Emirati'
                              ? measurement.lengthArabi.toString()
                              : measurement.lengthKuwaiti.toString(),
                      color: InventoryDesignConfig.primaryColor,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    _buildMeasurementChip(
                      label: 'Chest',
                      value: measurement.chest.toString(),
                      color: InventoryDesignConfig.infoColor,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    _buildMeasurementChip(
                      label: 'Width',
                      value: measurement.width.toString(),
                      color: InventoryDesignConfig.successColor,
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

  Widget _buildMeasurementChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: InventoryDesignConfig.spacingS,
          vertical: InventoryDesignConfig.spacingXS,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        ),
        child: Column(
          children: [
            Text(
              value == '0.0' ? '-' : value,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
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
                PhosphorIcons.ruler(),
                size: 48,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            if (_searchQuery.isNotEmpty)
              _buildEmptyStateButton(
                icon: PhosphorIcons.arrowClockwise(),
                label: 'Clear Search',
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                isPrimary: false,
              )
            else
              _buildEmptyStateButton(
                icon: PhosphorIcons.plus(),
                label: 'Add Measurement',
                onPressed: _showAddMeasurementSheet,
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
          decoration:
              isPrimary
                  ? InventoryDesignConfig.buttonPrimaryDecoration
                  : InventoryDesignConfig.buttonSecondaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isPrimary
                        ? InventoryDesignConfig.surfaceColor
                        : InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color:
                      isPrimary
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

  bool _hasActiveFilters() {
    return _currentFilter.searchQuery.isNotEmpty ||
        _currentFilter.style != null ||
        _currentFilter.designType != null ||
        _currentFilter.dateRange != null ||
        _currentFilter.sortBy != MeasurementSortBy.date ||
        !_currentFilter.sortAscending;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';
    if (difference < 30) return '${(difference / 7).floor()}w ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showMeasurementDetails(BuildContext context, Measurement measurement) {
    MeasurementDetailScreenMobile.show(
      context,
      measurement: measurement,
      onMeasurementUpdated: _loadData,
    );
  }

  void _showMeasurementActions(BuildContext context, Measurement measurement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(InventoryDesignConfig.radiusXL),
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
                    color: InventoryDesignConfig.borderPrimary,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.ruler(),
                        color: InventoryDesignConfig.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Measurement Actions',
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                    _showMeasurementDetails(context, measurement);
                  },
                ),
                ListTile(
                  leading: Icon(PhosphorIcons.pencilSimple()),
                  title: const Text('Edit Measurement'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Implement edit functionality
                  },
                ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.trash(),
                    color: InventoryDesignConfig.errorColor,
                  ),
                  title: Text(
                    'Delete Measurement',
                    style: TextStyle(color: InventoryDesignConfig.errorColor),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Implement delete functionality
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}
