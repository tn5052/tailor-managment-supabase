import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (isDesktop) {
      return showDialog<Customer>(
        context: context,
        builder:
            (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: SizedBox(
                width: 600,
                height: MediaQuery.of(context).size.height * 0.8,
                child: CustomerSelectorDialog(
                  customers: customers,
                  onSelect: (customer) => Navigator.pop(context, customer),
                ),
              ),
            ),
      );
    }

    // Full screen dialog for mobile
    return showDialog<Customer>(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero, // Remove default padding
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.7,
              margin: const EdgeInsets.symmetric(
                vertical: 24,
              ), // Add some vertical margin
              child: CustomerSelectorDialog(
                customers: customers,
                onSelect: (customer) => Navigator.pop(context, customer),
              ),
            ),
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
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 28 : 20),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.person_search, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Select Customer',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 24 : 16),

          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or bill number...',
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 12),

          // Customer list
          Expanded(
            child:
                _filteredCustomers.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 16 : 8,
                        vertical: 8,
                      ),
                      itemCount: _filteredCustomers.length,
                      itemBuilder:
                          (context, index) => _CustomerListItem(
                            customer: _filteredCustomers[index],
                            onTap:
                                () =>
                                    widget.onSelect(_filteredCustomers[index]),
                            searchQuery: _searchQuery,
                          ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerListItem extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final String searchQuery;

  const _CustomerListItem({
    required this.customer,
    required this.onTap,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isDesktop ? 16 : 12,
          ),
          child:
              isSmallScreen
                  ? _buildCompactLayout(theme)
                  : _buildRegularLayout(theme, isDesktop),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAvatar(theme, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _highlightText(
                    customer.name,
                    searchQuery,
                    theme.textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildPhoneNumber(theme, small: true),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildBillNumber(theme, small: true)),
            const SizedBox(width: 8),
            Text(
              DateFormat('MM/dd/yy').format(customer.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegularLayout(ThemeData theme, bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left section with avatar and name
        Expanded(
          flex: 3,
          child: Row(
            children: [
              _buildAvatar(theme, size: isDesktop ? 48 : 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _highlightText(
                      customer.name,
                      searchQuery,
                      theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isDesktop ? null : 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildPhoneNumber(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Right section with bill number and date
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBillNumber(theme),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        isDesktop ? 'MMM dd, yyyy' : 'MM/dd/yy',
                      ).format(customer.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: isDesktop ? null : 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
                size: isDesktop ? 24 : 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(ThemeData theme, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Text(
          customer.name[0].toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: size / 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumber(ThemeData theme, {bool small = false}) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.phone_outlined,
            size: small ? 12 : 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: _highlightText(
              customer.phone,
              searchQuery,
              theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: small ? 11 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillNumber(ThemeData theme, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _highlightText(
              '#${customer.billNumber}',
              searchQuery,
              TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: small ? 11 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final matches = query.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    int start = 0;

    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: style.copyWith(
            backgroundColor: Colors.yellow.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(text: TextSpan(style: style, children: spans));
  }
}
