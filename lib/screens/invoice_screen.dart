import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../models/invoice_filter.dart';
import '../widgets/invoice/add_invoice_dailog.dart';
import '../widgets/invoice/invoice_details_dialog.dart';
import '../widgets/invoice/invoice_search_bar.dart';
import '../services/invoice_service.dart';
import '../widgets/invoice/invoice_group_view.dart';
import 'complaints_screen.dart'; // Import ComplaintsScreen

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _searchController = TextEditingController();
  final InvoiceService _invoiceService = InvoiceService();
  final _scrollController = ScrollController();
  InvoiceFilter _filter = const InvoiceFilter();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoices',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: !isDesktop,
        actions: <Widget>[
          Row(
            children: [
              if (!isDesktop)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ComplaintsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.feedback_outlined,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Issues',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (isDesktop) ...[
                FilledButton.icon(
                  onPressed: () => InvoiceScreen.show(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New Invoice'),
                ),
                const SizedBox(width: 16),
              ],
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0, // Add vertical spacing
            ),
            child: InvoiceSearchBar(
              searchController: _searchController,
              onSearchChanged: (query) {
                setState(() {
                  _filter = _filter.copyWith(searchQuery: query);
                });
              },
              onClearSearch: () {
                _searchController.clear();
                setState(() {
                  _filter = _filter.copyWith(searchQuery: '');
                });
              },
              filter: _filter,
              onFilterChanged: (newFilter) {
                setState(() {
                  _filter = newFilter;
                });
              },
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                physics: const BouncingScrollPhysics(),
                scrollbars: false,
              ),
              child: StreamBuilder<List<Invoice>>(
                stream: _invoiceService.getInvoicesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allInvoices = snapshot.data ?? [];
                  final filteredInvoices =
                      allInvoices
                          .where((invoice) => _filter.matchesInvoice(invoice))
                          .toList();

                  if (filteredInvoices.isEmpty) {
                    if (_filter.hasActiveFilters) {
                      return _buildNoResultsFound(context);
                    }
                    return _buildEmptyState(context);
                  }

                  return InvoiceGroupView(
                    invoices: filteredInvoices,
                    groupBy: _filter.groupBy,
                    isGridView: isDesktop || isTablet,
                    onTap: (invoice) => _showInvoiceDetails(context, invoice),
                    onDelete: (invoice) => _confirmDelete(
                      context,
                      () async => await _invoiceService.deleteInvoice(invoice.id),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          isDesktop
              ? null
              : FloatingActionButton.extended(
                onPressed: () => InvoiceScreen.show(context),
                icon: const Icon(Icons.add),
                label: const Text('New Invoice'),
              ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No invoices yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => InvoiceScreen.show(context),
            icon: const Icon(Icons.add),
            label: const Text('Create your first invoice'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No matching invoices found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _filter = const InvoiceFilter();
              });
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear all filters'),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetails(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => InvoiceDetailsDialog(invoice: invoice),
    );
  }

  Future<void> _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Invoice'),
            content: const Text(
              'Are you sure you want to delete this invoice? This action cannot be undone.',
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
}
