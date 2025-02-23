import 'package:flutter/material.dart';
import '../../models/customer.dart';

class FamilyBadge extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;

  const FamilyBadge({
    super.key,
    required this.customer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (customer.familyId == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.tertiary.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.family_restroom,
              size: 16,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 4),
            Text(
              customer.familyRelationDisplay,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: theme.colorScheme.tertiary.withOpacity(0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
