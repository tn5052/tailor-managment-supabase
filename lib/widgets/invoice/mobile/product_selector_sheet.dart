import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/invoice_product.dart';

enum InventoryType { fabric, accessory }

class ProductSelectorSheet extends StatefulWidget {
  final List<InvoiceProduct> initialProducts;
  final Function(List<InvoiceProduct>) onProductsSelected;

  const ProductSelectorSheet({
    Key? key,
    required this.initialProducts,
    required this.onProductsSelected,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required List<InvoiceProduct> initialProducts,
    required Function(List<InvoiceProduct>) onProductsSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      useSafeArea: true,
      builder: (context) => ProductSelectorSheet(
        initialProducts: initialProducts,
        onProductsSelected: onProductsSelected,
      ),
    );
  }

  @override
  _ProductSelectorSheetState createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<ProductSelectorSheet>
    with TickerProviderStateMixin {
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

  // Animation controllers
  late AnimationController _sheetAnimationController;
  late Animation<double> _sheetAnimation;

  final List<double> _quickMeters = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0];
  final List<int> _quickQuantities = [1, 2, 3, 4, 5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _selectedProducts = List.from(widget.initialProducts);
    _initializeAnimations();
    _loadAvailableItems();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sheetAnimationController.forward();
    });
  }

  void _initializeAnimations() {
    _sheetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _sheetAnimation = CurvedAnimation(
      parent: _sheetAnimationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _sheetAnimationController.dispose();
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
            backgroundColor: InventoryDesignConfig.errorColor,
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
        backgroundColor: InventoryDesignConfig.successColor,
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: InventoryDesignConfig.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(InventoryDesignConfig.radiusXL),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: InventoryDesignConfig.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _parseColor(item['color_code']),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: InventoryDesignConfig.borderPrimary,
                      ),
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
                          style: InventoryDesignConfig.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'AED ${NumberFormat('#,##0.00').format(item['selling_price_per_unit'])} per ${item['unit_type']}',
                          style: InventoryDesignConfig.bodyMedium.copyWith(
                            color: InventoryDesignConfig.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    icon: Icon(PhosphorIcons.x()),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick selection buttons
                    if (isFabric) ...[
                      Text(
                        'Select Kandora Type',
                        style: InventoryDesignConfig.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (fullKandoraPrice > 0 || adultKandoraPrice > 0) ...[
                        if (fullKandoraPrice > 0)
                          _buildKandoraButton(
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
                        if (fullKandoraPrice > 0)
                          const SizedBox(height: 12),
                        if (adultKandoraPrice > 0)
                          _buildKandoraButton(
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
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: InventoryDesignConfig.warningColor
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: InventoryDesignConfig.warningColor
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'No Kandora pricing set for this fabric. You can add custom meters below.',
                            textAlign: TextAlign.center,
                            style: InventoryDesignConfig.bodyMedium.copyWith(
                              color: InventoryDesignConfig.warningColor,
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Quick Quantity',
                        style: InventoryDesignConfig.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickQuantities.map((amount) {
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
                    if (!isFabric) ...[
                      Text(
                        'Custom Quantity',
                        style: InventoryDesignConfig.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              autofocus: true,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: isFabric,
                              ),
                              style: InventoryDesignConfig.bodyLarge,
                              decoration: InputDecoration(
                                labelText:
                                    'Custom ${isFabric ? 'Meters' : 'Quantity'}',
                                suffixText: isFabric ? 'm' : 'pcs',
                                filled: true,
                                fillColor: InventoryDesignConfig.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: InventoryDesignConfig.borderPrimary,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: InventoryDesignConfig.borderPrimary,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: InventoryDesignConfig.primaryColor,
                                    width: 2,
                                  ),
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
                  ],
                ),
              ),
            ),
          ],
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: InventoryDesignConfig.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AED ${NumberFormat('#,##0').format(price)} (${yards}y)',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? colorCode) {
    if (colorCode == null || colorCode.isEmpty) {
      return InventoryDesignConfig.primaryColor;
    }
    
    try {
      if (colorCode.startsWith('#')) {
        String hex = colorCode.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        }
      }
      
      // Map common color names to more vibrant colors
      switch (colorCode.toLowerCase()) {
        case 'red':
          return const Color(0xFFE53E3E);
        case 'blue':
          return const Color(0xFF3182CE);
        case 'green':
          return const Color(0xFF38A169);
        case 'yellow':
          return const Color(0xFFD69E2E);
        case 'black':
          return const Color(0xFF2D3748);
        case 'white':
          return const Color(0xFFF7FAFC);
        case 'purple':
          return const Color(0xFF805AD5);
        case 'pink':
          return const Color(0xFFED64A6);
        case 'orange':
          return const Color(0xFFDD6B20);
        case 'brown':
          return const Color(0xFF8B4513);
        case 'grey':
        case 'gray':
          return const Color(0xFF718096);
        case 'navy':
          return const Color(0xFF2C5282);
        case 'teal':
          return const Color(0xFF319795);
        case 'lime':
          return const Color(0xFF68D391);
        case 'cyan':
          return const Color(0xFF0BC5EA);
        case 'amber':
          return const Color(0xFFF6AD55);
        default:
          return InventoryDesignConfig.primaryColor;
      }
    } catch (e) {
      return InventoryDesignConfig.primaryColor;
    }
  }

  Future<void> _handleClose() async {
    HapticFeedback.lightImpact();
    await _sheetAnimationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final safeAreaTop = mediaQuery.padding.top;

    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.4 * _sheetAnimation.value),
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: safeAreaTop + 40,
                  bottom: 0,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (screenHeight - safeAreaTop - 40) * (1 - _sheetAnimation.value),
                    ),
                    child: _buildSheetContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetContent() {
    return Container(
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.fromLTRB(
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingS,
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingL,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                    border: Border.all(
                      color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    PhosphorIcons.shoppingBag(),
                    color: InventoryDesignConfig.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Products',
                        style: InventoryDesignConfig.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        '${_selectedProducts.length} selected',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHeaderActionButton(
                  icon: PhosphorIcons.x(),
                  onTap: _handleClose,
                  semanticLabel: 'Close product selector',
                ),
              ],
            ),
          ),

          Container(height: 1, color: InventoryDesignConfig.borderSecondary),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            ),
            child: Icon(
              icon,
              size: 18,
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildControls(),
        Expanded(child: _buildProductsList()),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
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
              color: InventoryDesignConfig.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: InventoryDesignConfig.borderPrimary),
            ),
            child: TextField(
              controller: _searchController,
              style: InventoryDesignConfig.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search products, brands, categories...',
                hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.textTertiary,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                  child: Icon(
                    PhosphorIcons.magnifyingGlass(),
                    size: 18,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          PhosphorIcons.x(),
                          size: 16,
                          color: InventoryDesignConfig.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterItems('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: InventoryDesignConfig.spacingM,
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedInventoryType = type;
            _selectedBrand = null;
          });
          _loadAvailableItems();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? InventoryDesignConfig.primaryColor
                : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? InventoryDesignConfig.primaryColor
                  : InventoryDesignConfig.borderPrimary,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : InventoryDesignConfig.textSecondary,
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
              backgroundColor: InventoryDesignConfig.surfaceLight,
              selectedColor: InventoryDesignConfig.primaryColor.withOpacity(0.2),
              checkmarkColor: InventoryDesignConfig.primaryColor,
              labelStyle: InventoryDesignConfig.bodySmall.copyWith(
                color: isSelected
                    ? InventoryDesignConfig.primaryColor
                    : InventoryDesignConfig.textSecondary,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? InventoryDesignConfig.primaryColor
                      : InventoryDesignConfig.borderPrimary,
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
      return const Center(
        child: CircularProgressIndicator(
          color: InventoryDesignConfig.primaryColor,
        ),
      );
    }

    if (_filteredItems.isEmpty) {
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
                _selectedInventoryType == InventoryType.fabric
                    ? PhosphorIcons.scissors()
                    : PhosphorIcons.package(),
                size: 48,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            Text(
              'No items found',
              style: InventoryDesignConfig.headlineMedium,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              'Try searching with different keywords',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedBrand != null) ...[
              const SizedBox(height: InventoryDesignConfig.spacingXL),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedBrand = null;
                    _filteredItems = _availableItems;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: InventoryDesignConfig.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXL,
      ),
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
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        child: InkWell(
          onTap: () => _showQuantitySelector(item),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Row(
              children: [
                // Color indicator / Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _parseColor(item['color_code']),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: InventoryDesignConfig.borderPrimary,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _parseColor(item['color_code']).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFabric
                        ? PhosphorIcons.scissors()
                        : PhosphorIcons.package(),
                    size: 28,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: InventoryDesignConfig.spacingL),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: InventoryDesignConfig.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      if (brandName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: InventoryDesignConfig.spacingS,
                            vertical: InventoryDesignConfig.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              InventoryDesignConfig.radiusS,
                            ),
                          ),
                          child: Text(
                            '$brandName • ${categoryName ?? 'Uncategorized'}',
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color: InventoryDesignConfig.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        '$itemCode • $stock $unit in stock',
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.textSecondary,
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
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.textTertiary,
                        ),
                      ),
                    ] else ...[
                      Text(
                        NumberFormat.currency(symbol: 'AED ', decimalDigits: 2).format(unitPrice),
                        style: InventoryDesignConfig.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: InventoryDesignConfig.successColor,
                        ),
                      ),
                      Text(
                        'per $unit',
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.textSecondary,
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
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          NumberFormat.currency(symbol: 'AED ', decimalDigits: 0).format(price),
          style: InventoryDesignConfig.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: InventoryDesignConfig.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final hasProducts = _selectedProducts.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingL + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          top: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Total if products selected
          if (hasProducts) ...[
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
                border: Border.all(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total (${_selectedProducts.length} items):',
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'AED ${NumberFormat('#,##0.00').format(_selectedProducts.fold(0.0, (sum, p) => sum + p.totalPrice))}',
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: InventoryDesignConfig.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Cancel',
                  icon: PhosphorIcons.x(),
                  color: InventoryDesignConfig.textSecondary,
                  backgroundColor: InventoryDesignConfig.surfaceLight,
                  onTap: _handleClose,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                flex: 2,
                child: _buildActionButton(
                  label: hasProducts ? 'Add to Invoice' : 'Select Products',
                  icon: hasProducts ? PhosphorIcons.check() : PhosphorIcons.shoppingBag(),
                  color: Colors.white,
                  backgroundColor: hasProducts
                      ? InventoryDesignConfig.primaryColor
                      : InventoryDesignConfig.textTertiary,
                  onTap: hasProducts
                      ? () {
                          widget.onProductsSelected(_selectedProducts);
                          _handleClose();
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    IconData? icon,
    required Color color,
    required Color backgroundColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.mediumImpact();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: InventoryDesignConfig.spacingL,
            horizontal: InventoryDesignConfig.spacingM,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color: backgroundColor == InventoryDesignConfig.surfaceLight
                  ? InventoryDesignConfig.borderPrimary
                  : backgroundColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: InventoryDesignConfig.spacingS),
              ],
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
