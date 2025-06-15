import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/customer.dart';
import '../../models/customer_filter.dart';
import '../../services/customer_service.dart';
import '../inventory/inventory_design_config.dart';
import 'add_customer_dialog.dart';
import 'customer_detail_dialog_desktop.dart';
import 'customer_filter_dialog.dart';

class CustomerDesktopView extends StatefulWidget {
  final CustomerFilter filter;
  final Function(CustomerFilter)? onFilterChanged;

  const CustomerDesktopView({
    super.key,
    required this.filter,
    this.onFilterChanged,
  });

  @override
  State<CustomerDesktopView> createState() => _CustomerDesktopViewState();
}

class _CustomerDesktopViewState extends State<CustomerDesktopView> {
  final SupabaseService _customerService = SupabaseService();
  String _sortColumn = 'created_at';
  bool _sortAscending = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<Customer> _customers = [];
  CustomerFilter _currentFilter = const CustomerFilter();

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filter;
    _searchQuery = _currentFilter.searchQuery;
    _searchController.text = _searchQuery;
    _sortColumn = _mapSortByToString(_currentFilter.sortBy);
    _sortAscending = _isSortAscending(_currentFilter.sortBy);
    _loadCustomers();
  }

  @override
  void didUpdateWidget(covariant CustomerDesktopView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter != oldWidget.filter) {
      _currentFilter = widget.filter;
      _searchQuery = _currentFilter.searchQuery;

      // Update TextField's text only if it differs from the new filter's search query.
      // This avoids interrupting user typing if widget.filter changes for other reasons
      // while the user is actively typing in the search field.
      if (_searchController.text != _searchQuery) {
        _searchController.text = _searchQuery;
      }

      _sortColumn = _mapSortByToString(_currentFilter.sortBy);
      _sortAscending = _isSortAscending(_currentFilter.sortBy);
      _loadCustomers();
    }
  }

  String _mapSortByToString(CustomerSortBy sortBy) {
    switch (sortBy) {
      case CustomerSortBy.nameAZ:
      case CustomerSortBy.nameZA:
        return 'name';
      case CustomerSortBy.billNumberAsc:
      case CustomerSortBy.billNumberDesc:
        return 'bill_number';
      case CustomerSortBy.newest:
      case CustomerSortBy.oldest:
        return 'created_at';
    }
  }

  bool _isSortAscending(CustomerSortBy sortBy) {
    switch (sortBy) {
      case CustomerSortBy.nameAZ:
      case CustomerSortBy.billNumberAsc:
      case CustomerSortBy.oldest:
        return true;
      case CustomerSortBy.nameZA:
      case CustomerSortBy.billNumberDesc:
      case CustomerSortBy.newest:
        return false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _customerService.getAllCustomers();

      var filteredCustomers =
          customers.where((customer) {
            // Enhanced search query filter - search by name, phone, and bill number
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase().trim();
              final nameMatch = customer.name.toLowerCase().contains(query);
              final phoneMatch = customer.phone
                  .replaceAll(RegExp(r'[^\d+]'), '')
                  .contains(query.replaceAll(RegExp(r'[^\d+]'), ''));
              final billNumberMatch = customer.billNumber
                  .toLowerCase()
                  .contains(query);
              final addressMatch = customer.address.toLowerCase().contains(
                query,
              );

              // If none of the fields match, filter out this customer
              if (!nameMatch &&
                  !phoneMatch &&
                  !billNumberMatch &&
                  !addressMatch) {
                return false;
              }
            }

            // Gender filter
            if (_currentFilter.selectedGenders.isNotEmpty &&
                !_currentFilter.selectedGenders.contains(customer.gender)) {
              return false;
            }

            // Date range filter
            if (_currentFilter.dateRange != null) {
              final customerDate = DateUtils.dateOnly(customer.createdAt);
              final startDate = DateUtils.dateOnly(
                _currentFilter.dateRange!.start,
              );
              final endDate = DateUtils.dateOnly(_currentFilter.dateRange!.end);

              if (customerDate.isBefore(startDate) ||
                  customerDate.isAfter(endDate)) {
                return false;
              }
            } else if (_currentFilter.dateRange != null &&
                // ignore: unnecessary_null_comparison
                customer.createdAt == null) {
              return false;
            }

            // onlyWithFamily filter
            if (_currentFilter.onlyWithFamily && customer.familyId == null) {
              return false;
            }

            // onlyWithReferrals filter (customer was referred by someone)
            if (_currentFilter.onlyWithReferrals &&
                customer.referredBy == null) {
              return false;
            }

            // isReferrer filter (customer has referred others)
            if (_currentFilter.isReferrer && (customer.referralCount <= 0)) {
              return false;
            }

            // onlyRecentlyAdded filter
            if (_currentFilter.onlyRecentlyAdded) {
              final today = DateUtils.dateOnly(DateTime.now());
              final firstDayOfRecentPeriod = today.subtract(
                const Duration(days: 6),
              );
              final customerCreationDate = DateUtils.dateOnly(
                customer.createdAt,
              );
              if (customerCreationDate.isBefore(firstDayOfRecentPeriod)) {
                return false;
              }
            }

            // hasWhatsapp filter
            if (_currentFilter.hasWhatsapp &&
                (customer.whatsapp.trim().isEmpty)) {
              return false;
            }

            // hasAddress filter
            if (_currentFilter.hasAddress && customer.address.trim().isEmpty) {
              return false;
            }

            // hasFamilyMembers filter:
            if (_currentFilter.hasFamilyMembers && customer.familyId == null) {
              return false;
            }

            return true;
          }).toList();

      // Apply sorting
      filteredCustomers.sort((a, b) {
        int comparison;
        switch (_sortColumn) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'bill_number':
            comparison = a.billNumber.compareTo(b.billNumber);
            break;
          case 'phone':
            comparison = a.phone.compareTo(b.phone);
            break;
          case 'address':
            comparison = a.address.compareTo(b.address);
            break;
          case 'gender':
            comparison = a.gender.name.compareTo(b.gender.name);
            break;
          case 'created_at':
          default:
            // Compare createdAt dates directly since they are non-nullable
            final aDate = a.createdAt;
            final bDate = b.createdAt;
            comparison = aDate.compareTo(bDate);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });

      setState(() {
        _customers = filteredCustomers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customers: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  void _onSort(String column) {
    CustomerSortBy newSortBy;
    bool newAscending;

    if (_sortColumn == column) {
      newAscending = !_sortAscending;
    } else {
      newAscending = true;
    }

    switch (column) {
      case 'name':
        newSortBy =
            newAscending ? CustomerSortBy.nameAZ : CustomerSortBy.nameZA;
        break;
      case 'bill_number':
        newSortBy =
            newAscending
                ? CustomerSortBy.billNumberAsc
                : CustomerSortBy.billNumberDesc;
        break;
      case 'created_at':
      default:
        newSortBy =
            newAscending ? CustomerSortBy.oldest : CustomerSortBy.newest;
        break;
    }

    _currentFilter = _currentFilter.copyWith(sortBy: newSortBy);
    widget.onFilterChanged?.call(_currentFilter);
    // _loadCustomers will be called by didUpdateWidget due to filter change
  }

  // This method is called when the search text field content changes.
  void _onSearchTextChanged(String text) {
    if (_searchQuery == text) return;

    setState(() {
      _searchQuery = text; // Update local state for _loadCustomers
    });

    // Update _currentFilter state and notify parent.
    // This will trigger didUpdateWidget, which calls _loadCustomers.
    _currentFilter = _currentFilter.copyWith(searchQuery: text);
    widget.onFilterChanged?.call(_currentFilter);
  }

  void _showFilterDialog() async {
    final result = await showDialog<CustomerFilter>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: InventoryDesignConfig.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          ),
          child: CustomerFilterDialog(
            filter: _currentFilter,
            onFilterChanged: (newFilter) {
              // No need to call _loadCustomers here,
              // as _currentFilter update and onFilterChanged will trigger didUpdateWidget
              _currentFilter = newFilter;
              widget.onFilterChanged?.call(_currentFilter);
              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    AddCustomerDialog.show(context, onCustomerAdded: _loadCustomers);
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    AddCustomerDialog.show(
      context,
      customer: customer,
      isEditing: true,
      onCustomerAdded: _loadCustomers,
    );
  }

  void _showCustomerDetailsDialog(BuildContext context, Customer customer) {
    CustomerDetailDialogDesktop.show(
      context,
      customer: customer,
      onCustomerUpdated: _loadCustomers,
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
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text('Delete Customer', style: InventoryDesignConfig.titleLarge),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${customer.name}?',
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
        await _customerService.deleteCustomer(customer.id);
        _loadCustomers(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${customer.name} deleted successfully.'),
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
              content: Text('Error deleting customer: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.backgroundColor,
      ),
      child: Column(
        children: [
          // Compact header section with title and controls - matching inventory design
          Container(
            decoration: const BoxDecoration(
              color: InventoryDesignConfig.backgroundColor,
            ),
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
            child: Column(
              children: [
                // Main header row - compact design matching inventory
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title section - matching inventory layout
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
                            PhosphorIcons.users(),
                            size: 22,
                            color: InventoryDesignConfig.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Management',
                              style: InventoryDesignConfig.headlineLarge
                                  .copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                            Text(
                              'Manage customer information',
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

                    // Right side controls - in a single row matching inventory
                    Row(
                      children: [
                        _buildSearchField(),
                        const SizedBox(width: 12),
                        _buildModernFilterButton(),
                        const SizedBox(width: 12),
                        _buildModernPrimaryButton(
                          icon: PhosphorIcons.plus(),
                          label: 'Add Customer',
                          onPressed: () => _showAddCustomerDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats row - matching inventory design
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
                child:
                    _isLoading ? _buildLoadingState() : _buildCustomerTable(),
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
          hintText: 'Search by name, phone, or bill number...',
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
                      _onSearchTextChanged('');
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: _onSearchTextChanged,
      ),
    );
  }

  Widget _buildModernFilterButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: _showFilterDialog,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          height: 40, // Match other elements height
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: InventoryDesignConfig.buttonSecondaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.funnel(),
                size: 16,
                color:
                    _currentFilter.hasActiveFilters
                        ? InventoryDesignConfig.primaryAccent
                        : InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                'Filter',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color:
                      _currentFilter.hasActiveFilters
                          ? InventoryDesignConfig.primaryAccent
                          : InventoryDesignConfig.textSecondary,
                ),
              ),
              if (_currentFilter.hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.only(
                    left: InventoryDesignConfig.spacingXS,
                  ),
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

  Widget _buildModernStatsRow() {
    final totalCustomers = _customers.length;
    final maleCustomers =
        _customers.where((c) => c.gender == Gender.male).length;
    final femaleCustomers =
        _customers.where((c) => c.gender == Gender.female).length;
    final recentCustomers =
        _customers.where((customer) {
          final today = DateUtils.dateOnly(DateTime.now());
          final firstDayOfRecentPeriod = today.subtract(
            const Duration(days: 7),
          );
          final customerCreationDate = DateUtils.dateOnly(customer.createdAt);
          return !customerCreationDate.isBefore(firstDayOfRecentPeriod);
        }).length;

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Row(
        children: [
          _buildModernStatCard(
            title: 'Total Customers',
            value: totalCustomers.toString(),
            icon: PhosphorIcons.users(),
            color: InventoryDesignConfig.primaryAccent,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Male',
            value: maleCustomers.toString(),
            icon: PhosphorIcons.user(),
            color: InventoryDesignConfig.infoColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Female',
            value: femaleCustomers.toString(),
            icon: PhosphorIcons.user(),
            color: InventoryDesignConfig.successColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Recent (7 days)',
            value: recentCustomers.toString(),
            icon: PhosphorIcons.clockClockwise(),
            color: InventoryDesignConfig.warningColor,
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
                  PhosphorIcons.users(),
                  size: 14,
                  color: InventoryDesignConfig.primaryColor,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingXS),
                Text(
                  'Customer Management',
                  style: InventoryDesignConfig.bodySmall.copyWith(
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

  Widget _buildCustomerTable() {
    if (_customers.isEmpty) {
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
              _buildDataColumn('Bill #', 'bill_number'),
              _buildDataColumn('Name', 'name'),
              _buildDataColumn('Phone', 'phone'),
              _buildDataColumn('Address', 'address'),
              _buildDataColumn('Gender', 'gender'),
              _buildDataColumn('Created', 'created_at'),
              const DataColumn(label: Text('')), // Actions
            ],
            rows:
                _customers
                    .map((customer) => _buildCustomerRow(customer))
                    .toList(),
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
            'Loading customers...',
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
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          if (_searchQuery.isNotEmpty || _currentFilter.hasActiveFilters)
            _buildModernPrimaryButton(
              icon: PhosphorIcons.arrowClockwise(),
              label: 'Clear Filters/Search',
              onPressed: () {
                _searchController.clear();
                _currentFilter = const CustomerFilter();
                widget.onFilterChanged?.call(_currentFilter);
              },
            )
          else
            _buildModernPrimaryButton(
              icon: PhosphorIcons.plus(),
              label: 'Add Customer',
              onPressed: () => _showAddCustomerDialog(context),
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

  DataRow _buildCustomerRow(Customer customer) {
    return DataRow(
      cells: [
        DataCell(_buildBillNumberCell(customer.billNumber)),
        DataCell(_buildNameCell(customer.name, customer.gender)),
        DataCell(_buildPhoneCell(customer.phone, customer.whatsapp)),
        DataCell(_buildAddressCell(customer.address)),
        DataCell(_buildGenderCell(customer.gender)),
        DataCell(_buildDateCell(customer.createdAt)),
        DataCell(_buildActionsCell(customer)),
      ],
      onSelectChanged: (selected) {
        if (selected == true) _showCustomerDetailsDialog(context, customer);
      },
    );
  }

  Widget _buildBillNumberCell(String billNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      ),
      child: _buildHighlightedText(
        text: billNumber,
        style: InventoryDesignConfig.code,
        searchQuery: _searchQuery,
      ),
    );
  }

  Widget _buildNameCell(String name, Gender gender) {
    final genderColor =
        gender == Gender.male
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: genderColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
            border: Border.all(color: genderColor, width: 1),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: InventoryDesignConfig.titleMedium.copyWith(
                color: genderColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingM),
        Expanded(
          child: _buildHighlightedText(
            text: name,
            style: InventoryDesignConfig.titleMedium,
            searchQuery: _searchQuery,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneCell(String phone, String? whatsapp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.phone(),
              size: 12,
              color: InventoryDesignConfig.textSecondary,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingXS),
            Flexible(
              child: _buildHighlightedText(
                text: phone,
                style: InventoryDesignConfig.bodyLarge,
                searchQuery: _searchQuery,
              ),
            ),
          ],
        ),
        if (whatsapp != null && whatsapp.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.whatsappLogo(),
                size: 12,
                color: InventoryDesignConfig.successColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                'WhatsApp',
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAddressCell(String address) {
    return _buildHighlightedText(
      text: address,
      style: InventoryDesignConfig.bodyLarge,
      searchQuery: _searchQuery,
      maxLines: 2,
    );
  }

  Widget _buildGenderCell(Gender gender) {
    final genderColor =
        gender == Gender.male
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: genderColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      ),
      child: Text(
        gender.name.toUpperCase(),
        style: InventoryDesignConfig.bodySmall.copyWith(
          color: genderColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateCell(DateTime? date) {
    if (date == null) {
      return Text(
        'N/A',
        style: InventoryDesignConfig.bodyLarge.copyWith(
          color: InventoryDesignConfig.textTertiary,
        ),
      );
    }
    return Text(
      DateFormat('MMM d, y').format(date),
      style: InventoryDesignConfig.bodyLarge,
    );
  }

  Widget _buildActionsCell(Customer customer) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionIcon(
          icon: PhosphorIcons.pencilSimple(),
          onTap: () => _showEditCustomerDialog(context, customer),
          color: InventoryDesignConfig.primaryAccent,
          tooltip: 'Edit Customer',
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        _buildActionIcon(
          icon: PhosphorIcons.trash(),
          onTap: () => _confirmDeleteCustomer(context, customer),
          color: InventoryDesignConfig.errorColor,
          tooltip: 'Delete Customer',
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

  Widget _buildHighlightedText({
    required String text,
    required TextStyle style,
    required String searchQuery,
    int? maxLines,
  }) {
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    final query = searchQuery.toLowerCase().trim();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];

    int currentIndex = 0;
    while (currentIndex < text.length) {
      final matchIndex = textLower.indexOf(query, currentIndex);

      if (matchIndex == -1) {
        // No more matches, add the rest of the text
        spans.add(TextSpan(text: text.substring(currentIndex), style: style));
        break;
      }

      // Add text before the match
      if (matchIndex > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, matchIndex),
            style: style,
          ),
        );
      }

      // Add the highlighted match
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + query.length),
          style: style.copyWith(
            backgroundColor: InventoryDesignConfig.warningColor.withOpacity(
              0.3,
            ),
            fontWeight: FontWeight.w700,
            color: InventoryDesignConfig.warningColor,
          ),
        ),
      );

      currentIndex = matchIndex + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}
