import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/inventory_design_config.dart';
import 'edit_inventory_desktop_dialog.dart';
import '../../../../theme/app_theme.dart';

class InventoryDetailDialogDesktop extends StatefulWidget {
  final Map<String, dynamic> item;
  final String inventoryType;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const InventoryDetailDialogDesktop({
    super.key,
    required this.item,
    required this.inventoryType,
    this.onEdit,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> item,
    required String inventoryType,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
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

  @override
  Widget build(BuildContext context) {
    final isFabric = widget.inventoryType == 'fabric';
    final itemName =
        isFabric
            ? widget.item['fabric_item_name']
            : widget.item['accessory_item_name'];
    final itemCode =
        isFabric ? widget.item['fabric_code'] : widget.item['accessory_code'];
    final colorCode = widget.item['color_code'] ?? '';

    // Get screen size to limit dialog height and prevent overflow
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.85;

    // Use app theme colors for better styling
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ), // Add vertical padding
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 850,
          maxHeight: maxHeight, // Limit max height to prevent overflow
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important for sizing
            children: [
              // Compact header with app theme styling
              _buildHeader(itemName, itemCode, isFabric, theme),

              // Content with scrolling
              Flexible(child: _buildContent(theme)),

              // Footer with actions
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    String? itemName,
    String? itemCode,
    bool isFabric,
    ThemeData theme,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Type icon with app theme styling
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isFabric ? PhosphorIcons.scissors() : PhosphorIcons.package(),
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),

          // Title and subtitle with app theme typography
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName ?? 'Unknown Item',
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  itemCode ?? 'No Code',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              PhosphorIcons.x(),
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return SingleChildScrollView(
      // Ensure content is scrollable
      physics: const ClampingScrollPhysics(), // Better scrolling behavior
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left section: Color preview and details
            Expanded(flex: 3, child: _buildLeftSection(theme)),

            const SizedBox(width: 24),

            // Right section: Item details and stats
            Expanded(flex: 5, child: _buildRightSection(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSection(ThemeData theme) {
    final isFabric = widget.inventoryType == 'fabric';
    final colorName =
        isFabric ? widget.item['shade_color'] : widget.item['color'];
    final colorCode = widget.item['color_code'] ?? '';
    final itemType =
        isFabric ? widget.item['fabric_type'] : widget.item['accessory_type'];
    final brandName = widget.item['brand_name'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item color preview with enhanced styling
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: _parseColor(colorCode),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _parseColor(colorCode).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                isFabric ? PhosphorIcons.scissors() : PhosphorIcons.package(),
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Basic properties with app theme styling
        _buildPropertyCard([
          if (colorName != null && colorName.isNotEmpty)
            _buildProperty('Color', colorName, PhosphorIcons.palette(), theme),
          if (colorCode.isNotEmpty)
            _buildProperty(
              'Color Code',
              colorCode,
              PhosphorIcons.hash(),
              theme,
              isCode: true,
            ),
          _buildProperty(
            'Type',
            itemType ?? 'Unknown Type',
            PhosphorIcons.folder(),
            theme,
          ),
          _buildProperty(
            'Brand',
            brandName ?? 'No Brand',
            PhosphorIcons.tag(),
            theme,
          ),
          _buildProperty(
            'Unit Type',
            widget.item['unit_type'] ?? 'N/A',
            PhosphorIcons.ruler(),
            theme,
          ),
        ], theme),

        const SizedBox(height: 16),

        // Date information with theme styling
        _buildDateInfo(theme),
      ],
    );
  }

  Widget _buildRightSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stock information with theme styling
        _buildStockCard(theme),

        const SizedBox(height: 16),

        // Pricing information with theme styling
        _buildPricingCard(theme),

        const SizedBox(height: 16),

        // Notes if available with theme styling
        if (widget.item['notes'] != null &&
            widget.item['notes'].toString().isNotEmpty)
          _buildNotesCard(theme),
      ],
    );
  }

  Widget _buildStockCard(ThemeData theme) {
    final quantityAvailable = _toInt(widget.item['quantity_available']);
    final minimumStockLevel = _toInt(widget.item['minimum_stock_level']);
    final isLowStock = quantityAvailable <= minimumStockLevel;

    return _buildCard(
      title: 'Stock Information',
      icon: PhosphorIcons.package(),
      color: isLowStock ? AppTheme.warningColor : theme.colorScheme.primary,
      theme: theme,
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  'Available Stock',
                  '$quantityAvailable ${widget.item['unit_type'] ?? 'units'}',
                  icon: PhosphorIcons.stack(),
                  color:
                      isLowStock
                          ? AppTheme.warningColor
                          : AppTheme.successColor,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoBox(
                  'Minimum Level',
                  '$minimumStockLevel ${widget.item['unit_type'] ?? 'units'}',
                  icon: PhosphorIcons.arrowsInLineVertical(),
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status indicator with theme styling
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isLowStock
                      ? AppTheme.warningColor
                      : AppTheme.successColor)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (isLowStock
                        ? AppTheme.warningColor
                        : AppTheme.successColor)
                    .withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isLowStock
                      ? PhosphorIcons.warning()
                      : PhosphorIcons.checkCircle(),
                  size: 20,
                  color:
                      isLowStock
                          ? AppTheme.warningColor
                          : AppTheme.successColor,
                ),
                const SizedBox(width: 12),
                Text(
                  isLowStock ? 'Low Stock - Order Soon' : 'Stock Level is Good',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color:
                        isLowStock
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(ThemeData theme) {
    final costPerUnit = _toDouble(widget.item['cost_per_unit']);
    final sellingPrice = _toDouble(widget.item['selling_price_per_unit']);
    final profit = sellingPrice - costPerUnit;
    final marginPercent = costPerUnit > 0 ? (profit / costPerUnit * 100) : 0.0;
    final totalValue =
        _toDouble(widget.item['quantity_available']) * costPerUnit;

    return _buildCard(
      title: 'Pricing & Value',
      icon: PhosphorIcons.currencyDollar(),
      color: theme.colorScheme.primary,
      theme: theme,
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  'Cost per Unit',
                  NumberFormat.currency(symbol: '\$').format(costPerUnit),
                  icon: PhosphorIcons.arrowDown(),
                  color: theme.colorScheme.tertiary,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoBox(
                  'Selling Price',
                  NumberFormat.currency(symbol: '\$').format(sellingPrice),
                  icon: PhosphorIcons.arrowUp(),
                  color: AppTheme.successColor,
                  theme: theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  'Profit per Unit',
                  NumberFormat.currency(symbol: '\$').format(profit),
                  icon: PhosphorIcons.trendUp(),
                  color:
                      profit >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoBox(
                  'Profit Margin',
                  '${marginPercent.toStringAsFixed(1)}%',
                  icon: PhosphorIcons.percent(),
                  color:
                      marginPercent >= 20
                          ? AppTheme.successColor
                          : marginPercent >= 0
                          ? AppTheme.warningColor
                          : AppTheme.errorColor,
                  theme: theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total value with theme styling
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.wallet(),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Inventory Value:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  NumberFormat.currency(symbol: '\$').format(totalValue),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme) {
    return _buildCard(
      title: 'Notes',
      icon: PhosphorIcons.notepad(),
      color: theme.colorScheme.primary,
      theme: theme,
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          widget.item['notes'].toString(),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateInfo(ThemeData theme) {
    final createdAt = widget.item['created_at'];
    final updatedAt = widget.item['updated_at'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (createdAt != null)
            _buildDateRow(
              'Created',
              DateFormat('MMM d, yyyy').format(DateTime.parse(createdAt)),
              PhosphorIcons.calendar(),
              theme,
            ),
          if (updatedAt != null)
            _buildDateRow(
              'Updated',
              DateFormat('MMM d, yyyy').format(DateTime.parse(updatedAt)),
              PhosphorIcons.clockClockwise(),
              theme,
            ),
        ],
      ),
    );
  }

  Widget _buildDateRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProperty(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    bool isCode = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  isCode
                      ? theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                        fontSize: 12,
                      )
                      : theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(List<Widget> children, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Properties',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
    required ThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
    String label,
    String value, {
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Delete button with theme styling - using proper app theming
          OutlinedButton(
            onPressed: _isProcessing ? null : _handleDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: BorderSide(color: AppTheme.errorColor.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.errorColor,
                    ),
                  )
                else
                  Icon(PhosphorIcons.trash(), size: 16),
                const SizedBox(width: 8),
                Text(
                  _isProcessing ? 'Deleting...' : 'Delete',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Edit button with app theme styling - using config primary color
          FilledButton(
            onPressed: _isProcessing ? null : _handleEdit,
            style: FilledButton.styleFrom(
              backgroundColor: InventoryDesignConfig.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.pencilSimple(), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Edit Item',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

      await _supabase
          .from(table)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.item['id']);

      Navigator.of(context).pop();
      widget.onDelete?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.inventoryType == 'fabric' ? 'Fabric' : 'Accessory'} deleted successfully',
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting item: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    final theme = Theme.of(context);
    final isFabric = widget.inventoryType == 'fabric';
    final itemName =
        widget.item[isFabric ? 'fabric_item_name' : 'accessory_item_name'];

    return showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      PhosphorIcons.warning(PhosphorIconsStyle.fill),
                      color: AppTheme.errorColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text('Confirm Deletion', style: theme.textTheme.titleLarge),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are you sure you want to delete this ${isFabric ? 'fabric' : 'accessory'}?',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.errorColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isFabric
                                  ? PhosphorIcons.scissors()
                                  : PhosphorIcons.package(),
                              color: AppTheme.errorColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                itemName ?? 'Unknown Item',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This action cannot be undone.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  // Cancel button with consistent styling
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(color: theme.colorScheme.outline),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Delete button with consistent styling
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.trash(), size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actionsAlignment: MainAxisAlignment.end,
              ),
            ),
          ),
    );
  }

  // Helper methods
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Color _parseColor(String colorCode) {
    if (colorCode.isEmpty) return AppTheme.primaryColor;

    try {
      if (colorCode.startsWith('#')) {
        String hexCode = colorCode.substring(1);
        if (hexCode.length == 6) {
          return Color(int.parse('FF$hexCode', radix: 16));
        }
      }
      return AppTheme.primaryColor;
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }
}
