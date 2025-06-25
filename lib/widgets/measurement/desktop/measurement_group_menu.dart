import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/measurement_filter.dart';
import '../../../theme/inventory_design_config.dart';

class MeasurementFilterDialog extends StatefulWidget {
  final MeasurementFilter currentFilter;
  final Function(MeasurementFilter) onFilterApplied;
  final VoidCallback onClearFilters;

  const MeasurementFilterDialog({
    super.key,
    required this.currentFilter,
    required this.onFilterApplied,
    required this.onClearFilters,
  });

  static Future<void> show(
    BuildContext context, {
    required MeasurementFilter currentFilter,
    required Function(MeasurementFilter) onFilterApplied,
    required VoidCallback onClearFilters,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => MeasurementFilterDialog(
            currentFilter: currentFilter,
            onFilterApplied: onFilterApplied,
            onClearFilters: onClearFilters,
          ),
    );
  }

  @override
  State<MeasurementFilterDialog> createState() =>
      _MeasurementFilterDialogState();
}

class _MeasurementFilterDialogState extends State<MeasurementFilterDialog> {
  late MeasurementFilter _localFilter;
  final _searchController = TextEditingController();

  // Filter options
  final List<String> _styleOptions = [
    'All Styles',
    'Emirati',
    'Kuwaiti',
    'Saudi',
    'Omani',
    'Qatari',
  ];

  final List<String> _designTypeOptions = ['All Designs', 'Aadi', 'Baat'];

  final List<String> _tarbooshTypeOptions = ['All Types', 'Fixed', 'Separate'];

  final List<String> _dateRangeOptions = [
    'All Time',
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
    'Custom Range',
  ];

  final List<MeasurementSortBy> _sortOptions = [
    MeasurementSortBy.date,
    MeasurementSortBy.customerName,
    MeasurementSortBy.style,
    MeasurementSortBy.designType,
  ];

  final List<MeasurementGroupBy> _groupOptions = [
    MeasurementGroupBy.none,
    MeasurementGroupBy.style,
    MeasurementGroupBy.designType,
    MeasurementGroupBy.tarbooshType,
    MeasurementGroupBy.date,
    MeasurementGroupBy.customer,
  ];

  @override
  void initState() {
    super.initState();
    _localFilter = widget.currentFilter;
    _searchController.text = _localFilter.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.onFilterApplied(_localFilter);
    Navigator.of(context).pop();
  }

  void _clearAllFilters() {
    widget.onClearFilters();
    Navigator.of(context).pop();
  }

