import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';

class EditInventoryMobileSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String inventoryType;
  final VoidCallback? onItemUpdated;

  const EditInventoryMobileSheet({
    super.key,
    required this.item,
    required this.inventoryType,
    this.onItemUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> item,
    required String inventoryType,
    VoidCallback? onItemUpdated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => EditInventoryMobileSheet(
            item: item,
            inventoryType: inventoryType,
            onItemUpdated: onItemUpdated,
          ),
    );
  }

  @override
  State<EditInventoryMobileSheet> createState() =>
      _EditInventoryMobileSheetState();
}

class _EditInventoryMobileSheetState extends State<EditInventoryMobileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Controllers with existing data
  late final TextEditingController _itemNameController;
  late final TextEditingController _itemCodeController;
  late final TextEditingController _colorController;
  late final TextEditingController _colorCodeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minStockController;
  late final TextEditingController _costController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;

  String? _selectedBrand;
  String? _selectedCategory;
  String? _selectedUnitType;

  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _categories = [];

  final List<String> _unitTypes = [
    'Meter',
    'Yard',
    'Piece',
    'Kg',
    'Gram',
    'Set',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadDropdownData();
  }

  void _initializeControllers() {
    final isFabric = widget.inventoryType == 'fabric';

    _itemNameController = TextEditingController(
      text:
          widget.item[isFabric ? 'fabric_item_name' : 'accessory_item_name'] ??
          '',
    );
    _itemCodeController = TextEditingController(
      text: widget.item[isFabric ? 'fabric_code' : 'accessory_code'] ?? '',
    );
    _colorController = TextEditingController(
      text: widget.item[isFabric ? 'shade_color' : 'color'] ?? '',
    );
    _colorCodeController = TextEditingController(
      text: widget.item['color_code'] ?? '',
    );
    _quantityController = TextEditingController(
      text: (widget.item['quantity_available'] ?? 0).toString(),
    );
    _minStockController = TextEditingController(
      text: (widget.item['minimum_stock_level'] ?? 0).toString(),
    );
    _costController = TextEditingController(
      text: (widget.item['cost_per_unit'] ?? 0.0).toString(),
    );
    _priceController = TextEditingController(
      text: (widget.item['selling_price_per_unit'] ?? 0.0).toString(),
    );
    _notesController = TextEditingController(text: widget.item['notes'] ?? '');

    _selectedBrand = widget.item['brand_id']?.toString();
    _selectedCategory = widget.item['category_id']?.toString();

    // Fix the unit type dropdown issue by validating the value
    final storedUnitType = widget.item['unit_type'];
    _selectedUnitType =
        _unitTypes.contains(storedUnitType) ? storedUnitType : null;
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemCodeController.dispose();
    _colorController.dispose();
    _colorCodeController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final brandsResponse = await _supabase
          .from('brands')
          .select('id, name')
          .eq('is_active', true)
          .order('name');

      final categoriesResponse = await _supabase
          .from('inventory_categories')
          .select('id, category_name')
          .eq('is_active', true)
          .order('category_name');

      setState(() {
        _brands = List<Map<String, dynamic>>.from(brandsResponse);
        _categories = List<Map<String, dynamic>>.from(categoriesResponse);
      });
    } catch (e) {
      // Handle error silently or show message
    }
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final table =
          widget.inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';

      final data = {
        if (widget.inventoryType == 'fabric') ...{
          'fabric_item_name': _itemNameController.text.trim(),
          'fabric_code': _itemCodeController.text.trim(),
          'shade_color': _colorController.text.trim(),
        } else ...{
          'accessory_item_name': _itemNameController.text.trim(),
          'accessory_code': _itemCodeController.text.trim(),
          'color': _colorController.text.trim(),
        },
        'color_code': _colorCodeController.text.trim(),
        'unit_type': _selectedUnitType,
        'quantity_available': int.parse(_quantityController.text),
        'minimum_stock_level': int.parse(_minStockController.text),
        'cost_per_unit': double.parse(_costController.text),
        'selling_price_per_unit': double.parse(_priceController.text),
        'notes':
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        'brand_id': _selectedBrand,
        'category_id': _selectedCategory,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(table).update(data).eq('id', widget.item['id']);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onItemUpdated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.inventoryType == 'fabric' ? 'Fabric' : 'Accessory'} updated successfully',
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isFabric = widget.inventoryType == 'fabric';

    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: theme.dividerColor.withAlpha(100),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.pencilSimple(),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Edit ${isFabric ? 'Fabric' : 'Accessory'}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(PhosphorIcons.x()),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    _buildSection('Basic Information', PhosphorIcons.info(), [
                      _buildTextField(
                        controller: _itemNameController,
                        label: '${isFabric ? 'Fabric' : 'Accessory'} Name',
                        hint: 'Enter item name',
                        icon: PhosphorIcons.textT(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _itemCodeController,
                        label: 'Item Code',
                        hint: 'SKU/Code',
                        icon: PhosphorIcons.barcode(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter item code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<String>(
                        value: _selectedBrand,
                        label: 'Brand',
                        hint: 'Select brand',
                        icon: PhosphorIcons.tag(),
                        items:
                            _brands
                                .map(
                                  (brand) => DropdownMenuItem<String>(
                                    value: brand['id'].toString(),
                                    child: Text(brand['name']),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(() => _selectedBrand = value),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<String>(
                        value: _selectedCategory,
                        label: 'Category',
                        hint: 'Select category',
                        icon: PhosphorIcons.folder(),
                        items:
                            _categories
                                .map(
                                  (category) => DropdownMenuItem<String>(
                                    value: category['id'].toString(),
                                    child: Text(category['category_name']),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) =>
                                setState(() => _selectedCategory = value),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Color Information
                    _buildSection(
                      'Color Information',
                      PhosphorIcons.palette(),
                      [
                        _buildTextField(
                          controller: _colorController,
                          label: isFabric ? 'Shade Color' : 'Color',
                          hint: 'Enter color name',
                          icon: PhosphorIcons.eyedropper(),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _colorCodeController,
                          label: 'Color Code',
                          hint: '#FFFFFF or color name',
                          icon: PhosphorIcons.hash(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Inventory Details
                    _buildSection(
                      'Inventory Details',
                      PhosphorIcons.package(),
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _quantityController,
                                label: 'Quantity Available',
                                hint: '0',
                                icon: PhosphorIcons.stack(),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter quantity';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _minStockController,
                                label: 'Minimum Stock Level',
                                hint: '0',
                                icon: PhosphorIcons.arrowsInLineVertical(),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter minimum stock';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown<String>(
                          value: _selectedUnitType,
                          label: 'Unit Type',
                          hint: 'Select unit',
                          icon: PhosphorIcons.ruler(),
                          items:
                              _unitTypes
                                  .map(
                                    (unit) => DropdownMenuItem<String>(
                                      value: unit,
                                      child: Text(unit),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) =>
                                  setState(() => _selectedUnitType = value),
                          validator: (value) {
                            if (value == null) {
                              return 'Please select unit type';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Pricing Information
                    _buildSection(
                      'Pricing Information',
                      PhosphorIcons.currencyDollar(),
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _costController,
                                label: 'Cost per Unit',
                                hint: '0.00',
                                icon: PhosphorIcons.arrowDown(),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter cost';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter valid amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _priceController,
                                label: 'Selling Price per Unit',
                                hint: '0.00',
                                icon: PhosphorIcons.arrowUp(),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter selling price';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter valid amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Additional Notes
                    _buildSection('Additional Notes', PhosphorIcons.notepad(), [
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notes (Optional)',
                        hint: 'Any additional information...',
                        icon: PhosphorIcons.note(),
                        maxLines: 3,
                      ),
                    ]),

                    const SizedBox(
                      height: 100,
                    ), // Extra space for floating buttons
                  ],
                ),
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _updateItem,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Update Item'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    final theme = Theme.of(context);

    // Ensure the value exists in the items list, otherwise set to null
    final validValue = items.any((item) => item.value == value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: validValue, // Use validated value
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
