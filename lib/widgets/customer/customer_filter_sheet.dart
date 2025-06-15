import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/customer.dart';
import '../../models/customer_filter.dart';
import '../inventory/inventory_design_config.dart';

class CustomerFilterSheet extends StatefulWidget {
  final CustomerFilter initialFilter;
  final Function(CustomerFilter) onFilterChanged;

  const CustomerFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onFilterChanged,
  });

  static void show(
    BuildContext context,
    CustomerFilter currentFilter,
    Function(CustomerFilter) onFilterChanged,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: true,
      builder:
          (context) => CustomerFilterSheet(
            initialFilter: currentFilter,
            onFilterChanged: onFilterChanged,
          ),
    );
  }

  @override
  State<CustomerFilterSheet> createState() => _CustomerFilterSheetState();
}

class _CustomerFilterSheetState extends State<CustomerFilterSheet>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;

  late AnimationController _animationController;
  late Animation<double> _sheetAnimation;

  // Local state for filters
  CustomerFilter _localFilter = const CustomerFilter();

  final List<String> _quickFilterOptions = [
    'All',
    'Recently Added',
    'Has WhatsApp',
    'Is Referrer',
    'Has Family',
  ];

  final List<String> _genderOptions = ['All Genders', 'Male', 'Female'];

  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Name (A-Z)',
    'Name (Z-A)',
    'Bill Number (Low-High)',
    'Bill Number (High-Low)',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _searchController = TextEditingController(
      text: widget.initialFilter.searchQuery,
    );

    // Initialize local state
    _localFilter = widget.initialFilter;

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _sheetAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.onFilterChanged(_localFilter);
    Navigator.of(context).pop();
  }

  void _clearAllFilters() {
    setState(() {
      _localFilter = const CustomerFilter();
      _searchController.clear();
    });
    widget.onFilterChanged(const CustomerFilter());
    Navigator.of(context).pop();
  }

  String _getQuickFilterSelection() {
    if (_localFilter.onlyRecentlyAdded) return 'Recently Added';
    if (_localFilter.hasWhatsapp) return 'Has WhatsApp';
    if (_localFilter.isReferrer) return 'Is Referrer';
    if (_localFilter.hasFamilyMembers) return 'Has Family';
    return 'All';
  }

  String _getGenderSelection() {
    if (_localFilter.selectedGenders.isEmpty) return 'All Genders';
    if (_localFilter.selectedGenders.contains(Gender.male) &&
        _localFilter.selectedGenders.contains(Gender.female))
      return 'All Genders';
    if (_localFilter.selectedGenders.contains(Gender.male)) return 'Male';
    if (_localFilter.selectedGenders.contains(Gender.female)) return 'Female';
    return 'All Genders';
  }

  String _getSortSelection() {
    switch (_localFilter.sortBy) {
      case CustomerSortBy.nameAZ:
        return 'Name (A-Z)';
      case CustomerSortBy.nameZA:
        return 'Name (Z-A)';
      case CustomerSortBy.billNumberAsc:
        return 'Bill Number (Low-High)';
      case CustomerSortBy.billNumberDesc:
        return 'Bill Number (High-Low)';
      case CustomerSortBy.oldest:
        return 'Oldest First';
      case CustomerSortBy.newest:
      return 'Newest First';
    }
  }

  void _updateQuickFilter(String selection) {
    setState(() {
      switch (selection) {
        case 'Recently Added':
          _localFilter = _localFilter.copyWith(
            onlyRecentlyAdded: true,
            hasWhatsapp: false,
            isReferrer: false,
            hasFamilyMembers: false,
          );
          break;
        case 'Has WhatsApp':
          _localFilter = _localFilter.copyWith(
            hasWhatsapp: true,
            onlyRecentlyAdded: false,
            isReferrer: false,
            hasFamilyMembers: false,
          );
          break;
        case 'Is Referrer':
          _localFilter = _localFilter.copyWith(
            isReferrer: true,
            onlyRecentlyAdded: false,
            hasWhatsapp: false,
            hasFamilyMembers: false,
          );
          break;
        case 'Has Family':
          _localFilter = _localFilter.copyWith(
            hasFamilyMembers: true,
            onlyRecentlyAdded: false,
            hasWhatsapp: false,
            isReferrer: false,
          );
          break;
        case 'All':
        default:
          _localFilter = _localFilter.copyWith(
            onlyRecentlyAdded: false,
            hasWhatsapp: false,
            isReferrer: false,
            hasFamilyMembers: false,
          );
          break;
      }
    });
  }

  void _updateGenderFilter(String selection) {
    setState(() {
      Set<Gender> genders = {};
      switch (selection) {
        case 'Male':
          genders.add(Gender.male);
          break;
        case 'Female':
          genders.add(Gender.female);
          break;
        case 'All Genders':
        default:
          genders = {};
          break;
      }
      _localFilter = _localFilter.copyWith(selectedGenders: genders);
    });
  }

  void _updateSortFilter(String selection) {
    setState(() {
      CustomerSortBy sortBy;
      switch (selection) {
        case 'Name (A-Z)':
          sortBy = CustomerSortBy.nameAZ;
          break;
        case 'Name (Z-A)':
          sortBy = CustomerSortBy.nameZA;
          break;
        case 'Bill Number (Low-High)':
          sortBy = CustomerSortBy.billNumberAsc;
          break;
        case 'Bill Number (High-Low)':
          sortBy = CustomerSortBy.billNumberDesc;
          break;
        case 'Oldest First':
          sortBy = CustomerSortBy.oldest;
          break;
        case 'Newest First':
        default:
          sortBy = CustomerSortBy.newest;
          break;
      }
      _localFilter = _localFilter.copyWith(sortBy: sortBy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(InventoryDesignConfig.radiusXL),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.fromLTRB(
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingS,
              InventoryDesignConfig.spacingL,
              InventoryDesignConfig.spacingL,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                  ),
                  child: Icon(
                    PhosphorIcons.funnel(),
                    size: 20,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter & Sort',
                        style: InventoryDesignConfig.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Refine your customer view',
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.surfaceLight,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusM,
                        ),
                      ),
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
          ),

          Container(height: 1, color: InventoryDesignConfig.borderSecondary),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Section
          _buildSection(
            title: 'Search',
            icon: PhosphorIcons.magnifyingGlass(),
            child: Container(
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
              ),
              child: TextField(
                controller: _searchController,
                style: InventoryDesignConfig.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, bill number...',
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
                  setState(() {
                    _localFilter = _localFilter.copyWith(searchQuery: value);
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Quick Filters
          _buildSection(
            title: 'Quick Filters',
            icon: PhosphorIcons.lightning(),
            child: _buildChipGroup(
              options: _quickFilterOptions,
              selectedOption: _getQuickFilterSelection(),
              onSelectionChanged: _updateQuickFilter,
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Gender Filter
          _buildSection(
            title: 'Gender',
            icon: PhosphorIcons.users(),
            child: _buildChipGroup(
              options: _genderOptions,
              selectedOption: _getGenderSelection(),
              onSelectionChanged: _updateGenderFilter,
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Date Range Section
          _buildSection(
            title: 'Date Range',
            icon: PhosphorIcons.calendar(),
            child: _buildDateRangeSelector(),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Advanced Filters
          _buildSection(
            title: 'Advanced Filters',
            icon: PhosphorIcons.gear(),
            child: _buildAdvancedFilters(),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Sort Options
          _buildSection(
            title: 'Sort By',
            icon: PhosphorIcons.sortAscending(),
            child: _buildChipGroup(
              options: _sortOptions,
              selectedOption: _getSortSelection(),
              onSelectionChanged: _updateSortFilter,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        child,
      ],
    );
  }

  Widget _buildChipGroup({
    required List<String> options,
    required String selectedOption,
    required Function(String) onSelectionChanged,
  }) {
    return Wrap(
      spacing: InventoryDesignConfig.spacingM,
      runSpacing: InventoryDesignConfig.spacingM,
      children:
          options.map((option) {
            final isSelected = selectedOption == option;

            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelectionChanged(option);
                },
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: InventoryDesignConfig.spacingL,
                    vertical: InventoryDesignConfig.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? InventoryDesignConfig.primaryColor
                            : InventoryDesignConfig.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color:
                          isSelected
                              ? InventoryDesignConfig.primaryColor
                              : InventoryDesignConfig.borderPrimary,
                    ),
                  ),
                  child: Text(
                    option,
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      color:
                          isSelected
                              ? InventoryDesignConfig.surfaceColor
                              : InventoryDesignConfig.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDateRangeSelector() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: _showDateRangePicker,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color:
                _localFilter.dateRange != null
                    ? InventoryDesignConfig.primaryColor.withOpacity(0.1)
                    : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color:
                  _localFilter.dateRange != null
                      ? InventoryDesignConfig.primaryColor
                      : InventoryDesignConfig.borderPrimary,
            ),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.calendar(),
                size: 20,
                color:
                    _localFilter.dateRange != null
                        ? InventoryDesignConfig.primaryColor
                        : InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Text(
                  _localFilter.dateRange != null
                      ? '${_formatDate(_localFilter.dateRange!.start)} - ${_formatDate(_localFilter.dateRange!.end)}'
                      : 'Select date range',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color:
                        _localFilter.dateRange != null
                            ? InventoryDesignConfig.primaryColor
                            : InventoryDesignConfig.textSecondary,
                    fontWeight:
                        _localFilter.dateRange != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                  ),
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(),
                size: 16,
                color:
                    _localFilter.dateRange != null
                        ? InventoryDesignConfig.primaryColor
                        : InventoryDesignConfig.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      children: [
        _buildAdvancedFilterToggle(
          title: 'Has Address',
          subtitle: 'Customers with complete address',
          icon: PhosphorIcons.mapPin(),
          value: _localFilter.hasAddress,
          onChanged: (value) {
            setState(() {
              _localFilter = _localFilter.copyWith(hasAddress: value);
            });
          },
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildAdvancedFilterToggle(
          title: 'With Family Network',
          subtitle: 'Customers with family connections',
          icon: PhosphorIcons.houseLine(),
          value: _localFilter.onlyWithFamily,
          onChanged: (value) {
            setState(() {
              _localFilter = _localFilter.copyWith(onlyWithFamily: value);
            });
          },
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildAdvancedFilterToggle(
          title: 'With Referrals',
          subtitle: 'Customers who were referred by others',
          icon: PhosphorIcons.arrowDown(),
          value: _localFilter.onlyWithReferrals,
          onChanged: (value) {
            setState(() {
              _localFilter = _localFilter.copyWith(onlyWithReferrals: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedFilterToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color:
                value
                    ? InventoryDesignConfig.primaryColor.withOpacity(0.1)
                    : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color:
                  value
                      ? InventoryDesignConfig.primaryColor
                      : InventoryDesignConfig.borderPrimary,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                decoration: BoxDecoration(
                  color:
                      value
                          ? InventoryDesignConfig.primaryColor.withOpacity(0.2)
                          : InventoryDesignConfig.textSecondary.withOpacity(
                            0.1,
                          ),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color:
                      value
                          ? InventoryDesignConfig.primaryColor
                          : InventoryDesignConfig.textSecondary,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color:
                            value
                                ? InventoryDesignConfig.primaryColor
                                : InventoryDesignConfig.textPrimary,
                        fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                      ),
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
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasActiveFilters = _localFilter.hasActiveFilters;

    return Container(
      padding: EdgeInsets.fromLTRB(
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingL + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          top: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (hasActiveFilters) ...[
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: InkWell(
                  onTap: _clearAllFilters,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: InventoryDesignConfig.spacingL,
                    ),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      border: Border.all(
                        color: InventoryDesignConfig.borderPrimary,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.arrowClockwise(),
                          size: 18,
                          color: InventoryDesignConfig.textSecondary,
                        ),
                        const SizedBox(width: InventoryDesignConfig.spacingS),
                        Text(
                          'Clear All',
                          style: InventoryDesignConfig.bodyMedium.copyWith(
                            color: InventoryDesignConfig.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
          ],
          Expanded(
            flex: hasActiveFilters ? 2 : 1,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: InkWell(
                onTap: _applyFilters,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: InventoryDesignConfig.spacingL,
                  ),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.check(),
                        size: 18,
                        color: InventoryDesignConfig.surfaceColor,
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingS),
                      Text(
                        hasActiveFilters
                            ? 'Apply Filters'
                            : 'Show All Customers',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.surfaceColor,
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
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _localFilter.dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: InventoryDesignConfig.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _localFilter = _localFilter.copyWith(dateRange: picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