  void _resetToDefaults() {
    setState(() {
      _localFilter = const MeasurementFilter();
      _searchController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXXL,
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
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
            ),
            child: Icon(
              PhosphorIcons.funnel(),
              size: 18,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter & Group Measurements',
                  style: InventoryDesignConfig.headlineMedium,
                ),
                Text(
                  'Refine and organize your measurements',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                child: Icon(
                  PhosphorIcons.x(),
                  size: 18,
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Section
          _buildSection(
            'Search & Text Filters',
            PhosphorIcons.magnifyingGlass(),
            [
              _buildTextField(
                controller: _searchController,
                label: 'Search Measurements',
                hint: 'Search by customer name, style, design type...',
                icon: PhosphorIcons.magnifyingGlass(),
                onChanged: (value) {
                  setState(() {
                    _localFilter = _localFilter.copyWith(searchQuery: value);
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Style & Design Filters
          _buildSection('Style & Design Filters', PhosphorIcons.paintBrush(), [
            Row(
              children: [
                Expanded(
                  child: _buildDropdownFilter<String>(
                    label: 'Style',
                    value: _localFilter.style ?? 'All Styles',
                    options: _styleOptions,
                    onChanged: (value) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(
                          style: value == 'All Styles' ? null : value,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingL),
                Expanded(
                  child: _buildDropdownFilter<String>(
                    label: 'Design Type',
                    value: _localFilter.designType ?? 'All Designs',
                    options: _designTypeOptions,
                    onChanged: (value) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(
                          designType: value == 'All Designs' ? null : value,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownFilter<String>(
                    label: 'Tarboosh Type',
                    value: _localFilter.tarbooshType ?? 'All Types',
                    options: _tarbooshTypeOptions,
                    onChanged: (value) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(
                          tarbooshType: value == 'All Types' ? null : value,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingL),
                Expanded(
                  child: _buildDropdownFilter<String>(
                    label: 'Date Range',
                    value: _getDateRangeLabel(),
                    options: _dateRangeOptions,
                    onChanged: (value) {
                      _handleDateRangeChange(value);
                    },
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Sort & Group Section
          _buildSection('Sort & Group Options', PhosphorIcons.sortAscending(), [
            Row(
              children: [
                Expanded(
                  child: _buildDropdownFilter<MeasurementSortBy>(
                    label: 'Sort By',
                    value: _localFilter.sortBy,
                    options: _sortOptions,
                    optionLabels: _sortOptions.map(_getSortLabel).toList(),
                    onChanged: (value) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(sortBy: value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingL),
                Expanded(child: _buildSortDirectionToggle()),
              ],
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownFilter<MeasurementGroupBy>(
                    label: 'Group By',
                    value: _localFilter.groupBy,
                    options: _groupOptions,
                    optionLabels: _groupOptions.map(_getGroupLabel).toList(),
                    onChanged: (value) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(groupBy: value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingL),
                Expanded(child: Container()), // Empty space for alignment
              ],
            ),
          ]),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Advanced Filters
          _buildSection('Advanced Filters', PhosphorIcons.gear(), [
            _buildMeasurementRangeFilters(),
          ]),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Active Filters Summary
          if (_hasActiveFilters()) _buildActiveFiltersSummary(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXXL,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          bottomRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(
          top: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _resetToDefaults,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.arrowClockwise(),
                      size: 16,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      'Reset',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _clearAllFilters,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXXL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: InventoryDesignConfig.buttonSecondaryDecoration,
                child: Text(
                  'Clear All',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _applyFilters,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXXL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: InventoryDesignConfig.buttonPrimaryDecoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.check(), size: 16, color: Colors.white),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      'Apply Filters',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
              ),
              border: Border(
                bottom: BorderSide(
                  color: InventoryDesignConfig.borderSecondary,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  title,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        TextFormField(
          controller: controller,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: InventoryDesignConfig.textSecondary,
            ),
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical: InventoryDesignConfig.spacingM,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownFilter<T>({
    required String label,
    required T value,
    required List<T> options,
    List<String>? optionLabels,
    required Function(T) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        DropdownButtonFormField<T>(
          value: value,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
          ),
          dropdownColor: InventoryDesignConfig.surfaceColor,
          decoration: InputDecoration(
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical: InventoryDesignConfig.spacingM,
            ),
          ),
          items:
              options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final label = optionLabels?[index] ?? option.toString();

                return DropdownMenuItem<T>(
                  value: option,
                  child: Text(label, style: InventoryDesignConfig.bodyLarge),
                );
              }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          icon: Icon(
            PhosphorIcons.caretDown(),
            size: 16,
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSortDirectionToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort Direction',
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _localFilter = _localFilter.copyWith(sortAscending: true);
                    });
                  },
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: InventoryDesignConfig.spacingM + 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _localFilter.sortAscending
                              ? InventoryDesignConfig.primaryColor
                              : InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      border: Border.all(
                        color:
                            _localFilter.sortAscending
                                ? InventoryDesignConfig.primaryColor
                                : InventoryDesignConfig.borderPrimary,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.sortAscending(),
                          size: 16,
                          color:
                              _localFilter.sortAscending
                                  ? Colors.white
                                  : InventoryDesignConfig.textSecondary,
                        ),
                        const SizedBox(width: InventoryDesignConfig.spacingXS),
                        Text(
                          'Ascending',
                          style: InventoryDesignConfig.bodyMedium.copyWith(
                            color:
                                _localFilter.sortAscending
                                    ? Colors.white
                                    : InventoryDesignConfig.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _localFilter = _localFilter.copyWith(
                        sortAscending: false,
                      );
                    });
                  },
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: InventoryDesignConfig.spacingM + 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          !_localFilter.sortAscending
                              ? InventoryDesignConfig.primaryColor
                              : InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      border: Border.all(
                        color:
                            !_localFilter.sortAscending
                                ? InventoryDesignConfig.primaryColor
                                : InventoryDesignConfig.borderPrimary,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.sortDescending(),
                          size: 16,
                          color:
                              !_localFilter.sortAscending
                                  ? Colors.white
                                  : InventoryDesignConfig.textSecondary,
                        ),
                        const SizedBox(width: InventoryDesignConfig.spacingXS),
                        Text(
                          'Descending',
                          style: InventoryDesignConfig.bodyMedium.copyWith(
                            color:
                                !_localFilter.sortAscending
                                    ? Colors.white
                                    : InventoryDesignConfig.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeasurementRangeFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Measurement Value Ranges',
          style: InventoryDesignConfig.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: InventoryDesignConfig.textPrimary,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        Text(
          'Filter measurements by specific value ranges (coming soon)',
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersSummary() {
    final activeFilters = <String>[];

    if (_localFilter.searchQuery.isNotEmpty) {
      activeFilters.add('Search: "${_localFilter.searchQuery}"');
    }
    if (_localFilter.style != null) {
      activeFilters.add('Style: ${_localFilter.style}');
    }
    if (_localFilter.designType != null) {
      activeFilters.add('Design: ${_localFilter.designType}');
    }
    if (_localFilter.tarbooshType != null) {
      activeFilters.add('Tarboosh: ${_localFilter.tarbooshType}');
    }
    if (_localFilter.dateRange != null) {
      activeFilters.add('Date Range: ${_getDateRangeLabel()}');
    }
    if (_localFilter.groupBy != MeasurementGroupBy.none) {
      activeFilters.add('Grouped by: ${_getGroupLabel(_localFilter.groupBy)}');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
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
                'Active Filters (${activeFilters.length})',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          Wrap(
            spacing: InventoryDesignConfig.spacingS,
            runSpacing: InventoryDesignConfig.spacingS,
            children:
                activeFilters.map((filter) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: InventoryDesignConfig.spacingM,
                      vertical: InventoryDesignConfig.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.primaryColor,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  String _getDateRangeLabel() {
    if (_localFilter.dateRange == null) return 'All Time';

    final now = DateTime.now();
    final range = _localFilter.dateRange!;

    if (range.start.isAtSameMomentAs(DateTime(now.year, now.month, now.day)) &&
        range.end.isAtSameMomentAs(
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        )) {
      return 'Today';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (range.start.isAtSameMomentAs(
          DateTime(yesterday.year, yesterday.month, yesterday.day),
        ) &&
        range.end.isAtSameMomentAs(
          DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
        )) {
      return 'Yesterday';
    }

    final weekAgo = now.subtract(const Duration(days: 7));
    if (range.start.isAtSameMomentAs(
      DateTime(weekAgo.year, weekAgo.month, weekAgo.day),
    )) {
      return 'Last 7 Days';
    }

    final monthAgo = now.subtract(const Duration(days: 30));
    if (range.start.isAtSameMomentAs(
      DateTime(monthAgo.year, monthAgo.month, monthAgo.day),
    )) {
      return 'Last 30 Days';
    }

    return 'Custom Range';
  }

  void _handleDateRangeChange(String value) {
    final now = DateTime.now();
    DateTimeRange? dateRange;

    switch (value) {
      case 'All Time':
        dateRange = null;
        break;
      case 'Today':
        dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        dateRange = DateTimeRange(
          start: DateTime(yesterday.year, yesterday.month, yesterday.day),
          end: DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
            59,
          ),
        );
        break;
      case 'Last 7 Days':
        dateRange = DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 7)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
      case 'Last 30 Days':
        dateRange = DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 30)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
      case 'This Month':
        dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        dateRange = DateTimeRange(
          start: lastMonth,
          end: DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59),
        );
        break;
      case 'Custom Range':
        // TODO: Show date picker for custom range
        break;
    }

    setState(() {
      _localFilter = _localFilter.copyWith(dateRange: dateRange);
    });
  }

  String _getSortLabel(MeasurementSortBy sortBy) {
    switch (sortBy) {
      case MeasurementSortBy.date:
        return 'Date Created';
      case MeasurementSortBy.customerName:
        return 'Customer Name';
      case MeasurementSortBy.style:
        return 'Style';
      case MeasurementSortBy.designType:
        return 'Design Type';
      // Add a default case or throw an exception if necessary,
      // though all enum values are covered.
      // default:
      //   return 'Unknown';
    }
  }

  String _getGroupLabel(MeasurementGroupBy groupBy) {
    switch (groupBy) {
      case MeasurementGroupBy.none:
        return 'No Grouping';
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

  bool _hasActiveFilters() {
    return _localFilter.searchQuery.isNotEmpty ||
        _localFilter.style != null ||
        _localFilter.designType != null ||
        _localFilter.tarbooshType != null ||
        _localFilter.dateRange != null ||
        _localFilter.groupBy != MeasurementGroupBy.none ||
        _localFilter.sortBy != MeasurementSortBy.date ||
        !_localFilter.sortAscending;
  }
}
