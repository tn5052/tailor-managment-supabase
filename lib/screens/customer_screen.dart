import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';
import '../widgets/customer/add_customer_dialog.dart';
import '../widgets/customer/customer_list.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or bill number',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
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
    
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40.0 : 0, // Remove horizontal padding on mobile
          vertical: isDesktop ? 24.0 : 0, // Remove vertical padding on mobile
        ),
        child: Container(
          width: isDesktop ? 600 : screenSize.width,
          height: isDesktop ? null : screenSize.height, // Full height on mobile
          constraints: BoxConstraints(
            maxHeight: isDesktop ? screenSize.height * 0.9 : screenSize.height,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                isDesktop ? 28 : 0, // No border radius on mobile
              ),
            ),
            child: SingleChildScrollView(
              child: const AddCustomerDialog(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditCustomerDialog(BuildContext context, Customer customer, int index) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
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
}
