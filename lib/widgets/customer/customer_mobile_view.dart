import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/customer.dart';
import '../../models/customer_filter.dart';
import '../../services/customer_service.dart';
import '../inventory/inventory_design_config.dart'; // Using InventoryDesignConfig
import 'add_customer_mobile_sheet.dart';
import 'customer_detail_dialog.dart';
import 'customer_filter_sheet.dart'; // For filter sheet

class CustomerMobileView extends StatefulWidget {
  final CustomerFilter filter;
  final Function(CustomerFilter)? onFilterChanged;

  const CustomerMobileView({
    super.key,
    required this.filter,
    this.onFilterChanged,
  });

  @override
  State<CustomerMobileView> createState() => _CustomerMobileViewState();
}

class _CustomerMobileViewState extends State<CustomerMobileView>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _customerService = SupabaseService();

  String _searchQuery = '';
  bool _isLoading = false;
  List<Customer> _customers = [];
  CustomerFilter _currentFilter = const CustomerFilter();

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

    _loadCustomers();
  }

  @override
  void didUpdateWidget(covariant CustomerMobileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter != oldWidget.filter) {
      _currentFilter = widget.filter;
      _searchQuery = _currentFilter.searchQuery;
      _searchController.text = _searchQuery;
      _loadCustomers();
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

  Future<void> _loadCustomers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final allCustomers = await _customerService.getAllCustomers();

      List<Customer> filteredCustomers =
          allCustomers.where((customer) {
            final searchLower = _searchQuery.toLowerCase();
            bool matchesSearch =
                _searchQuery.isEmpty ||
                customer.name.toLowerCase().contains(searchLower) ||
                customer.phone.contains(searchLower) ||
                customer.billNumber.contains(searchLower);

            bool matchesDate = true;
            if (_currentFilter.dateRange != null) {
              matchesDate =
                  !customer.createdAt.isBefore(
                    _currentFilter.dateRange!.start,
                  ) &&
                  !customer.createdAt.isAfter(
                    _currentFilter.dateRange!.end.add(const Duration(days: 1)),
                  );
            }

            bool matchesWhatsapp =
                !_currentFilter.hasWhatsapp || customer.whatsapp.isNotEmpty;
            bool matchesReferrer =
                !_currentFilter.isReferrer || (customer.referralCount > 0);
            bool matchesFamily =
                !_currentFilter.hasFamilyMembers ||
                (customer.familyId?.isNotEmpty ?? false);

            return matchesSearch &&
                matchesDate &&
                matchesWhatsapp &&
                matchesReferrer &&
                matchesFamily;
          }).toList();

      // Apply sorting
      filteredCustomers.sort((a, b) {
        int comparison = 0;
        switch (_currentFilter.sortBy) {
          case CustomerSortBy.nameAZ:
            comparison = a.name.compareTo(b.name);
            break;
          case CustomerSortBy.nameZA:
            comparison = b.name.compareTo(a.name);
            break;
          case CustomerSortBy.billNumberAsc:
            comparison = a.billNumber.compareTo(b.billNumber);
            break;
          case CustomerSortBy.billNumberDesc:
            comparison = b.billNumber.compareTo(a.billNumber);
            break;
          case CustomerSortBy.oldest:
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case CustomerSortBy.newest:
            comparison = b.createdAt.compareTo(a.createdAt);
            break;
        }
        return comparison;
      });

      if (mounted) {
        setState(() {
          _customers = filteredCustomers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customers: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _currentFilter = _currentFilter.copyWith(searchQuery: query);
    widget.onFilterChanged?.call(_currentFilter);
    _loadCustomers();
  }

  void _showFilterBottomSheet() {
    CustomerFilterSheet.show(context, _currentFilter, (newFilter) {
      _currentFilter = newFilter;
      widget.onFilterChanged?.call(_currentFilter);
      _loadCustomers();
    });
  }

  // Action methods
  void _showAddCustomerSheet() {
    AddCustomerMobileSheet.show(context, onCustomerAdded: _loadCustomers);
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
          Expanded(child: _buildCustomerList()),
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
                                  PhosphorIcons.users(),
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
                                      'Customers',
                                      style:
                                          InventoryDesignConfig.headlineMedium,
                                    ),
                                    Text(
                                      'Manage customer records',
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
                        hintText: 'Search customers...',
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
                          vertical: InventoryDesignConfig.spacingM - 1,
                        ), // Adjust to center text
                      ),
                      onChanged: _onSearchChanged,
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
                        if (_currentFilter.hasActiveFilters)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: InventoryDesignConfig.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    _buildHeaderIconButton(
                      icon: PhosphorIcons.plus(),
                      onTap: () => _showAddCustomerSheet(),
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
    if (!_isSearchExpanded || _searchQuery.isEmpty) {
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
    // This can be expanded to show more active filters from _currentFilter
    if (_searchQuery.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Text(
          'Searching for:',
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingM,
            vertical: InventoryDesignConfig.spacingXS,
          ),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.primaryAccent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '"$_searchQuery"',
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.surfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: Icon(
                  PhosphorIcons.x(),
                  size: 12,
                  color: InventoryDesignConfig.surfaceColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsBar() {
    final totalCustomers = _customers.length;
    final maleCustomers =
        _customers.where((c) => c.gender == Gender.male).length;
    final femaleCustomers =
        _customers.where((c) => c.gender == Gender.female).length;

    return Container(
      color: InventoryDesignConfig.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingL,
        vertical: InventoryDesignConfig.spacingM,
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: PhosphorIcons.users(),
            label: 'Total',
            value: '$totalCustomers',
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          _buildStatItem(
            icon: PhosphorIcons.user(),
            label: 'Male',
            value: '$maleCustomers',
            color: InventoryDesignConfig.infoColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          _buildStatItem(
            icon: PhosphorIcons.user(),
            label: 'Female',
            value: '$femaleCustomers',
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

  Widget _buildCustomerList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: InventoryDesignConfig.primaryColor,
        ),
      );
    }
    if (_customers.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      color: InventoryDesignConfig.primaryColor,
      onRefresh: _loadCustomers,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          InventoryDesignConfig.spacingL,
          InventoryDesignConfig.spacingS,
          InventoryDesignConfig.spacingL,
          InventoryDesignConfig.spacingXL,
        ),
        itemCount: _customers.length,
        itemBuilder: (context, index) => _buildCustomerCard(_customers[index]),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final genderColor =
        customer.gender == Gender.male
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;
    return Container(
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        child: InkWell(
          onTap: () => _showCustomerDetailsDialog(context, customer),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: genderColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusM,
                        ),
                        border: Border.all(color: genderColor, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : '?',
                          style: InventoryDesignConfig.titleLarge.copyWith(
                            color: genderColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: InventoryDesignConfig.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(
                            height: InventoryDesignConfig.spacingXS,
                          ),
                          Row(
                            children: [
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
                                  customer.billNumber,
                                  style: InventoryDesignConfig.code.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: InventoryDesignConfig.spacingS,
                              ),
                              Icon(
                                PhosphorIcons.phone(),
                                size: 12,
                                color: InventoryDesignConfig.textSecondary,
                              ),
                              const SizedBox(
                                width: InventoryDesignConfig.spacingXS,
                              ),
                              Expanded(
                                child: Text(
                                  customer.phone,
                                  style: InventoryDesignConfig.bodySmall
                                      .copyWith(
                                        color:
                                            InventoryDesignConfig.textSecondary,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: InventoryDesignConfig.spacingS,
                            vertical: InventoryDesignConfig.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: genderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              InventoryDesignConfig.radiusS,
                            ),
                          ),
                          child: Text(
                            customer.gender.name.toUpperCase(),
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color: genderColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: InventoryDesignConfig.spacingS),
                        _buildCardActionButton(
                          PhosphorIcons.dotsThreeVertical(),
                          () => _showCustomerActions(context, customer),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.mapPin(),
                      size: 14,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Expanded(
                      child: Text(
                        customer.address,
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildCardActionButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        child: Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: Icon(
            icon,
            size: 16,
            color: InventoryDesignConfig.textSecondary,
          ),
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
                PhosphorIcons.users(),
                size: 48,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
            Text(
              'No customers found',
              style: InventoryDesignConfig.headlineMedium,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              _searchQuery.isNotEmpty || _currentFilter.hasActiveFilters
                  ? 'Try adjusting your search or filters'
                  : 'Add your first customer to get started',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            if (_searchQuery.isNotEmpty || _currentFilter.hasActiveFilters)
              _buildEmptyStateButton(
                icon: PhosphorIcons.arrowClockwise(),
                label: 'Clear Filters/Search',
                onPressed: () {
                  _searchController.clear();
                  _currentFilter = const CustomerFilter();
                  widget.onFilterChanged?.call(_currentFilter);
                  _loadCustomers();
                },
                isPrimary: false,
              )
            else
              _buildEmptyStateButton(
                icon: PhosphorIcons.plus(),
                label: 'Add Customer',
                onPressed: _showAddCustomerSheet,
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

  void _showCustomerActions(BuildContext context, Customer customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(InventoryDesignConfig.radiusL),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: InventoryDesignConfig.spacingM,
                    bottom: InventoryDesignConfig.spacingS,
                  ),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.borderPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.user(),
                        color: InventoryDesignConfig.primaryColor,
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingM),
                      Expanded(
                        child: Text(
                          customer.name,
                          style: InventoryDesignConfig.titleMedium.copyWith(
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
                  leading: Icon(
                    PhosphorIcons.eye(),
                    color: InventoryDesignConfig.textSecondary,
                  ),
                  title: Text(
                    'View Details',
                    style: InventoryDesignConfig.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomerDetailsDialog(context, customer);
                  },
                ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.pencilSimple(),
                    color: InventoryDesignConfig.textSecondary,
                  ),
                  title: Text(
                    'Edit Customer',
                    style: InventoryDesignConfig.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    AddCustomerMobileSheet.show(
                      context,
                      customer: customer,
                      index: _customers.indexOf(customer),
                      isEditing: true,
                      onCustomerAdded: _loadCustomers,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.trash(),
                    color: InventoryDesignConfig.errorColor,
                  ),
                  title: Text(
                    'Delete Customer',
                    style: InventoryDesignConfig.bodyLarge.copyWith(
                      color: InventoryDesignConfig.errorColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteCustomer(context, customer);
                  },
                ),
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom +
                      InventoryDesignConfig.spacingS,
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _confirmDeleteCustomer(
    BuildContext context,
    Customer customer,
  ) async {
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
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Text('Delete Customer', style: InventoryDesignConfig.titleLarge),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${customer.name}?',
            style: InventoryDesignConfig.bodyLarge,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel', style: InventoryDesignConfig.bodyMedium),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: Icon(PhosphorIcons.trash()),
              label: const Text('Delete'),
              style: FilledButton.styleFrom(
                backgroundColor: InventoryDesignConfig.errorColor,
                foregroundColor: InventoryDesignConfig.surfaceColor,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _customerService.deleteCustomer(customer.id);
        _loadCustomers(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${customer.name} deleted successfully'),
              backgroundColor: InventoryDesignConfig.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting customer: ${e.toString()}'),
              backgroundColor: InventoryDesignConfig.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCustomerDetailsDialog(
    BuildContext context,
    Customer customer,
  ) {
    return showDialog(
      context: context,
      builder: (context) => CustomerDetailDialog(customer: customer),
    );
  }
}
