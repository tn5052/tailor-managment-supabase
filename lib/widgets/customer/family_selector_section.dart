import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/supabase_service.dart'; // Add this import
import '../customer/customer_selector_dialog.dart'; // Add this import

class FamilySelectorSection extends StatelessWidget {
  final Customer? selectedFamilyMember;
  final FamilyRelation? selectedRelation;
  final Function(Customer?) onFamilyMemberSelected;
  final Function(FamilyRelation?) onRelationChanged;

  const FamilySelectorSection({
    super.key,
    this.selectedFamilyMember,
    this.selectedRelation,
    required this.onFamilyMemberSelected,
    required this.onRelationChanged,
  });

  Future<void> _confirmRemoveMember(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Family Member'),
        content: Text(
          'Are you sure you want to remove ${selectedFamilyMember?.name} as a family member? '
          'This will unlink the family connection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(context);
              onFamilyMemberSelected(null);
              onRelationChanged(null);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final supabaseService = SupabaseService();

    // Define adaptive colors based on theme
    final containerColor = brightness == Brightness.light
        ? theme.colorScheme.primaryContainer.withOpacity(0.1)
        : theme.colorScheme.surfaceVariant.withOpacity(0.3);

    final borderColor = brightness == Brightness.light
        ? theme.colorScheme.primary.withOpacity(0.1)
        : theme.colorScheme.outline.withOpacity(0.2);

    final headerColor = brightness == Brightness.light
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced margin
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Compact padding
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with Remove Button
          Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: headerColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Family Connection',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: headerColor,
                  ),
                ),
              ),
              if (selectedFamilyMember != null)
                IconButton(
                  icon: const Icon(Icons.link_off, size: 18),
                  tooltip: 'Remove family connection',
                  onPressed: () => _confirmRemoveMember(context),
                ),
            ],
          ),
          if (selectedFamilyMember != null) ...[
            const SizedBox(height: 8),
            // Selected family member info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brightness == Brightness.light
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: Text(
                      selectedFamilyMember!.name[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedFamilyMember!.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '#${selectedFamilyMember!.billNumber} · ${selectedFamilyMember!.phone}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: () async {
                      final currentContext = context;
                      try {
                        final customers = await supabaseService.getAllCustomers();
                        if (!currentContext.mounted) return;
                        final customer = await CustomerSelectorDialog.show(
                          currentContext,
                          customers,
                        );
                        if (customer != null) {
                          onFamilyMemberSelected(customer);
                          // Keep existing relation if changing to new member
                          if (selectedRelation == null) {
                            onRelationChanged(FamilyRelation.other);
                          }
                        }
                      } catch (e) {
                        if (!currentContext.mounted) return;
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.edit, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Relation Dropdown
            Theme(
              data: theme.copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: brightness == Brightness.light
                      ? theme.colorScheme.surface
                      : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                ),
              ),
              child: DropdownButtonFormField<FamilyRelation>(
                value: selectedRelation,
                isDense: true, // Makes the dropdown more compact
                decoration: InputDecoration(
                  labelText: 'Relation',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                ),
                items: FamilyRelation.values.map((relation) {
                  return DropdownMenuItem(
                    value: relation,
                    child: Text(
                      relation.name.toUpperCase(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: onRelationChanged,
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            FilledButton.tonalIcon(
              onPressed: () async {
                final currentContext = context;
                try {
                  final customers = await supabaseService.getAllCustomers();
                  if (!currentContext.mounted) return;
                  final customer = await CustomerSelectorDialog.show(
                    currentContext,
                    customers,
                  );
                  if (customer != null) {
                    onFamilyMemberSelected(customer);
                    onRelationChanged(FamilyRelation.other);
                  }
                } catch (e) {
                  if (!currentContext.mounted) return;
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('SELECT FAMILY MEMBER'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}