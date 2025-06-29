import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/customer.dart';
import '../../../theme/inventory_design_config.dart';

class CustomerSelectorDialog extends StatefulWidget {
  final List<Customer> customers;
  final Function(Customer) onSelect;

  const CustomerSelectorDialog({
    super.key,
    required this.customers,
    required this.onSelect,
  });

  static Future<Customer?> show(
    BuildContext context,
    List<Customer> customers,
  ) {
    return showDialog<Customer>(
      context: context,
      builder:
          (context) => CustomerSelectorDialog(
            customers: customers,
            onSelect: (customer) => Navigator.pop(context, customer),
          ),
    );
  }

  @override
  State<CustomerSelectorDialog> createState() => _CustomerSelectorDialogState();
}

class _CustomerSelectorDialogState extends State<CustomerSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredCustomers =
          widget.customers.where((customer) {
            return customer.name.toLowerCase().contains(_searchQuery) ||
                customer.phone.toLowerCase().contains(_searchQuery) ||
                customer.billNumber.toLowerCase().contains(_searchQuery);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 700,
        decoration: BoxDecoration(
          color: InventoryDesignConfig.surfaceColor,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
          border: Border.all(color: InventoryDesignConfig.borderPrimary),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildCustomerList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
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
          Icon(
            PhosphorIcons.users(),
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Text('Select Customer', style: InventoryDesignConfig.titleLarge),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(PhosphorIcons.x()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, bill number, or phone...',
          prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
    if (_filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.users(),
              size: 48,
              color: InventoryDesignConfig.textTertiary,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Text(
              'No customers found',
              style: InventoryDesignConfig.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  customer.gender == Gender.male
                      ? InventoryDesignConfig.infoColor.withOpacity(0.1)
                      : InventoryDesignConfig.successColor.withOpacity(0.1),
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color:
                      customer.gender == Gender.male
                          ? InventoryDesignConfig.infoColor
                          : InventoryDesignConfig.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(customer.name),
            subtitle: Text('#${customer.billNumber} • ${customer.phone}'),
            onTap: () => Navigator.pop(context, customer),
          ),
        );
      },
    );
  }
}
