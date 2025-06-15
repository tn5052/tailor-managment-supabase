import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/customer.dart';
import '../../models/customer_filter.dart';
import '../inventory/inventory_design_config.dart';

class CustomerFilterDialog extends StatefulWidget {
  final CustomerFilter filter;
  final Function(CustomerFilter) onFilterChanged;

  const CustomerFilterDialog({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<CustomerFilterDialog> createState() => _CustomerFilterDialogState();
}

class _CustomerFilterDialogState extends State<CustomerFilterDialog> {
  late CustomerFilter _currentFilter;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filter;
    _selectedDateRange = _currentFilter.dateRange;
  }

  void _updateFilter(CustomerFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
    });
  }

  void _applyFilters() {
    widget.onFilterChanged(_currentFilter);
  }

  void _clearAllFilters() {
    _updateFilter(const CustomerFilter());
    _selectedDateRange = null;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: InventoryDesignConfig.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _currentFilter = _currentFilter.copyWith(dateRange: picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      constraints: const BoxConstraints(maxHeight: 700),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGenderFilter(),
                  const SizedBox(height: InventoryDesignConfig.spacingXL),
                  _buildDateRangeFilter(),
                  const SizedBox(height: InventoryDesignConfig.spacingXL),
                  _buildBooleanFilters(),
                  const SizedBox(height: InventoryDesignConfig.spacingXL),
                  _buildSortingOptions(),
                  const SizedBox(height: InventoryDesignConfig.spacingXL),
                  _buildGroupingOptions(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.funnel(),
            size: 24,
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Text(
            'Filter Customers',
            style: InventoryDesignConfig.headlineSmall,
          ),
          const Spacer(),
          if (_currentFilter.hasActiveFilters)
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: Icon(
                PhosphorIcons.eraser(),
                size: 16,
                color: InventoryDesignConfig.errorColor,
              ),
              label: Text(
                'Clear All',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.errorColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: InventoryDesignConfig.titleMedium,
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        Wrap(
          spacing: InventoryDesignConfig.spacingM,
          children: Gender.values.map((gender) {
            final isSelected = _currentFilter.selectedGenders.contains(gender);
            return FilterChip(
              label: Text(gender.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                final newGenders = Set<Gender>.from(_currentFilter.selectedGenders);
                if (selected) {
                  newGenders.add(gender);
                } else {
                  newGenders.remove(gender);
                }
                _updateFilter(_currentFilter.copyWith(selectedGenders: newGenders));
              },
              backgroundColor: InventoryDesignConfig.surfaceLight,
              selectedColor: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              checkmarkColor: InventoryDesignConfig.primaryColor,
              labelStyle: InventoryDesignConfig.bodySmall.copyWith(
                color: isSelected
                    ? InventoryDesignConfig.primaryColor
                    : InventoryDesignConfig.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: InventoryDesignConfig.titleMedium,
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          child: Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              border: Border.all(color: InventoryDesignConfig.borderPrimary),
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.calendar(),
                  size: 20,
                  color: InventoryDesignConfig.textSecondary,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'
                        : 'Select date range',
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      color: _selectedDateRange != null
                          ? InventoryDesignConfig.textPrimary
                          : InventoryDesignConfig.textSecondary,
                    ),
                  ),
                ),
                if (_selectedDateRange != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                        _currentFilter = _currentFilter.copyWith(clearDateRange: true);
                      });
                    },
                    icon: Icon(
                      PhosphorIcons.x(),
                      size: 16,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBooleanFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Filters',
          style: InventoryDesignConfig.titleMedium,
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildSwitchTile(
          'Only with Family',
          'Show customers who are part of a family',
          _currentFilter.onlyWithFamily,
          (value) => _updateFilter(_currentFilter.copyWith(onlyWithFamily: value)),
        ),
        _buildSwitchTile(
          'Only with Referrals',
          'Show customers who were referred by someone',
          _currentFilter.onlyWithReferrals,
          (value) => _updateFilter(_currentFilter.copyWith(onlyWithReferrals: value)),
        ),
        _buildSwitchTile(
          'Recently Added',
          'Show customers added in the last 7 days',
          _currentFilter.onlyRecentlyAdded,
          (value) => _updateFilter(_currentFilter.copyWith(onlyRecentlyAdded: value)),
        ),
        _buildSwitchTile(
          'Has WhatsApp',
          'Show customers with WhatsApp number',
          _currentFilter.hasWhatsapp,
          (value) => _updateFilter(_currentFilter.copyWith(hasWhatsapp: value)),
        ),
        _buildSwitchTile(
          'Has Address',
          'Show customers with complete address',
          _currentFilter.hasAddress,
          (value) => _updateFilter(_currentFilter.copyWith(hasAddress: value)),
        ),
        _buildSwitchTile(
          'Is Referrer',
          'Show customers who have referred others',
          _currentFilter.isReferrer,
          (value) => _updateFilter(_currentFilter.copyWith(isReferrer: value)),
        ),
        _buildSwitchTile(
          'Has Family Members',
          'Show customers with family connections',
          _currentFilter.hasFamilyMembers,
          (value) => _updateFilter(_currentFilter.copyWith(hasFamilyMembers: value)),
        ),
        _buildSwitchTile(
          'Show Top Referrers',
          'Show customers with the most referrals',
          _currentFilter.showTopReferrers,
          (value) => _updateFilter(_currentFilter.copyWith(showTopReferrers: value)),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: InventoryDesignConfig.bodyMedium,
                ),
                Text(
                  subtitle,
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: InventoryDesignConfig.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSortingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: InventoryDesignConfig.titleMedium,
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        Wrap(
          spacing: InventoryDesignConfig.spacingS,
          runSpacing: InventoryDesignConfig.spacingS,
          children: CustomerSortBy.values.map((sortBy) {
            final isSelected = _currentFilter.sortBy == sortBy;
            return ChoiceChip(
              label: Text(_getSortByLabel(sortBy)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateFilter(_currentFilter.copyWith(sortBy: sortBy));
                }
              },
              backgroundColor: InventoryDesignConfig.surfaceLight,
              selectedColor: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              labelStyle: InventoryDesignConfig.bodySmall.copyWith(
                color: isSelected
                    ? InventoryDesignConfig.primaryColor
                    : InventoryDesignConfig.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGroupingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group By',
          style: InventoryDesignConfig.titleMedium,
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        Wrap(
          spacing: InventoryDesignConfig.spacingS,
          runSpacing: InventoryDesignConfig.spacingS,
          children: CustomerGroupBy.values.map((groupBy) {
            final isSelected = _currentFilter.groupBy == groupBy;
            return ChoiceChip(
              label: Text(_getGroupByLabel(groupBy)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateFilter(_currentFilter.copyWith(groupBy: groupBy));
                }
              },
              backgroundColor: InventoryDesignConfig.surfaceLight,
              selectedColor: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              labelStyle: InventoryDesignConfig.bodySmall.copyWith(
                color: isSelected
                    ? InventoryDesignConfig.primaryColor
                    : InventoryDesignConfig.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_getActiveFiltersCount()} filters active',
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          FilledButton(
            onPressed: _applyFilters,
            style: FilledButton.styleFrom(
              backgroundColor: InventoryDesignConfig.primaryColor,
              foregroundColor: InventoryDesignConfig.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              ),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  String _getSortByLabel(CustomerSortBy sortBy) {
    switch (sortBy) {
      case CustomerSortBy.newest:
        return 'Newest First';
      case CustomerSortBy.oldest:
        return 'Oldest First';
      case CustomerSortBy.nameAZ:
        return 'Name A-Z';
      case CustomerSortBy.nameZA:
        return 'Name Z-A';
      case CustomerSortBy.billNumberAsc:
        return 'Bill # Ascending';
      case CustomerSortBy.billNumberDesc:
        return 'Bill # Descending';
    }
  }

  String _getGroupByLabel(CustomerGroupBy groupBy) {
    switch (groupBy) {
      case CustomerGroupBy.none:
        return 'None';
      case CustomerGroupBy.gender:
        return 'Gender';
      case CustomerGroupBy.family:
        return 'Family';
      case CustomerGroupBy.referrals:
        return 'Referrals';
      case CustomerGroupBy.dateAdded:
        return 'Date Added';
    }
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_currentFilter.selectedGenders.isNotEmpty) count++;
    if (_currentFilter.dateRange != null) count++;
    if (_currentFilter.onlyWithFamily) count++;
    if (_currentFilter.onlyWithReferrals) count++;
    if (_currentFilter.onlyRecentlyAdded) count++;
    if (_currentFilter.hasWhatsapp) count++;
    if (_currentFilter.hasAddress) count++;
    if (_currentFilter.isReferrer) count++;
    if (_currentFilter.hasFamilyMembers) count++;
    if (_currentFilter.showTopReferrers) count++;
    if (_currentFilter.sortBy != CustomerSortBy.newest) count++;
    if (_currentFilter.groupBy != CustomerGroupBy.none) count++;
    return count;
  }
}
