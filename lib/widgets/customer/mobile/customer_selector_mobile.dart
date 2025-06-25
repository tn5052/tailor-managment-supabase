import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/customer.dart';
import '../../../theme/inventory_design_config.dart';

class CustomerSelectorMobile extends StatefulWidget {
  final List<Customer> customers;

  const CustomerSelectorMobile({super.key, required this.customers});

  static Future<Customer?> show(
    BuildContext context,
    List<Customer> customers,
  ) {
    return showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerSelectorMobile(customers: customers),
    );
  }

  @override
  State<CustomerSelectorMobile> createState() => _CustomerSelectorMobileState();
}

class _CustomerSelectorMobileState extends State<CustomerSelectorMobile> {
  final _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers =
          widget.customers.where((customer) {
            return customer.name.toLowerCase().contains(query) ||
                customer.billNumber.toLowerCase().contains(query) ||
                customer.phone.toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(child: _buildCustomerList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Row(
            children: [
              Icon(
                PhosphorIcons.users(),
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Customer',
                      style: InventoryDesignConfig.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${widget.customers.length} customers available',
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
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Container(
        decoration: BoxDecoration(
          color: InventoryDesignConfig.surfaceLight,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          border: Border.all(color: InventoryDesignConfig.borderPrimary),
        ),
        child: TextField(
          controller: _searchController,
          style: InventoryDesignConfig.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search by name, bill number, or phone...',
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
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
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
    if (_filteredCustomers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        InventoryDesignConfig.spacingL,
        0,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingL,
      ),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return _buildCustomerCard(customer);
      },
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
          onTap: () => Navigator.of(context).pop(customer),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: genderColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(color: genderColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        color: genderColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: InventoryDesignConfig.spacingM),

                // Customer Info
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
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: InventoryDesignConfig.spacingS,
                              vertical: InventoryDesignConfig.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: InventoryDesignConfig.primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                InventoryDesignConfig.radiusS,
                              ),
                            ),
                            child: Text(
                              '#${customer.billNumber}',
                              style: InventoryDesignConfig.bodySmall.copyWith(
                                color: InventoryDesignConfig.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: InventoryDesignConfig.spacingS),
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
                        ],
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        customer.phone,
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  PhosphorIcons.caretRight(),
                  size: 16,
                  color: InventoryDesignConfig.textSecondary,
                ),
              ],
            ),
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
                PhosphorIcons.userMinus(),
                size: 48,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            Text(
              'No customers found',
              style: InventoryDesignConfig.headlineMedium,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'No customers available to select',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
