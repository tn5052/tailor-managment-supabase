import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../theme/inventory_design_config.dart';

// Legacy fallback dialog - redirects to the new inventory item selector
class InventorySelectorDialog extends StatelessWidget {
  final String inventoryType;

  const InventorySelectorDialog({super.key, required this.inventoryType});

  static Future<List<dynamic>?> show(
    BuildContext context, {
    required String inventoryType,
  }) {
    return showDialog<List<dynamic>>(
      context: context,
      builder:
          (context) => InventorySelectorDialog(inventoryType: inventoryType),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
      ),
      title: Row(
        children: [
          Icon(PhosphorIcons.info(), color: InventoryDesignConfig.infoColor),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          const Text('Use Updated Dialog'),
        ],
      ),
      content: const Text(
        'This dialog has been replaced with the new InventoryItemSelectorDialog. Please use the new implementation.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
