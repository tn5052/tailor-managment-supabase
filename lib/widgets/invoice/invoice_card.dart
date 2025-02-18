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
                      'INV No #${invoice.invoiceNumber}', // Changed from displayNumber to invoiceNumber
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
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptions(context),
            ),
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
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final theme = Theme.of(context);
    
    showMenu<String>(  // Add type parameter
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: theme.colorScheme.surface,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
      items: [
        PopupMenuItem<String>(  // Add type parameter
          value: 'edit',  // Add value
          height: 48,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Edit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 0.5),
        PopupMenuItem<String>(  // Add type parameter
          value: 'delete',  // Add value
          height: 48,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        InvoiceScreen.show(context, invoice: invoice);
      } else if (value == 'delete') {
        onDelete();
      }
    });
  }
}
