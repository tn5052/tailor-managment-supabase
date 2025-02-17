import 'package:flutter/material.dart';
import '../../models/invoice_group_by.dart';

class InvoiceGroupMenu extends StatelessWidget {
  final InvoiceGroupBy currentGroup;
  final ValueChanged<InvoiceGroupBy> onGroupChanged;

  const InvoiceGroupMenu({
    super.key,
    required this.currentGroup,
    required this.onGroupChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return PopupMenuButton<InvoiceGroupBy>(
      initialValue: currentGroup,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onGroupChanged,
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: currentGroup != InvoiceGroupBy.none
              ? Border.all(color: theme.colorScheme.primary)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _getGroupIcon(currentGroup),
                  size: 24,
                  color: currentGroup != InvoiceGroupBy.none
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (currentGroup != InvoiceGroupBy.none)
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
            if (isDesktop) ...[
              const SizedBox(width: 8),
              Text(
                _getGroupText(currentGroup),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: currentGroup != InvoiceGroupBy.none
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildMenuItem(
          context,
          InvoiceGroupBy.none,
          'No Grouping',
          Icons.grid_view_outlined,
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          context,
          InvoiceGroupBy.customer,
          'Group by Customer',
          Icons.people_alt_outlined,
        ),
        _buildMenuItem(
          context,
          InvoiceGroupBy.date,
          'Group by Date',
          Icons.event_outlined,
        ),
        _buildMenuItem(
          context,
          InvoiceGroupBy.month,
          'Group by Month',
          Icons.calendar_view_month_outlined,
        ),
        _buildMenuItem(
          context,
          InvoiceGroupBy.status,
          'Group by Status',
          Icons.fact_check_outlined,
        ),
        _buildMenuItem(
          context,
          InvoiceGroupBy.amount,
          'Group by Amount',
          Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }

  PopupMenuItem<InvoiceGroupBy> _buildMenuItem(
    BuildContext context,
    InvoiceGroupBy value,
    String text,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = currentGroup == value;

    return PopupMenuItem<InvoiceGroupBy>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : null,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? theme.colorScheme.primary : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getGroupIcon(InvoiceGroupBy group) {
    switch (group) {
      case InvoiceGroupBy.customer:
        return Icons.people_alt_outlined;
      case InvoiceGroupBy.date:
        return Icons.event_outlined;
      case InvoiceGroupBy.month:
        return Icons.calendar_view_month_outlined;
      case InvoiceGroupBy.status:
        return Icons.fact_check_outlined;
      case InvoiceGroupBy.amount:
        return Icons.account_balance_wallet_outlined;
      case InvoiceGroupBy.none:
        return Icons.grid_view_outlined;
    }
  }

  String _getGroupText(InvoiceGroupBy group) {
    if (group == InvoiceGroupBy.none) {
      return 'Group';
    }
    return 'Grouped by ${group.name.capitalize()}';
  }
}
