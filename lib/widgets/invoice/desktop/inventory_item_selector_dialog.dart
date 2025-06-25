import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/invoice_product.dart'; // Import the shared InvoiceProduct model

class InventoryItemSelectorDialog extends StatefulWidget {
  final String inventoryType;

  const InventoryItemSelectorDialog({super.key, required this.inventoryType});

  static Future<List<InvoiceProduct>?> show(
    BuildContext context, {
    required String inventoryType,
  }) {
    return showDialog<List<InvoiceProduct>>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              InventoryItemSelectorDialog(inventoryType: inventoryType),
    );
  }

  @override
  State<InventoryItemSelectorDialog> createState() =>
      _InventoryItemSelectorDialogState();
}

class _InventoryItemSelectorDialogState
    extends State<InventoryItemSelectorDialog> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _inventoryItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final Map<String, SelectedItem> _selectedItems = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
    _searchController.addListener(() => _filterItems(_searchController.text));
  }

  Future<void> _loadInventoryItems() async {
    setState(() => _isLoading = true);

    try {
      final table =
          widget.inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';

      final query = _supabase
          .from(table)
          .select('''
            *,
            brands ( id, name ),
            inventory_categories ( id, category_name )
          ''')
          .eq('is_active', true)
          .gt('quantity_available', 0);

      final response = await query;

      setState(() {
        _inventoryItems = response;
        _filterItems(_searchQuery);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading inventory: $e')));
      }
    }
  }

  Widget _buildHeader(Color color, bool isFabric) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXXL,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          topRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(
              isFabric ? PhosphorIcons.scissors() : PhosphorIcons.package(),
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select ${isFabric ? 'Fabric' : 'Accessories'}',
                  style: InventoryDesignConfig.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                Text(
                  'Choose items from your inventory',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(PhosphorIcons.x(), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndStats(Color color, bool isFabric) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: InventoryDesignConfig.borderPrimary),
            ),
            child: TextField(
              controller: _searchController,
              style: InventoryDesignConfig.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search by name, code, color, brand...',
                hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
                prefixIcon: Icon(
                  PhosphorIcons.magnifyingGlass(),
                  size: 16,
                  color: InventoryDesignConfig.textSecondary,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(PhosphorIcons.x(), size: 14),
                          onPressed: () {
                            _searchController.clear();
                            _filterItems('');
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingM),

          // Stats row
          Row(
            children: [
              _buildStatChip(
                icon: PhosphorIcons.stack(),
                label: 'Available Items',
                value: _filteredItems.length.toString(),
                color: color,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              _buildStatChip(
                icon: PhosphorIcons.shoppingCart(),
                label: 'Selected',
                value: _selectedItems.length.toString(),
                color: InventoryDesignConfig.primaryColor,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingM,
                  vertical: InventoryDesignConfig.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFabric
                          ? PhosphorIcons.scissors()
                          : PhosphorIcons.package(),
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${isFabric ? 'Fabric' : 'Accessory'} Inventory',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        _filteredItems = _inventoryItems;
      } else {
        _filteredItems =
            _inventoryItems.where((item) {
              final name =
                  widget.inventoryType == 'fabric'
                      ? (item['fabric_item_name']?.toString() ?? '')
                          .toLowerCase()
                      : (item['accessory_item_name']?.toString() ?? '')
                          .toLowerCase();
              final code =
                  widget.inventoryType == 'fabric'
                      ? (item['fabric_code']?.toString() ?? '').toLowerCase()
                      : (item['accessory_code']?.toString() ?? '')
                          .toLowerCase();
              final color =
                  widget.inventoryType == 'fabric'
                      ? (item['shade_color']?.toString() ?? '').toLowerCase()
                      : (item['color']?.toString() ?? '').toLowerCase();
              final brand =
                  (item['brands']?['name']?.toString() ?? '').toLowerCase();
              final category =
                  (item['inventory_categories']?['category_name']?.toString() ??
                          '')
                      .toLowerCase();

              return name.contains(_searchQuery) ||
                  code.contains(_searchQuery) ||
                  color.contains(_searchQuery) ||
                  brand.contains(_searchQuery) ||
                  category.contains(_searchQuery);
            }).toList();
      }
    });
  }

  void _updateQuantity(String itemId, double quantity) {
    final item = _inventoryItems.firstWhere((i) => i['id'] == itemId);
    final availableStock =
        (item['quantity_available'] as num?)?.toDouble() ?? 0.0;

    setState(() {
      if (quantity > 0 && quantity <= availableStock) {
        _selectedItems[itemId] = SelectedItem(
          item: item,
          quantity: quantity,
          type: widget.inventoryType,
        );
      } else if (quantity <= 0) {
        _selectedItems.remove(itemId);
      }
    });
  }

  void _confirmSelection() {
    final products =
        _selectedItems.values.map((selected) {
          final name =
              widget.inventoryType == 'fabric'
                  ? (selected.item['fabric_item_name']?.toString() ??
                      'Unknown Fabric')
                  : (selected.item['accessory_item_name']?.toString() ??
                      'Unknown Accessory');

          final code =
              widget.inventoryType == 'fabric'
                  ? (selected.item['fabric_code']?.toString() ?? 'NO-CODE')
                  : (selected.item['accessory_code']?.toString() ?? 'NO-CODE');

          final color =
              widget.inventoryType == 'fabric'
                  ? (selected.item['shade_color']?.toString() ?? 'No Color')
                  : (selected.item['color']?.toString() ?? 'No Color');

          final brandName =
              selected.item['brands']?['name']?.toString() ?? 'No Brand';
          final categoryName =
              selected.item['inventory_categories']?['category_name']
                  ?.toString() ??
              'Uncategorized';

          final description = [code, color, brandName, categoryName]
              .where(
                (e) => e.isNotEmpty && e != 'No Brand' && e != 'Uncategorized',
              )
              .join(' • ');

          return InvoiceProduct(
            id: const Uuid().v4(),
            name: name,
            description: description.isEmpty ? 'No description' : description,
            unitPrice:
                (selected.item['selling_price_per_unit'] as num?)?.toDouble() ??
                0.0,
            quantity: selected.quantity, // Already double
            unit: selected.item['unit_type']?.toString() ?? 'pcs',
            inventoryId: selected.item['id']?.toString(),
            inventoryType: widget.inventoryType,
          );
        }).toList();

    Navigator.pop(context, products);
  }

  @override
  Widget build(BuildContext context) {
    final isFabric = widget.inventoryType == 'fabric';
    final color =
        isFabric
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(color, isFabric),
              _buildSearchAndStats(color, isFabric),
              Expanded(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingM,
        vertical: InventoryDesignConfig.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      itemCount: _filteredItems.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: InventoryDesignConfig.spacingM),
      itemBuilder:
          (context, index) => _buildInventoryItem(_filteredItems[index]),
    );
  }

  Widget _buildInventoryItem(Map<String, dynamic> item) {
    final itemId = item['id']?.toString() ?? '';
    if (itemId.isEmpty) return const SizedBox.shrink();

    final selectedQuantity = _selectedItems[itemId]?.quantity ?? 0.0;
    final isSelected = selectedQuantity > 0;
    final availableStock =
        (item['quantity_available'] as num?)?.toDouble() ?? 0.0;
    final minStock = (item['minimum_stock_level'] as num?)?.toDouble() ?? 0.0;
    final isLowStock = availableStock <= minStock;

    final isFabric = widget.inventoryType == 'fabric';
    final itemColor =
        isFabric
            ? InventoryDesignConfig.infoColor
            : InventoryDesignConfig.successColor;

    final itemName =
        isFabric
            ? (item['fabric_item_name']?.toString() ?? 'Unknown Fabric')
            : (item['accessory_item_name']?.toString() ?? 'Unknown Accessory');

    final itemCode =
        isFabric
            ? (item['fabric_code']?.toString() ?? 'NO-CODE')
            : (item['accessory_code']?.toString() ?? 'NO-CODE');

    final colorName =
        isFabric
            ? (item['shade_color']?.toString() ?? 'No Color')
            : (item['color']?.toString() ?? 'No Color');

    final brandName = item['brands']?['name']?.toString() ?? 'No Brand';
    final categoryName =
        item['inventory_categories']?['category_name']?.toString() ??
        'Uncategorized';
    final unitType = item['unit_type']?.toString() ?? 'pcs';
    final sellingPrice =
        (item['selling_price_per_unit'] as num?)?.toDouble() ?? 0.0;
    final colorCode = item['color_code']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color:
            isSelected
                ? itemColor.withOpacity(0.05)
                : InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(
          color:
              isSelected
                  ? itemColor.withOpacity(0.3)
                  : InventoryDesignConfig.borderPrimary,
          width: isSelected ? 2 : 1,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: itemColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Row(
        children: [
          // Item icon and color
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _parseColor(colorCode).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _parseColor(colorCode).withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Icon(
                isFabric ? PhosphorIcons.scissors() : PhosphorIcons.package(),
                size: 20,
                color: _parseColor(colorCode),
              ),
            ),
          ),

          const SizedBox(width: InventoryDesignConfig.spacingL),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        style: InventoryDesignConfig.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.surfaceAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        itemCode,
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Text(
                      '$colorName • $brandName',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        categoryName,
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: itemColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    // Stock status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isLowStock
                                ? InventoryDesignConfig.warningColor
                                    .withOpacity(0.1)
                                : InventoryDesignConfig.successColor
                                    .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.stack(),
                            size: 12,
                            color:
                                isLowStock
                                    ? InventoryDesignConfig.warningColor
                                    : InventoryDesignConfig.successColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${availableStock.toStringAsFixed(availableStock.truncateToDouble() == availableStock ? 0 : 1)} $unitType',
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color:
                                  isLowStock
                                      ? InventoryDesignConfig.warningColor
                                      : InventoryDesignConfig.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.primaryColor.withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        NumberFormat.currency(
                          symbol: 'AED ',
                        ).format(sellingPrice),
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: InventoryDesignConfig.spacingL),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: InventoryDesignConfig.borderPrimary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed:
                      selectedQuantity > 0
                          ? () => _updateQuantity(
                            itemId,
                            selectedQuantity - (isFabric ? 0.5 : 1),
                          )
                          : null,
                  icon: Icon(
                    PhosphorIcons.minus(),
                    size: 16,
                    color:
                        selectedQuantity > 0
                            ? InventoryDesignConfig.textSecondary
                            : InventoryDesignConfig.textTertiary,
                  ),
                ),

                Container(
                  constraints: const BoxConstraints(minWidth: 40),
                  child: Text(
                    selectedQuantity.toStringAsFixed(
                      selectedQuantity.truncateToDouble() == selectedQuantity
                          ? 0
                          : 1,
                    ),
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                IconButton(
                  onPressed:
                      selectedQuantity < availableStock
                          ? () => _updateQuantity(
                            itemId,
                            selectedQuantity + (isFabric ? 0.5 : 1),
                          )
                          : null,
                  icon: Icon(
                    PhosphorIcons.plus(),
                    size: 16,
                    color:
                        selectedQuantity < availableStock
                            ? InventoryDesignConfig.textSecondary
                            : InventoryDesignConfig.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFabric = widget.inventoryType == 'fabric';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusXL,
              ),
            ),
            child: Icon(
              isFabric ? PhosphorIcons.scissors() : PhosphorIcons.package(),
              size: 48,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXL),
          Text(
            _searchQuery.isNotEmpty
                ? 'No items found'
                : 'No ${isFabric ? 'fabric' : 'accessories'} available',
            style: InventoryDesignConfig.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search criteria'
                : 'Add some ${isFabric ? 'fabric' : 'accessories'} to your inventory first',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXXL,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          bottomRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(
          top: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Summary
          if (_selectedItems.isNotEmpty)
            Text(
              '${_selectedItems.length} item(s) selected',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            )
          else
            const SizedBox(),

          // Action buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: InventoryDesignConfig.textSecondary,
                  side: BorderSide(color: InventoryDesignConfig.borderPrimary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.x(), size: 16),
                    const SizedBox(width: 8),
                    const Text('Cancel'),
                  ],
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingL),
              FilledButton(
                onPressed: _selectedItems.isNotEmpty ? _confirmSelection : null,
                style: FilledButton.styleFrom(
                  backgroundColor: InventoryDesignConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.check(), size: 16),
                    const SizedBox(width: 8),
                    Text('Add ${_selectedItems.length} Item(s)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorCode) {
    if (colorCode.isEmpty) return InventoryDesignConfig.primaryColor;

    try {
      if (colorCode.startsWith('#')) {
        String hexCode = colorCode.substring(1);
        if (hexCode.length == 6) {
          return Color(int.parse('FF$hexCode', radix: 16));
        }
      }
      return InventoryDesignConfig.primaryColor;
    } catch (e) {
      return InventoryDesignConfig.primaryColor;
    }
  }
}

class SelectedItem {
  final Map<String, dynamic> item;
  final double quantity;
  final String type;

  SelectedItem({
    required this.item,
    required this.quantity,
    required this.type,
  });
}
