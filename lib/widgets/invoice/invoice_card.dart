import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import 'invoice_status_badge.dart';
import 'invoice_screen.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isGridView;
  
  static final _currencyFormat = NumberFormat.currency(symbol: '');
  static final _dateFormat = DateFormat('MMM dd, yyyy');

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
    required this.onDelete,
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (!isGridView) ...[
              _buildExpandedBody(context),
            ] else ...[
              Expanded(child: _buildCompactBody(context)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = invoice.deliveryDate.isBefore(DateTime.now()) && 
                     invoice.deliveryStatus == InvoiceStatus.pending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      invoice.displayNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 8),
                      _buildOverdueBadge(theme),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  invoice.customerName,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBody(BuildContext context) {
    final theme = Theme.of(context);
    final hasBalance = invoice.remainingBalance > 0;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            theme,
            'Bill #${invoice.customerBillNumber}',
            invoice.customerPhone,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            theme,
            'Created: ${_dateFormat.format(invoice.date)}',
            'Due: ${_dateFormat.format(invoice.deliveryDate)}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currencyFormat.format(invoice.amountIncludingVat),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (hasBalance)
                      Text(
                        'Balance: ${_currencyFormat.format(invoice.remainingBalance)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InvoiceStatusBadge(status: invoice.deliveryStatus),
                  const SizedBox(height: 4),
                  InvoiceStatusBadge(status: invoice.paymentStatus),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedBody(BuildContext context) {
    final theme = Theme.of(context);
    final hasBalance = invoice.remainingBalance > 0;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 12 : 16), // Reduced padding for desktop
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            theme,
            'Bill #${invoice.customerBillNumber}',
            invoice.customerPhone,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            theme,
            'Created: ${_dateFormat.format(invoice.date)}',
            'Due: ${_dateFormat.format(invoice.deliveryDate)}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currencyFormat.format(invoice.amountIncludingVat),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (hasBalance)
                      Text(
                        'Balance: ${_currencyFormat.format(invoice.remainingBalance)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InvoiceStatusBadge(status: invoice.deliveryStatus),
                  const SizedBox(height: 4),
                  InvoiceStatusBadge(status: invoice.paymentStatus),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String left, String right) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Text(
          right,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildOverdueBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'OVERDUE',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildQuickAction(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'Edit Invoice',
                  subtitle: 'Modify invoice details',
                  onTap: () {
                    Navigator.pop(context);
                    InvoiceScreen.show(context, invoice: invoice);
                  },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.print_outlined,
                  label: 'Print Invoice',
                  subtitle: 'Generate PDF document',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement print
                  },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.payments_outlined,
                  label: 'Record Payment',
                  subtitle: 'Add new payment record',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement payment
                  },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.local_shipping_outlined,
                  label: 'Update Status',
                  subtitle: 'Change delivery status',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement status update
                  },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.share_outlined,
                  label: 'Share Invoice',
                  subtitle: 'Send via email or message',
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(height: 16),
                _buildQuickAction(
                  context,
                  icon: Icons.delete_outline,
                  label: 'Delete Invoice',
                  subtitle: 'Remove permanently',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDestructive ? theme.colorScheme.error : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
