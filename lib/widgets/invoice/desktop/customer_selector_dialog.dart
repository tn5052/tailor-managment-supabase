import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/customer.dart'; // Assuming a Customer model exists

class CustomerSelectorDialog extends StatefulWidget {
  final String? selectedCustomerId;
  final Function(Customer customer) onCustomerSelected;

  const CustomerSelectorDialog({
    super.key,
    this.selectedCustomerId,
    required this.onCustomerSelected,
  });

  static Future<void> show(
    BuildContext context, {
    String? selectedCustomerId,
    required Function(Customer customer) onCustomerSelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomerSelectorDialog(
        selectedCustomerId: selectedCustomerId,
        onCustomerSelected: onCustomerSelected,
      ),
    );
  }

  @override
  State<CustomerSelectorDialog> createState() => _CustomerSelectorDialogState();
}

class _CustomerSelectorDialogState extends State<CustomerSelectorDialog> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _listFocusNode = FocusNode();

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String? _currentSelectedCustomerId;
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    _currentSelectedCustomerId = widget.selectedCustomerId;
    _loadCustomers();
    // Request focus on the search field when the dialog opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _listFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('customers')
          .select('id, name, phone, bill_number, created_at, gender') // Select necessary customer fields
          .order('name');

      setState(() {
        _customers = List<Customer>.from(response.map((map) => Customer.fromMap(map)));
        _filteredCustomers = _customers;
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

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers
            .where((customer) =>
                customer.name.toLowerCase().contains(query.toLowerCase()) ||
                customer.phone.toLowerCase().contains(query.toLowerCase()) ||
                customer.billNumber.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          if (_filteredCustomers.isNotEmpty) {
            _highlightedIndex = (_highlightedIndex + 1) % _filteredCustomers.length;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          if (_filteredCustomers.isNotEmpty) {
            _highlightedIndex = (_highlightedIndex - 1 + _filteredCustomers.length) % _filteredCustomers.length;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_highlightedIndex != -1 && _highlightedIndex < _filteredCustomers.length) {
          _selectCustomer(_filteredCustomers[_highlightedIndex]);
        } else if (_currentSelectedCustomerId != null) {
          final selectedCustomer = _customers.firstWhere(
            (customer) => customer.id == _currentSelectedCustomerId,
          );
          _selectCustomer(selectedCustomer);
        }
      }
    }
  }

  void _selectCustomer(Customer customer) {
    Navigator.of(context).pop();
    widget.onCustomerSelected(customer);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 550,
            maxHeight: screenSize.height * 0.75,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
              border: Border.all(color: InventoryDesignConfig.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
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
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
            ),
            child: Icon(
              PhosphorIcons.users(),
              size: 18,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Text(
              'Select Customer',
              style: InventoryDesignConfig.headlineMedium,
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
          child: Container(
            decoration: InventoryDesignConfig.inputDecoration,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: InventoryDesignConfig.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                hintStyle: InventoryDesignConfig.bodyMedium,
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
                  horizontal: InventoryDesignConfig.spacingL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
              ),
              onChanged: (query) {
                _filterCustomers(query);
                setState(() {
                  _highlightedIndex = _filteredCustomers.isNotEmpty ? 0 : -1;
                });
              },
              onSubmitted: (_) {
                if (_highlightedIndex != -1 && _highlightedIndex < _filteredCustomers.length) {
                  _selectCustomer(_filteredCustomers[_highlightedIndex]);
                }
              },
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingXXL,
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: InventoryDesignConfig.primaryAccent,
                    ),
                  )
                : _filteredCustomers.isEmpty
                    ? _buildEmptyState()
                    : _buildCustomersList(),
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
            ),
            child: Icon(
              PhosphorIcons.users(),
              size: 32,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Text('No customers found', style: InventoryDesignConfig.titleMedium),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search or add a new customer'
                : 'Add customers to get started',
            style: InventoryDesignConfig.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    return Focus(
      focusNode: _listFocusNode,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _filteredCustomers.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: InventoryDesignConfig.spacingXS),
        itemBuilder: (context, index) {
          final customer = _filteredCustomers[index];
          final isSelected = customer.id == _currentSelectedCustomerId;
          final isHighlighted = index == _highlightedIndex;

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              onTap: () {
                setState(() {
                  _currentSelectedCustomerId = customer.id;
                  _highlightedIndex = index;
                });
              },
              onDoubleTap: () => _selectCustomer(customer),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? InventoryDesignConfig.primaryColor.withOpacity(0.2)
                      : isSelected
                          ? InventoryDesignConfig.primaryColor.withOpacity(0.08)
                          : InventoryDesignConfig.surfaceAccent,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  border: Border.all(
                    color: isHighlighted || isSelected
                        ? InventoryDesignConfig.primaryColor
                        : InventoryDesignConfig.borderSecondary,
                    width: isHighlighted || isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? InventoryDesignConfig.primaryColor
                            : InventoryDesignConfig.surfaceColor,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? InventoryDesignConfig.primaryColor
                              : InventoryDesignConfig.borderPrimary,
                        ),
                      ),
                      child: Icon(
                        PhosphorIcons.user(), // Use generic user icon
                        size: 18,
                        color: isSelected ? Colors.white : InventoryDesignConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${customer.name} (${customer.phone})',
                            style: InventoryDesignConfig.titleMedium.copyWith(
                              color: isSelected
                                  ? InventoryDesignConfig.primaryColor
                                  : InventoryDesignConfig.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Bill No: ${customer.billNumber}',
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color: isSelected
                                  ? InventoryDesignConfig.primaryColor.withOpacity(0.8)
                                  : InventoryDesignConfig.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(
                          InventoryDesignConfig.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: InventoryDesignConfig.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIcons.check(),
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
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
                  'Cancel',
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
              onTap: _currentSelectedCustomerId != null
                  ? () {
                      final selectedCustomer = _customers.firstWhere(
                        (customer) => customer.id == _currentSelectedCustomerId,
                      );
                      _selectCustomer(selectedCustomer);
                    }
                  : null,
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
                      'Select Customer',
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
}
