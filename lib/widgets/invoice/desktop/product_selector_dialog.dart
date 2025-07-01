import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/invoice_product.dart';

class ProductSelectorDialog extends StatefulWidget {
  final List<InvoiceProduct> initialProducts;
  final Function(List<InvoiceProduct> selectedProducts) onProductsSelected;

  const ProductSelectorDialog({
    super.key,
    required this.initialProducts,
    required this.onProductsSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required List<InvoiceProduct> initialProducts,
    required Function(List<InvoiceProduct> selectedProducts) onProductsSelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ProductSelectorDialog(
            initialProducts: initialProducts,
            onProductsSelected: onProductsSelected,
          ),
    );
  }

  @override
  State<ProductSelectorDialog> createState() => _ProductSelectorDialogState();
}

enum InventoryType { fabric, accessory }

class _ProductSelectorDialogState extends State<ProductSelectorDialog> {
  final _supabase = Supabase.instance.client;
  InventoryType _selectedInventoryType = InventoryType.fabric;
  String _searchQuery = '';
  String? _selectedBrand;
  final _searchController = TextEditingController();
  bool _isLoading = false;
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _availableItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<InvoiceProduct> _selectedProducts = [];
  List<String> _availableBrands = [];

  final List<double> _quickMeters = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0];
  final List<int> _quickQuantities = [1, 2, 3, 4, 5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _selectedProducts = List.from(widget.initialProducts);
    _loadAvailableItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAvailableItems() async {
    setState(() => _isLoading = true);

    try {
      final table =
          _selectedInventoryType == InventoryType.fabric
              ? 'fabric_inventory'
              : 'accessories_inventory';

      // Optimized query - only get essential fields for fast loading
      String selectQuery;
      if (_selectedInventoryType == InventoryType.fabric) {
        selectQuery = '''
          id, fabric_code, fabric_item_name, shade_color, color_code, 
          unit_type, quantity_available, selling_price_per_unit,
          full_kandora_price, adult_kandora_price, full_kandora_yards, adult_kandora_yards,
          brands!inner(name),
          inventory_categories!inner(category_name)
        ''';
      } else {
        selectQuery = '''
          id, accessory_code, accessory_item_name, color, color_code,
          unit_type, quantity_available, selling_price_per_unit,
          brands!inner(name),
          inventory_categories!inner(category_name)
        ''';
      }

      var query = _supabase
          .from(table)
          .select(selectQuery)
          .eq('is_active', true)
          .limit(100); // Limit for faster loading

      final response = await query.order('created_at', ascending: false);
      final items = List<Map<String, dynamic>>.from(response);

      // Extract brands efficiently
      final brands =
          items
              .map((item) => item['brands']?['name'] as String?)
              .where((brand) => brand != null && brand.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();
      brands.sort();

      setState(() {
        _availableItems = items;
        _filteredItems = items;
        _availableBrands = brands;
        _isLoading = false;
      });

      // Apply search if needed
      if (_searchQuery.isNotEmpty) {
        _filterItems(_searchQuery);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _filterItems(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _searchQuery = query.toLowerCase();

        if (_searchQuery.isEmpty && _selectedBrand == null) {
          _filteredItems = _availableItems;
        } else {
          _filteredItems =
              _availableItems.where((item) {
                final isFabric = _selectedInventoryType == InventoryType.fabric;
                final itemName =
                    (isFabric
                            ? item['fabric_item_name']
                            : item['accessory_item_name'])
                        ?.toString()
                        .toLowerCase() ??
                    '';
                final itemCode =
                    (isFabric ? item['fabric_code'] : item['accessory_code'])
                        ?.toString()
                        .toLowerCase() ??
                    '';
                final brandName =
                    item['brands']?['name']?.toString().toLowerCase() ?? '';
                final categoryName =
                    item['inventory_categories']?['category_name']
                        ?.toString()
                        .toLowerCase() ??
                    '';

                final matchesSearch =
                    _searchQuery.isEmpty ||
                    itemName.contains(_searchQuery) ||
                    itemCode.contains(_searchQuery) ||
                    brandName.contains(_searchQuery) ||
                    categoryName.contains(_searchQuery);

                final matchesBrand =
                    _selectedBrand == null ||
                    brandName == _selectedBrand?.toLowerCase();

                return matchesSearch && matchesBrand;
              }).toList();
        }
      });
    });
  }

  void _filterByBrand(String? brand) {
    setState(() {
      _selectedBrand = brand;
      _filterItems(_searchQuery);
    });
  }

  void _addProductQuick(
    Map<String, dynamic> item,
    double quantity, {
    String? kandoraType,
    double? kandoraPrice,
    double? yardsPerKandora,
  }) {
    final isFabric = _selectedInventoryType == InventoryType.fabric;
    final itemId = item['id'];
    final itemName =
        isFabric ? item['fabric_item_name'] : item['accessory_item_name'];
    final colorCode = item['color_code'];

    final isKandora = kandoraType != null;
    final finalItemName = isKandora ? '$itemName ($kandoraType)' : itemName;

    // For Kandora, unit price is per Kandora. For others, it's per unit.
    final unitPrice =
        isKandora
            ? kandoraPrice!
            : (item['selling_price_per_unit'] as num).toDouble();

    // For Kandora, unit is "Kandora". For others, it's from inventory.
    final unitType = isKandora ? 'Kandora' : item['unit_type'];

    final existingIndex = _selectedProducts.indexWhere(
      (p) => p.inventoryId == itemId && p.name == finalItemName,
    );

    setState(() {
      if (existingIndex != -1) {
        // If it's a Kandora, increment by 1 Kandora. Otherwise, by the passed quantity.
        _selectedProducts[existingIndex].quantity += isKandora ? 1 : quantity;
      } else {
        _selectedProducts.add(
          InvoiceProduct(
            id: const Uuid().v4(),
            name: finalItemName,
            description:
                colorCode ?? (isFabric ? item['shade_color'] : item['color']),
            unitPrice: unitPrice,
            // For Kandora, initial quantity is 1.
            quantity: isKandora ? 1 : quantity,
            unit: unitType,
            inventoryId: itemId,
            inventoryType: isFabric ? 'fabric' : 'accessory',
            // Store the yardage for inventory deduction separately for Kandoras
            inventoryDeductionQuantity: isKandora ? yardsPerKandora : null,
          ),
        );
      }
    });

    // Show quick feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $finalItemName'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQuantitySelector(Map<String, dynamic> item) {
    final isFabric = _selectedInventoryType == InventoryType.fabric;

    // Kandora specific data
    final fullKandoraPrice =
        (item['full_kandora_price'] as num?)?.toDouble() ?? 0.0;
    final adultKandoraPrice =
        (item['adult_kandora_price'] as num?)?.toDouble() ?? 0.0;
    final fullKandoraYards =
        (item['full_kandora_yards'] as num?)?.toDouble() ?? 3.5;
    final adultKandoraYards =
        (item['adult_kandora_yards'] as num?)?.toDouble() ?? 2.5;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _parseColor(item['color_code']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isFabric
                              ? PhosphorIcons.scissors()
                              : PhosphorIcons.package(),
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFabric
                                  ? item['fabric_item_name']
                                  : item['accessory_item_name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'AED ${NumberFormat('#,##0.00').format(item['selling_price_per_unit'])} per ${item['unit_type']}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick selection buttons
                  if (isFabric) ...[
                    Text(
                      'Select Kandora Type',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (fullKandoraPrice > 0)
                          Expanded(
                            child: _buildKandoraButton(
                              label: 'Full Kandora',
                              price: fullKandoraPrice,
                              yards: fullKandoraYards,
                              onPressed: () {
                                _addProductQuick(
                                  item,
                                  1, // Quantity is 1 kandora
                                  kandoraType: 'Full Kandora',
                                  kandoraPrice: fullKandoraPrice,
                                  yardsPerKandora: fullKandoraYards,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        if (fullKandoraPrice > 0 && adultKandoraPrice > 0)
                          const SizedBox(width: 16),
                        if (adultKandoraPrice > 0)
                          Expanded(
                            child: _buildKandoraButton(
                              label: 'Adult Kandora',
                              price: adultKandoraPrice,
                              yards: adultKandoraYards,
                              onPressed: () {
                                _addProductQuick(
                                  item,
                                  1, // Quantity is 1 kandora
                                  kandoraType: 'Adult Kandora',
                                  kandoraPrice: adultKandoraPrice,
                                  yardsPerKandora: adultKandoraYards,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                      ],
                    ),
                    if (fullKandoraPrice <= 0 && adultKandoraPrice <= 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No Kandora pricing set for this fabric. You can add custom meters below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                  ] else ...[
                    Text(
                      'Quick Quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _quickQuantities.map((amount) {
                            return ElevatedButton(
                              onPressed: () {
                                _addProductQuick(item, amount.toDouble());
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: InventoryDesignConfig
                                    .primaryColor
                                    .withOpacity(0.1),
                                foregroundColor:
                                    InventoryDesignConfig.primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('$amount pcs'),
                            );
                          }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Custom input - REMOVED for fabrics to enforce Kandora selection
                  if (!isFabric)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            autofocus: true,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: isFabric,
                            ),
                            decoration: InputDecoration(
                              labelText:
                                  'Custom ${isFabric ? 'Meters' : 'Quantity'}',
                              suffixText: isFabric ? 'm' : 'pcs',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onFieldSubmitted: (value) {
                              final quantity = double.tryParse(value) ?? 0;
                              if (quantity > 0) {
                                _addProductQuick(item, quantity);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: InventoryDesignConfig.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildKandoraButton({
    required String label,
    required double price,
    required double yards,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: InventoryDesignConfig.primaryColor.withOpacity(0.1),
        foregroundColor: InventoryDesignConfig.primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'AED ${NumberFormat('#,##0').format(price)} (${yards}y)',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? colorCode) {
    if (colorCode == null || colorCode.isEmpty)
      return InventoryDesignConfig.primaryColor;
    try {
      if (colorCode.startsWith('#')) {
        String hex = colorCode.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        }
      }
      return InventoryDesignConfig.primaryColor;
    } catch (e) {
      return InventoryDesignConfig.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.shoppingBag(),
            size: 24,
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: 16),
          const Text(
            'Select Products',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_selectedProducts.length} selected',
              style: TextStyle(
                color: InventoryDesignConfig.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      children: [
        // Left panel - Products
        Expanded(
          flex: 3,
          child: Column(
            children: [_buildControls(), Expanded(child: _buildProductsList())],
          ),
        ),

        // Divider
        Container(width: 1, color: Colors.grey.shade200),

        // Right panel - Selected items
        Expanded(flex: 2, child: _buildSelectedPanel()),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Type selector
          Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  'Fabrics',
                  PhosphorIcons.scissors(),
                  InventoryType.fabric,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeButton(
                  'Accessories',
                  PhosphorIcons.package(),
                  InventoryType.accessory,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Enhanced search
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products, brands, categories...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  PhosphorIcons.magnifyingGlass(),
                  color: Colors.grey.shade500,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade500),
                          onPressed: () {
                            _searchController.clear();
                            _filterItems('');
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _filterItems,
            ),
          ),

          const SizedBox(height: 12),

          // Brand chips
          if (_availableBrands.isNotEmpty) _buildBrandChips(),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, IconData icon, InventoryType type) {
    final isSelected = _selectedInventoryType == type;
    return Material(
      color:
          isSelected
              ? InventoryDesignConfig.primaryColor
              : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedInventoryType = type;
            _selectedBrand = null;
          });
          _loadAvailableItems();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableBrands.length + 1,
        itemBuilder: (context, index) {
          final brand = index == 0 ? null : _availableBrands[index - 1];
          final isSelected = _selectedBrand == brand;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(brand ?? 'All'),
              selected: isSelected,
              onSelected: (selected) => _filterByBrand(selected ? brand : null),
              backgroundColor: Colors.grey.shade100,
              selectedColor: InventoryDesignConfig.primaryColor.withOpacity(
                0.2,
              ),
              checkmarkColor: InventoryDesignConfig.primaryColor,
              labelStyle: TextStyle(
                color:
                    isSelected
                        ? InventoryDesignConfig.primaryColor
                        : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected
                          ? InventoryDesignConfig.primaryColor
                          : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedInventoryType == InventoryType.fabric
                  ? PhosphorIcons.scissors()
                  : PhosphorIcons.package(),
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            if (_searchQuery.isNotEmpty || _selectedBrand != null)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedBrand = null;
                    _filteredItems = _availableItems;
                  });
                },
                child: const Text('Clear filters'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) => _buildProductCard(_filteredItems[index]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final isFabric = _selectedInventoryType == InventoryType.fabric;
    final itemName =
        isFabric ? item['fabric_item_name'] : item['accessory_item_name'];
    final itemCode = isFabric ? item['fabric_code'] : item['accessory_code'];
    final unitPrice = (item['selling_price_per_unit'] as num).toDouble();
    final stock = (item['quantity_available'] as num).toInt();
    final unit = item['unit_type'];
    final brandName = item['brands']?['name'];
    final categoryName = item['inventory_categories']?['category_name'];

    final fullKandoraPrice = isFabric ? (item['full_kandora_price'] as num?)?.toDouble() ?? 0.0 : 0.0;
    final adultKandoraPrice = isFabric ? (item['adult_kandora_price'] as num?)?.toDouble() ?? 0.0 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showQuantitySelector(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Color indicator / Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _parseColor(item['color_code']),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isFabric
                        ? PhosphorIcons.scissors()
                        : PhosphorIcons.package(),
                    size: 24,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (brandName != null)
                        Text(
                          '$brandName • ${categoryName ?? 'Uncategorized'}',
                          style: TextStyle(
                            color: InventoryDesignConfig.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        '$itemCode • $stock $unit in stock',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price and quick add
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isFabric && (fullKandoraPrice > 0 || adultKandoraPrice > 0)) ...[
                      if (fullKandoraPrice > 0)
                        _buildKandoraPriceTag('Full', fullKandoraPrice),
                      if (adultKandoraPrice > 0) ...[
                        const SizedBox(height: 4),
                        _buildKandoraPriceTag('Adult', adultKandoraPrice),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${NumberFormat.currency(symbol: 'AED ', decimalDigits: 2).format(unitPrice)} / $unit',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        NumberFormat.currency(symbol: 'AED ', decimalDigits: 2).format(unitPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'per $unit',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKandoraPriceTag(String label, double price) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          NumberFormat.currency(symbol: 'AED ', decimalDigits: 0).format(price),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPanel() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected (${_selectedProducts.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedProducts.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selectedProducts.clear()),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),

        // Selected items list
        Expanded(
          child:
              _selectedProducts.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.shoppingBagOpen(),
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items selected',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _selectedProducts.length,
                    itemBuilder: (context, index) {
                      final product = _selectedProducts[index];
                      final isKandora =
                          product.name.contains('(Full Kandora)') ||
                          product.name.contains('(Adult Kandora)');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _parseColor(product.description),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isKandora
                                        ? PhosphorIcons.scissors()
                                        : PhosphorIcons.package(),
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isKandora)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2.0,
                                          ),
                                          child: Text(
                                            'Total Yards: ${(product.quantity * (product.inventoryDeductionQuantity ?? 0.0)).toStringAsFixed(1)}y',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AED ${NumberFormat('#,##0.00').format(product.totalPrice)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: InventoryDesignConfig.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Quantity controls
                                _buildQuantityControl(
                                  onDecrement: () {
                                    setState(() {
                                      if (product.quantity > 1) {
                                        product.quantity--;
                                      } else {
                                        _selectedProducts.removeAt(index);
                                      }
                                    });
                                  },
                                  onIncrement: () {
                                    setState(() {
                                      product.quantity++;
                                    });
                                  },
                                  quantity: product.quantity.toInt(),
                                ),
                                const SizedBox(width: 8),
                                // Delete button
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () => _selectedProducts.removeAt(index),
                                      ),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  splashRadius: 20,
                                  tooltip: 'Remove Item',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),

        // Total
        if (_selectedProducts.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'AED ${NumberFormat('#,##0.00').format(_selectedProducts.fold(0.0, (sum, p) => sum + p.totalPrice))}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityControl({
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required int quantity,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: onDecrement,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
            splashRadius: 18,
            color: Colors.grey.shade700,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              quantity.toString(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: onIncrement,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
            splashRadius: 18,
            color: InventoryDesignConfig.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final hasProducts = _selectedProducts.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (!hasProducts)
            Text(
              'Select at least 1 product',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed:
                hasProducts
                    ? () {
                      Navigator.of(context).pop();
                      widget.onProductsSelected(_selectedProducts);
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  hasProducts
                      ? InventoryDesignConfig.primaryColor
                      : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(hasProducts ? 'Add to Invoice' : 'Select Products'),
          ),
        ],
      ),
    );
  }
}
