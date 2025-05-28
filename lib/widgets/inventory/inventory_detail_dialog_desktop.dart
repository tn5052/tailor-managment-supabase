// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_inventory_desktop_dialog.dart';

class InventoryDetailDialogDesktop extends StatefulWidget {
  final Map<String, dynamic> item;
  final String inventoryType; // 'fabric' or 'accessory'
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const InventoryDetailDialogDesktop({
    Key? key,
    required this.item,
    required this.inventoryType,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> item,
    required String inventoryType,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by clicking outside
      builder:
          (context) => InventoryDetailDialogDesktop(
            item: item,
            inventoryType: inventoryType,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
    );
  }

  @override
  State<InventoryDetailDialogDesktop> createState() =>
      _InventoryDetailDialogDesktopState();
}

class _InventoryDetailDialogDesktopState
    extends State<InventoryDetailDialogDesktop> {
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;

  Future<void> _handleEdit() async {
    Navigator.of(context).pop();
    await EditInventoryDesktopDialog.show(
      context,
      item: widget.item,
      inventoryType: widget.inventoryType,
      onItemUpdated: widget.onEdit,
    );
  }

  Future<void> _handleDelete() async {
    final confirm = await _showDeleteConfirmationDialog();
    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final table =
          widget.inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';

      // Soft delete by setting is_active to false instead of hard delete
      await _supabase
          .from(table)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.item['id']);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.inventoryType == 'fabric' ? 'Fabric' : 'Accessory'} deleted successfully',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onDelete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    final theme = Theme.of(context);
    final isFabric = widget.inventoryType == 'fabric';
    final itemName =
        widget.item[isFabric ? 'fabric_item_name' : 'accessory_item_name'];

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  PhosphorIcons.warning(PhosphorIconsStyle.fill),
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text('Confirm Deletion'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this ${isFabric ? 'fabric' : 'accessory'}?',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFabric
                            ? PhosphorIcons.scissors()
                            : PhosphorIcons.package(),
                        color: theme.colorScheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemName ?? 'Unknown Item',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This action cannot be undone. The item will be removed from your inventory.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(PhosphorIcons.trash()),
                label: const Text('Delete'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isFabric = widget.inventoryType == 'fabric';

    // Determine item-specific details
    final String itemName =
        widget.item[isFabric ? 'fabric_item_name' : 'accessory_item_name'] ??
        'N/A';
    final String itemCode =
        widget.item[isFabric ? 'fabric_code' : 'accessory_code'] ?? 'N/A';
    final String? itemBrand = widget.item['brand_name'];
    final String itemCategory =
        widget.item[isFabric ? 'fabric_type' : 'accessory_type'] ?? 'N/A';

    final String? fabricColorName =
        isFabric ? widget.item['shade_color'] : null;
    final String? fabricColorCode = isFabric ? widget.item['color_code'] : null;

    final Color displayColor =
        isFabric && fabricColorCode != null && fabricColorCode.isNotEmpty
            ? _parseColor(fabricColorCode)
            : Colors.grey.shade700; // Default for accessories or no color code

    return Dialog(
      backgroundColor: const Color(
        0xFF1A1C1E,
      ), // Dark background for the dialog
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 900, // Adjusted width
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2F31), // Darker header
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isFabric
                        ? PhosphorIcons.scissors(PhosphorIconsStyle.fill)
                        : PhosphorIcons.package(PhosphorIconsStyle.fill),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${isFabric ? 'Fabric' : 'Accessory'} Details',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.x(), color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    SizedBox(
                      width: 280,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: displayColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: displayColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  isFabric
                                      ? PhosphorIcons.scissors(
                                        PhosphorIconsStyle.bold,
                                      )
                                      : _getAccessoryIcon(itemCategory),
                                  color: Colors.white,
                                  size: 80,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildBasicInfoCard(
                            context,
                            itemCode: itemCode,
                            itemName: itemName,
                            itemBrand: itemBrand,
                            itemCategory: itemCategory,
                            fabricColorName: fabricColorName,
                            fabricColorCode: fabricColorCode,
                            isFabric: isFabric,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStockInfoCard(context, widget.item),
                          const SizedBox(height: 20),
                          _buildPricingInfoCard(context, widget.item),
                          if (widget.item['notes'] != null &&
                              widget.item['notes'].isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildAdditionalInfoCard(
                              context,
                              title: 'Notes',
                              icon: PhosphorIcons.notepad(),
                              children: [
                                Text(
                                  widget.item['notes'],
                                  style: GoogleFonts.inter(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C1E),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade700.withOpacity(0.5)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _handleDelete,
                    icon:
                        _isProcessing
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.error,
                              ),
                            )
                            : Icon(PhosphorIcons.trash(), size: 18),
                    label: Text(_isProcessing ? 'Deleting...' : 'Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withOpacity(0.7),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _handleEdit,
                    icon:
                        _isProcessing
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                            : Icon(PhosphorIcons.pencilSimple(), size: 18),
                    label: Text(_isProcessing ? 'Processing...' : 'Edit Item'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildBasicInfoCard(
    BuildContext context, {
    required String itemCode,
    required String itemName,
    String? itemBrand,
    required String itemCategory,
    String? fabricColorName,
    String? fabricColorCode,
    required bool isFabric,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2F31), // Dark card for basic info
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Item Code',
            itemCode,
            icon: PhosphorIcons.barcode(),
          ),
          _buildInfoRow(
            context,
            'Name',
            itemName,
            icon: PhosphorIcons.textAa(),
          ),
          if (itemBrand != null && itemBrand.isNotEmpty)
            _buildInfoRow(
              context,
              'Brand',
              itemBrand,
              icon: PhosphorIcons.tag(),
            ),
          _buildInfoRow(
            context,
            'Type',
            itemCategory,
            icon: PhosphorIcons.folder(),
          ),
          if (isFabric && fabricColorName != null && fabricColorName.isNotEmpty)
            _buildInfoRow(
              context,
              'Color',
              fabricColorName,
              icon: PhosphorIcons.palette(),
              trailing:
                  fabricColorCode != null && fabricColorCode.isNotEmpty
                      ? Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _parseColor(fabricColorCode),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      )
                      : null,
            ),
        ],
      ),
    );
  }

  Widget _buildStockInfoCard(
    BuildContext context,
    Map<String, dynamic> itemData,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool isLowStock =
        (itemData['quantity_available'] ?? 0) <=
        (itemData['minimum_stock_level'] ?? 0);

    // Color adjustments based on theme
    final Color stockStatusColor =
        isLowStock
            ? theme.colorScheme.error
            : (isDark
                ? Color(0xFF4CAF50)
                : Colors.green.shade600); // Green color adjusted for dark theme

    final String stockStatusText = isLowStock ? 'Low Stock' : 'In Stock';
    final String stockLevelText = isLowStock ? 'Order Soon' : 'Good Levels';

    // Card background color based on theme
    final Color cardBackground =
        isDark ? const Color(0xFF2D2F31) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color labelColor =
        isDark ? Colors.grey.shade300 : Colors.grey.shade600;
    final Color dividerColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.package(PhosphorIconsStyle.fill),
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Stock Information',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Divider(height: 24, color: dividerColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: stockStatusColor.withOpacity(isDark ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(8),
              border:
                  isDark
                      ? Border.all(color: stockStatusColor.withOpacity(0.3))
                      : null,
            ),
            child: Row(
              children: [
                Icon(
                  isLowStock
                      ? PhosphorIcons.warning(PhosphorIconsStyle.fill)
                      : PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  color: stockStatusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  stockStatusText,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: stockStatusColor,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  stockLevelText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: stockStatusColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildMetricTile(
            context,
            label: 'Available Quantity',
            value: (itemData['quantity_available'] ?? 0).toString(),
            suffix: itemData['unit_type'] ?? 'units',
            icon: PhosphorIcons.stack(),
            iconColor: theme.colorScheme.primary,
            labelColor: labelColor,
            textColor: textColor,
          ),
          _buildMetricTile(
            context,
            label: 'Minimum Stock Level',
            value: (itemData['minimum_stock_level'] ?? 0).toString(),
            suffix: itemData['unit_type'] ?? 'units',
            icon: PhosphorIcons.warning(),
            iconColor: theme.colorScheme.error,
            labelColor: labelColor,
            textColor: textColor,
          ),
          _buildMetricTile(
            context,
            label: 'Unit Type',
            value: itemData['unit_type'] ?? 'N/A',
            icon: PhosphorIcons.ruler(),
            iconColor: theme.colorScheme.tertiary,
            labelColor: labelColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingInfoCard(
    BuildContext context,
    Map<String, dynamic> itemData,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Card background color based on theme
    final Color cardBackground =
        isDark ? const Color(0xFF2D2F31) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color dividerColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    // Colors for price cards, adjusted for theme
    Color costBgColor =
        isDark ? Color(0xFF3B2A2A) : Color(0xFFFEE2E2); // Dark red/light red
    Color costTextColor = isDark ? Color(0xFFE57373) : Color(0xFFB91C1C); // Red

    Color priceBgColor =
        isDark
            ? Color(0xFF1E332B)
            : Color(0xFFD1FAE5); // Dark green/light green
    Color priceTextColor =
        isDark ? Color(0xFF4CAF50) : Color(0xFF047857); // Green

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.currencyCircleDollar(PhosphorIconsStyle.fill),
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Pricing Information',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Divider(height: 24, color: dividerColor),
          Row(
            children: [
              Expanded(
                child: _buildPriceSubCard(
                  context,
                  label: 'Cost per Unit',
                  amount: itemData['cost_per_unit'] ?? 0,
                  unitType: itemData['unit_type'] ?? 'unit',
                  color: costBgColor,
                  textColor: costTextColor,
                  icon: PhosphorIcons.currencyDollar(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPriceSubCard(
                  context,
                  label: 'Selling Price',
                  amount: itemData['selling_price_per_unit'] ?? 0,
                  unitType: itemData['unit_type'] ?? 'unit',
                  color: priceBgColor,
                  textColor: priceTextColor,
                  icon: PhosphorIcons.tag(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProfitAnalysis(context, itemData),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Card background color based on theme
    final Color cardBackground =
        isDark ? const Color(0xFF2D2F31) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color dividerColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Divider(height: 24, color: dividerColor),
          ...children.map((child) {
            // Apply appropriate text color to children if they're Text widgets
            if (child is Text) {
              return Text(
                child.data ?? '',
                style: (child.style ?? GoogleFonts.inter()).copyWith(
                  color: textColor,
                ),
              );
            }
            return child;
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Adjusted padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 90, // Adjusted width
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    String? suffix,
    required IconData icon,
    required Color iconColor,
    required Color labelColor,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 14, color: labelColor),
                ),
                const SizedBox(height: 2),
                Text(
                  suffix != null && suffix.isNotEmpty
                      ? '$value $suffix'
                      : value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSubCard(
    BuildContext context, {
    required String label,
    required double amount,
    required String unitType,
    required Color color, // Background color for the card
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            NumberFormat.currency(
              symbol: '\$',
            ).format(amount), // Assuming $ as currency
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            'per $unitType',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitAnalysis(
    BuildContext context,
    Map<String, dynamic> itemData,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cost = itemData['cost_per_unit'] ?? 0.0;
    final price = itemData['selling_price_per_unit'] ?? 0.0;
    final profit = price - cost;
    final marginPercent =
        cost > 0 ? (profit / cost) * 100 : (price > 0 ? 100.0 : 0.0);

    // Colors adjusted for theme
    Color profitColor;
    if (profit < 0) {
      profitColor = theme.colorScheme.error;
    } else if (profit == 0) {
      profitColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    } else {
      profitColor = isDark ? Color(0xFF81C784) : Colors.green.shade700;
    }

    // Background color for profit analysis section
    final Color analysisBgColor =
        isDark ? Color(0xFF212529) : Colors.grey.shade200;
    final Color labelColor = isDark ? Colors.grey.shade400 : Colors.black54;
    final Color valueColor = isDark ? Colors.white : Colors.black87;
    final Color dividerColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    final Color headerColor =
        isDark ? Colors.grey.shade300 : Colors.blueGrey.shade800;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: analysisBgColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
                color: headerColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Profit Analysis',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: headerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _profitRow('Cost per Unit', cost, labelColor, valueColor),
          _profitRow('Selling Price', price, labelColor, valueColor),
          Divider(color: dividerColor, height: 20),
          _profitRow(
            'Profit per Unit',
            profit,
            labelColor,
            profitColor,
            isBold: true,
          ),
          _profitRow(
            'Margin',
            marginPercent,
            labelColor,
            profitColor,
            isBold: true,
            isPercent: true,
          ),
        ],
      ),
    );
  }

  Widget _profitRow(
    String label,
    double value,
    Color labelColor,
    Color valueColor, {
    bool isBold = false,
    bool isPercent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: labelColor),
          ),
          Text(
            isPercent
                ? '${value.toStringAsFixed(1)}%'
                : NumberFormat.currency(symbol: '\$').format(value),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAccessoryIcon(String? type) {
    // Simplified version, expand as needed
    switch (type?.toLowerCase()) {
      case 'button':
        return PhosphorIcons.circle(PhosphorIconsStyle.bold);
      case 'zipper':
        return PhosphorIcons.arrowLineDown(PhosphorIconsStyle.bold);
      case 'thread':
        return PhosphorIcons.spiral(PhosphorIconsStyle.bold);
      default:
        return PhosphorIcons.package(PhosphorIconsStyle.bold);
    }
  }

  Color _parseColor(String? colorCode) {
    if (colorCode == null || colorCode.isEmpty) return Colors.grey.shade700;
    try {
      if (colorCode.startsWith('#')) {
        String hexCode = colorCode.substring(1);
        if (hexCode.length == 6)
          return Color(int.parse('FF$hexCode', radix: 16));
        if (hexCode.length == 3) {
          // Handle shorthand hex
          hexCode = hexCode.split('').map((char) => char + char).join('');
          return Color(int.parse('FF$hexCode', radix: 16));
        }
      }
    } catch (e) {
      /* Fall through to default */
    }
    return Colors.grey.shade700; // Default color if parsing fails
  }
}
