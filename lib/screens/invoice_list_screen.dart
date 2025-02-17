import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../widgets/invoice/invoice_screen.dart';
import '../widgets/invoice/invoice_status_badge.dart';
import '../widgets/invoice/invoice_details_dialog.dart';
import '../services/invoice_service.dart';

class InvoiceListScreen extends StatelessWidget {
  final InvoiceService _invoiceService = InvoiceService();

  InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: theme.colorScheme.primaryContainer,
        title: Text(
          'Invoices',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isDesktop) ...[
            FilledButton.icon(
              onPressed: () => InvoiceScreen.show(context),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Invoice'),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: StreamBuilder<List<Invoice>>(
        stream: _invoiceService.getInvoicesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final invoices = snapshot.data ?? [];

          if (invoices.isEmpty) {
            return _buildEmptyState(context);
          }

          return Padding(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child:
                isDesktop || isTablet
                    ? _buildGrid(context, invoices)
                    : _buildList(context, invoices),
          );
        },
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

  Widget _buildGrid(BuildContext context, List<Invoice> invoices) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 4 : 3,
        childAspectRatio: 1.1,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return _InvoiceGridCard(
          invoice: invoice,
          onTap: () => _showInvoiceDetails(context, invoice),
          onDelete:
              () => _confirmDelete(context, () async {
                await _invoiceService.deleteInvoice(invoice.id);
              }),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<Invoice> invoices) {
    return ListView.builder(
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return _InvoiceListTile(
          invoice: invoice,
          onTap: () => _showInvoiceDetails(context, invoice),
          onDelete:
              () => _confirmDelete(context, () async {
                await _invoiceService.deleteInvoice(invoice.id);
              }),
        );
      },
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

class _InvoiceGridCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InvoiceGridCard({
    required this.invoice,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          invoice.displayNumber,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showOptions(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    invoice.customerName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Bill #${invoice.customerBillNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          invoice.customerPhone,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(invoice.date),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InvoiceStatusBadge(status: invoice.deliveryStatus),
                        const SizedBox(width: 8),
                        InvoiceStatusBadge(
                          status: invoice.paymentStatus,
                          type: BadgeType.payment,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text('Total Amount', style: theme.textTheme.bodySmall),
                    Text(
                      currencyFormat.format(invoice.amountIncludingVat),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (invoice.remainingBalance > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Balance: ${currencyFormat.format(invoice.remainingBalance)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                  title: const Text('Edit Invoice'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement edit
                  },
                ),
                ListTile(
                  leading: Icon(Icons.print, color: theme.colorScheme.primary),
                  title: const Text('Print Invoice'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement print
                  },
                ),
                ListTile(
                  leading: Icon(Icons.share, color: theme.colorScheme.primary),
                  title: const Text('Share Invoice'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete Invoice',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _InvoiceListTile extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InvoiceListTile({
    required this.invoice,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'INV-${invoice.invoiceNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptions(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                invoice.customerName,
                style: theme.textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  InvoiceStatusBadge(status: invoice.deliveryStatus),
                  const SizedBox(width: 8),
                  InvoiceStatusBadge(
                    status: invoice.paymentStatus,
                    type: BadgeType.payment,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Total Amount', style: theme.textTheme.bodySmall),
              Text(
                currencyFormat.format(invoice.amountIncludingVat),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (invoice.balance > 0)
                Text(
                  'Balance: ${currencyFormat.format(invoice.balance)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                  title: const Text('Edit Invoice'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement edit
                  },
                ),
                ListTile(
                  leading: Icon(Icons.print, color: theme.colorScheme.primary),
                  title: const Text('Print Invoice'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement print
                  },
                ),
                ListTile(
                  leading: Icon(Icons.share, color: theme.colorScheme.primary),
                  title: const Text('Share Invoice'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete Invoice',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
    );
  }
}
