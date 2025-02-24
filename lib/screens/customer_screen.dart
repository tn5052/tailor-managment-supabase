import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/customer_filter.dart';
import '../services/supabase_service.dart';
import '../widgets/customer/add_customer_dialog.dart';
import '../widgets/customer/customer_list.dart';
import '../models/layout_type.dart';
import '../widgets/customer/customer_filter_sheet.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CustomerLayoutType _layoutType = CustomerLayoutType.list;
  CustomerFilter _filter = const CustomerFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildLayoutToggle() {
    return SegmentedButton<CustomerLayoutType>(
      segments: CustomerLayoutType.values.map((type) => ButtonSegment(
        value: type,
        icon: Icon(type.icon),
        label: Text(type.name.toUpperCase()),
      )).toList(),
      selected: {_layoutType},
      onSelectionChanged: (Set<CustomerLayoutType> selection) {
        setState(() => _layoutType = selection.first);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customers',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: !isDesktop,
        actions: [
          if (isDesktop) ...[
            _buildLayoutToggle(),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () => _showAddCustomerDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Customer'),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {
                        _searchQuery = value;
                        _filter = _filter.copyWith(searchQuery: value);
                      }),
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, or bill number',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _filter = _filter.copyWith(searchQuery: '');
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => CustomerFilterSheet.show(
                          context,
                          _filter,
                          (newFilter) => setState(() => _filter = newFilter),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: _filter.hasActiveFilters
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              if (_filter.hasActiveFilters)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
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
            ),
            const SizedBox(height: 16),
            Expanded(
              child: CustomerList(
                searchQuery: _searchQuery,
                onEdit: (customer, index) => _showEditCustomerDialog(
                  context,
                  customer,
                  index,
                ),
                onDelete: (customer) => _confirmDelete(
                  context,
                  () async {
                    await _supabaseService.deleteCustomer(customer.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${customer.name} has been deleted'),
                      ),
                    );
                  },
                ),
                layoutType: isDesktop ? _layoutType : CustomerLayoutType.list, // Always use list on mobile
                isDesktop: isDesktop,
                filter: _filter,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        label: const Text('Add Customer'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Customer'),
            content: const Text(
              'Are you sure you want to delete this customer? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('DELETE'),
              ),
            ],
          ),
    );
  }

  Future<void> _showAddCustomerDialog(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1024;
    
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40.0,
            vertical: 24.0,
          ),
          child: Container(
            width: 600,
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.9,
            ),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: const SingleChildScrollView(
                child: AddCustomerDialog(),
              ),
            ),
          ),
        ),
      );
    }

    // Full screen dialog for mobile
    return showDialog(
      context: context,
      builder: (context) => const AddCustomerDialog(),
      barrierDismissible: false,
      useSafeArea: true,
    );
  }

  Future<void> _showEditCustomerDialog(BuildContext context, Customer customer, int index) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40.0 : 8.0,
            vertical: 24.0,
          ),
          child: Container(
            width: isDesktop ? 600 : MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Card(
              margin: EdgeInsets.zero,
              child: SingleChildScrollView(
                child: AddCustomerDialog(
                  customer: customer,
                  index: index,
                  isEditing: true,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Full screen dialog for mobile
    return showDialog(
      context: context,
      builder: (context) => AddCustomerDialog(
        customer: customer,
        index: index,
        isEditing: true,
      ),
      barrierDismissible: false,
      useSafeArea: true,
    );
  }
}
