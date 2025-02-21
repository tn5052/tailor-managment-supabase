
import 'package:flutter/material.dart';
import '../../models/measurement_filter.dart';

class MeasurementGroupMenu extends StatelessWidget {
  final MeasurementGroupBy currentGroup;
  final Function(MeasurementGroupBy) onGroupChanged;

  const MeasurementGroupMenu({
    super.key,
    required this.currentGroup,
    required this.onGroupChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return PopupMenuButton<MeasurementGroupBy>(
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
          border: currentGroup != MeasurementGroupBy.none
              ? Border.all(color: theme.colorScheme.primary)
              : null,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                  color: currentGroup != MeasurementGroupBy.none
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (currentGroup != MeasurementGroupBy.none)
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
                  color: currentGroup != MeasurementGroupBy.none
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildMenuItem(context, MeasurementGroupBy.none, 'No Grouping', Icons.grid_view_outlined),
        const PopupMenuDivider(),
        _buildMenuItem(context, MeasurementGroupBy.customer, 'Group by Customer', Icons.people_alt_outlined),
        _buildMenuItem(context, MeasurementGroupBy.date, 'Group by Date', Icons.event_outlined),
        _buildMenuItem(context, MeasurementGroupBy.month, 'Group by Month', Icons.calendar_view_month_outlined),
        _buildMenuItem(context, MeasurementGroupBy.style, 'Group by Style', Icons.style_outlined),
        _buildMenuItem(context, MeasurementGroupBy.designType, 'Group by Design Type', Icons.design_services_outlined),
      ],
    );
  }

  PopupMenuItem<MeasurementGroupBy> _buildMenuItem(
    BuildContext context,
    MeasurementGroupBy value,
    String text,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = currentGroup == value;

    return PopupMenuItem<MeasurementGroupBy>(
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

  IconData _getGroupIcon(MeasurementGroupBy group) {
    switch (group) {
      case MeasurementGroupBy.customer:
        return Icons.people_alt_outlined;
      case MeasurementGroupBy.date:
        return Icons.event_outlined;
      case MeasurementGroupBy.month:
        return Icons.calendar_view_month_outlined;
      case MeasurementGroupBy.style:
        return Icons.style_outlined;
      case MeasurementGroupBy.designType:
        return Icons.design_services_outlined;
      case MeasurementGroupBy.none:
        return Icons.grid_view_outlined;
    }
  }

  String _getGroupText(MeasurementGroupBy group) {
    if (group == MeasurementGroupBy.none) {
      return 'Group';
    }
    return 'Grouped by ${group.name}';
  }
}