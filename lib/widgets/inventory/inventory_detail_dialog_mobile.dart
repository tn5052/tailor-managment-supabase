import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class InventoryDetailDialogMobile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String inventoryType; // 'fabric' or 'accessory'
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const InventoryDetailDialogMobile({
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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.92,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => InventoryDetailDialogMobile(
                  item: item,
                  inventoryType: inventoryType,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFabric = inventoryType == 'fabric';

    final backgroundColor =
        isDark ? const Color(0xFF1A1C1E) : theme.scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF2D2F31) : theme.cardColor;

    final colorCode = item['color_code'] ?? '';
    final colorName = isFabric ? item['shade_color'] : item['color'];
    final itemName =
        isFabric ? item['fabric_item_name'] : item['accessory_item_name'];
    final itemCode = isFabric ? item['fabric_code'] : item['accessory_code'];
    final itemType = isFabric ? item['fabric_type'] : item['accessory_type'];

    final isLowStock =
        (item['quantity_available'] ?? 0) <= (item['minimum_stock_level'] ?? 0);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
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
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(PhosphorIcons.x()),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 24,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                // Hero section
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _parseColor(colorCode),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFabric
                              ? PhosphorIcons.scissors(PhosphorIconsStyle.fill)
                              : _getAccessoryIcon(itemType),
                          color: Colors.white,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          itemName ?? 'Unknown Item',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            itemCode ?? 'No Code',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Inventory status card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Inventory Status',
                        PhosphorIcons.stack(),
                      ),
                      const SizedBox(height: 16),

                      // Stock status indicator
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isLowStock
                                  ? theme.colorScheme.error.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isLowStock
                                    ? theme.colorScheme.error.withOpacity(0.3)
                                    : Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    isLowStock
                                        ? theme.colorScheme.error.withOpacity(
                                          0.2,
                                        )
                                        : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                isLowStock
                                    ? PhosphorIcons.warning(
                                      PhosphorIconsStyle.fill,
                                    )
                                    : PhosphorIcons.checkCircle(
                                      PhosphorIconsStyle.fill,
                                    ),
                                color:
                                    isLowStock
                                        ? theme.colorScheme.error
                                        : Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLowStock ? 'Low Stock' : 'In Stock',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isLowStock
                                            ? theme.colorScheme.error
                                            : Colors.green,
                                  ),
                                ),
                                Text(
                                  isLowStock
                                      ? 'Below minimum level'
                                      : 'Stock levels are good',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color:
                                        isLowStock
                                            ? theme.colorScheme.error
                                                .withOpacity(0.8)
                                            : Colors.green.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quantity info
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              label: 'Available',
                              value: '${item['quantity_available'] ?? 0}',
                              suffix: item['unit_type'] ?? '',
                              color: theme.colorScheme.primary,
                              icon: PhosphorIcons.stack(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoCard(
                              label: 'Min Level',
                              value: '${item['minimum_stock_level'] ?? 0}',
                              suffix: item['unit_type'] ?? '',
                              color: theme.colorScheme.tertiary,
                              icon: PhosphorIcons.ruler(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Item details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Item Details', PhosphorIcons.info()),
                      const SizedBox(height: 16),

                      // Basic info
                      _buildDetailRow('Name', itemName ?? 'N/A'),
                      _buildDetailRow('Code', itemCode ?? 'N/A'),
                      _buildDetailRow('Brand', item['brand_name'] ?? 'N/A'),
                      _buildDetailRow('Type', itemType ?? 'N/A'),

                      // Color with swatch
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Color',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (colorCode.isNotEmpty) ...[
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _parseColor(colorCode),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              colorName ?? 'N/A',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildDetailRow('Unit Type', item['unit_type'] ?? 'N/A'),

                      // Created date
                      if (item['created_at'] != null)
                        _buildDetailRow(
                          'Created On',
                          DateFormat(
                            'MMM d, yyyy',
                          ).format(DateTime.parse(item['created_at'])),
                        ),

                      // Extra info if available
                      if (item['supplier_name'] != null)
                        _buildDetailRow('Supplier', item['supplier_name']),
                      if (item['storage_location'] != null)
                        _buildDetailRow('Location', item['storage_location']),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Pricing card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Pricing Information',
                        PhosphorIcons.currencyDollar(),
                      ),
                      const SizedBox(height: 16),

                      // Pricing cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildPriceCard(
                              'Cost',
                              item['cost_per_unit'] ?? 0,
                              theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPriceCard(
                              'Selling Price',
                              item['selling_price_per_unit'] ?? 0,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Profit calculation
                      _buildProfitSection(context),
                    ],
                  ),
                ),

                // Notes section if available
                if (item['notes'] != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Notes', PhosphorIcons.notepad()),
                        const SizedBox(height: 16),
                        Text(
                          item['notes'],
                          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: Icon(PhosphorIcons.trash()),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: Icon(PhosphorIcons.pencilSimple()),
                    label: const Text('Edit'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitSection(BuildContext context) {
    final theme = Theme.of(context);
    final cost = item['cost_per_unit'] ?? 0;
    final price = item['selling_price_per_unit'] ?? 0;
    final profit = price - cost;
    final marginPercent = cost > 0 ? (profit / cost) * 100 : 0;

    Color profitColor;
    String healthText;

    if (marginPercent <= 0) {
      profitColor = theme.colorScheme.error;
      healthText = 'Loss';
    } else if (marginPercent < 15) {
      profitColor = Colors.orange;
      healthText = 'Low Margin';
    } else if (marginPercent < 30) {
      profitColor = Colors.green;
      healthText = 'Good Margin';
    } else {
      profitColor = Colors.green[800]!;
      healthText = 'Excellent Margin';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profit per Unit',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: profitColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      healthText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: profitColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(profit),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: profitColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: marginPercent / 100,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(profitColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Margin',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${marginPercent.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: profitColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: color)),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: '\$').format(amount),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'per ${item['unit_type'] ?? 'unit'}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    String? suffix,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.inter(fontSize: 14, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suffix != null && suffix.isNotEmpty ? '$value $suffix' : value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAccessoryIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'button':
        return PhosphorIcons.circle(PhosphorIconsStyle.fill);
      case 'zipper':
        return PhosphorIcons.arrowLineDown(PhosphorIconsStyle.fill);
      case 'thread':
        return PhosphorIcons.spiral(PhosphorIconsStyle.fill);
      case 'elastic':
        return PhosphorIcons.waveSine(PhosphorIconsStyle.fill);
      case 'lace':
        return PhosphorIcons.flower(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.package(PhosphorIconsStyle.fill);
    }
  }

  Color _parseColor(String colorCode) {
    if (colorCode.isEmpty) return Colors.grey;

    try {
      if (colorCode.startsWith('#')) {
        return Color(
          int.parse(colorCode.substring(1, 7), radix: 16) + 0xFF000000,
        );
      }

      // Map common color names to colors
      switch (colorCode.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'yellow':
          return Colors.yellow;
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.white;
        case 'purple':
          return Colors.purple;
        case 'pink':
          return Colors.pink;
        case 'orange':
          return Colors.orange;
        case 'brown':
          return Colors.brown;
        case 'grey':
        case 'gray':
          return Colors.grey;
        default:
          return Colors.teal;
      }
    } catch (e) {
      return Colors.grey;
    }
  }
}
