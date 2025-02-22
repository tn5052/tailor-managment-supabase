import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/supabase_service.dart';

class CustomerList extends StatelessWidget {
  final String searchQuery;
  final Function(Customer, int) onEdit;
  final Function(Customer) onDelete;

  const CustomerList({
    super.key,
    required this.searchQuery,
    required this.onEdit,
    required this.onDelete,
  });

  bool _filterCustomer(Customer customer, String query) {
    if (query.isEmpty) return true;

    final queryLower = query.toLowerCase();
    return customer.name.toLowerCase().contains(queryLower) ||
        customer.phone.toLowerCase().contains(queryLower) ||
        customer.billNumber.toLowerCase().contains(queryLower);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Customer>>(
      stream: SupabaseService().getCustomersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final customers = snapshot.data ?? [];
        final filteredCustomers = customers
            .where((customer) => _filterCustomer(customer, searchQuery))
            .toList();

        if (customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No customers yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (filteredCustomers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No results found for "$searchQuery"',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: filteredCustomers.length,
          itemBuilder: (context, index) {
            final customer = filteredCustomers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CustomerCard(
                customer: customer,
                onEdit: () => onEdit(customer, index),
                onDelete: () => onDelete(customer),
              ),
            );
          },
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      color: theme.colorScheme.surface.withOpacity(0.8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              flex: 2,
                              child: Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.receipt_outlined,
                                      size: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        '#${customer.billNumber}',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCustomerBadge(
                      context,
                      'Phone: ${customer.phone}',
                      theme.colorScheme.primary,
                    ),
                    if (customer.whatsapp.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildCustomerBadge(
                          context,
                          'WhatsApp: ${customer.whatsapp}',
                          theme.colorScheme.secondary,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildCustomerBadge(
                        context,
                        'Gender: ${customer.gender.name.toUpperCase()}',
                        theme.colorScheme.tertiary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildCustomerBadge(
                        context,
                        'Address: ${customer.address}',
                        theme.colorScheme.error,
                        maxWidth: 200,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerBadge(
    BuildContext context,
    String text,
    Color color, {
    double? maxWidth,
  }) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
