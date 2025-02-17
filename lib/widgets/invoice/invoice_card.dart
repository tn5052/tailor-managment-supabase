import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import 'invoice_status_badge.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isGridView;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
    required this.onDelete,
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    return isGridView ? _buildGridCard(context) : _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InvoiceHeader(invoice: invoice, onMoreTap: _showOptions),
            Expanded(
              child: _InvoiceBody(
                invoice: invoice,
                isGridView: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InvoiceHeader(invoice: invoice, onMoreTap: _showOptions),
              const SizedBox(height: 16),
              _InvoiceBody(invoice: invoice, isGridView: false),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _InvoiceOptionsSheet(
        onDelete: () {
          Navigator.pop(context);
          onDelete();
        },
      ),
    );
  }
}

class _InvoiceHeader extends StatelessWidget {
  final Invoice invoice;
  final Function(BuildContext) onMoreTap;

  const _InvoiceHeader({
    required this.invoice,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
          _buildTitleRow(context, theme),
          const SizedBox(height: 8),
          _buildCustomerInfo(theme),
        ],
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, ThemeData theme) {
    return Row(
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
          onPressed: () => onMoreTap(context), // Fixed: directly pass the build context
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}

class _InvoiceBody extends StatelessWidget {
  final Invoice invoice;
  final bool isGridView;
  static final _currencyFormat = NumberFormat.currency(symbol: '');
  static final _dateFormat = DateFormat('MMM dd, yyyy');

  const _InvoiceBody({
    required this.invoice,
    required this.isGridView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateFormat.format(invoice.date),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _buildStatusBadges(),
          if (isGridView) const Spacer(),
          const SizedBox(height: 8),
          _buildAmountSection(theme),
        ],
      ),
    );
  }

  Widget _buildStatusBadges() {
    return Row(
      children: [
        InvoiceStatusBadge(status: invoice.deliveryStatus),
        const SizedBox(width: 8),
        InvoiceStatusBadge(
          status: invoice.paymentStatus,
          type: BadgeType.payment,
        ),
      ],
    );
  }

  Widget _buildAmountSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Amount', style: theme.textTheme.bodySmall),
        Text(
          _currencyFormat.format(invoice.amountIncludingVat),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        if (invoice.remainingBalance > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Balance: ${_currencyFormat.format(invoice.remainingBalance)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _InvoiceOptionsSheet extends StatelessWidget {
  final VoidCallback onDelete;

  const _InvoiceOptionsSheet({
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context: context,
            icon: Icons.edit,
            title: 'Edit Invoice',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement edit
            },
          ),
          _buildOption(
            context: context,
            icon: Icons.print,
            title: 'Print Invoice',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement print
            },
          ),
          _buildOption(
            context: context,
            icon: Icons.share,
            title: 'Share Invoice',
            onTap: () => Navigator.pop(context),
          ),
          _buildOption(
            context: context,
            icon: Icons.delete_outline,
            title: 'Delete Invoice',
            isDestructive: true,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? theme.colorScheme.error : null),
      ),
      onTap: onTap,
    );
  }
}
