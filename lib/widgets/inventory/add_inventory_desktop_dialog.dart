import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/searchable_addable_dropdown.dart';
import '../inventory/fabric_color_picker.dart';

class AddInventoryDesktopDialog extends StatefulWidget {
  final String inventoryType; // 'fabric' or 'accessory'
  final VoidCallback? onItemAdded;

  const AddInventoryDesktopDialog({
    super.key,
    required this.inventoryType,
    this.onItemAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required String inventoryType,
    VoidCallback? onItemAdded,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AddInventoryDesktopDialog(
            inventoryType: inventoryType,
            onItemAdded: onItemAdded,
          ),
    );
  }

  @override
  State<AddInventoryDesktopDialog> createState() =>
      _AddInventoryDesktopDialogState();
}

class _AddInventoryDesktopDialogState extends State<AddInventoryDesktopDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Essential controllers
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  // final _brandController = TextEditingController(); // REMOVE
  // final _typeController = TextEditingController(); // REMOVE
  final _colorController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedUnitType = 'meter'; // Default to meter
  Color _selectedColor = Colors.grey;
  String _colorName = '';
  String _hexColor = '';

  SearchableAddableDropdownItem? _selectedBrand;
  SearchableAddableDropdownItem? _selectedCategory;

  final List<String> _fabricUnits = ['meter', 'gaz', 'yard', 'piece'];
  final List<String> _accessoryUnits = ['piece', 'dozen', 'box'];

  @override
  void initState() {
    super.initState();
    _selectedUnitType = widget.inventoryType == 'fabric' ? 'meter' : 'piece';
    // Fetch initial brands and categories if needed, or let the dropdown handle it
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    // _brandController.dispose();
    // _typeController.dispose();
    _colorController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<SearchableAddableDropdownItem?> _addBrand(String brandName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await _supabase
              .from('brands')
              .insert({
                'name': brandName,
                'brand_type': widget.inventoryType, // Set brand type
                'tenant_id': userId,
              })
              .select('id, name')
              .single();

      return SearchableAddableDropdownItem(
        id: response['id'],
        name: response['name'],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding brand: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<SearchableAddableDropdownItem?> _addCategory(
    String categoryName,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await _supabase
              .from('inventory_categories')
              .insert({
                'category_name': categoryName,
                'category_type': widget.inventoryType,
                'tenant_id': userId,
              })
              .select('id, category_name')
              .single();

      return SearchableAddableDropdownItem(
        id: response['id'],
        name: response['category_name'],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding category: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<List<SearchableAddableDropdownItem>> _fetchBrands(
    String? searchText,
  ) async {
    try {
      var query = _supabase
          .from('brands')
          .select('id, name')
          .eq('brand_type', widget.inventoryType); // Filter by inventory type
      if (searchText != null && searchText.isNotEmpty) {
        query = query.ilike('name', '%$searchText%');
      }
      final response = await query;
      return response
          .map(
            (e) => SearchableAddableDropdownItem(id: e['id'], name: e['name']),
          )
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching brands: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  Future<List<SearchableAddableDropdownItem>> _fetchCategories(
    String? searchText,
  ) async {
    try {
      var query = _supabase
          .from('inventory_categories')
          .select('id, category_name')
          .eq('category_type', widget.inventoryType);

      if (searchText != null && searchText.isNotEmpty) {
        query = query.ilike('category_name', '%$searchText%');
      }
      final response = await query;
      return response
          .map(
            (e) => SearchableAddableDropdownItem(
              id: e['id'],
              name: e['category_name'],
            ),
          )
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching categories: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a ${widget.inventoryType} type/category.',
          ),
        ),
      );
      return;
    }

    // Brand is required only for fabric
    if (widget.inventoryType == 'fabric' && _selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a brand for the fabric.')),
      );
      return;
    }

    // Color is required only for fabric
    if (widget.inventoryType == 'fabric' && _colorName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fabric color is required.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final table =
          widget.inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> data = {
        'is_active': true,
        'tenant_id': userId,
        'category_id': _selectedCategory!.id,
        // brand_id is nullable, so it's fine if _selectedBrand is null for accessories
        'brand_id': _selectedBrand?.id,
      };

      if (widget.inventoryType == 'fabric') {
        data.addAll({
          'fabric_code': _codeController.text.trim(),
          'fabric_item_name': _nameController.text.trim(),
          'shade_color': _colorName.trim(), // Ensure color name is saved
          'color_code': _hexColor.trim(), // Ensure hex code is saved
          'unit_type': _selectedUnitType,
          'quantity_available': double.tryParse(_quantityController.text) ?? 0,
          'cost_per_unit': double.tryParse(_costController.text) ?? 0,
          'selling_price_per_unit': double.tryParse(_priceController.text) ?? 0,
        });
      } else {
        data.addAll({
          'accessory_code': _codeController.text.trim(),
          'accessory_item_name': _nameController.text.trim(),
          // For accessories, color is optional and might not be set
          // The database schema for accessories_inventory has 'color' and 'color_code' as nullable
          'color': _colorName.trim().isEmpty ? null : _colorName.trim(),
          'color_code': _hexColor.trim().isEmpty ? null : _hexColor.trim(),
          'unit_type': _selectedUnitType,
          'quantity_available': int.tryParse(_quantityController.text) ?? 0,
          'cost_per_unit': double.tryParse(_costController.text) ?? 0,
          'selling_price_per_unit': double.tryParse(_priceController.text) ?? 0,
        });
      }

      await _supabase.from(table).insert(data);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.inventoryType == 'fabric' ? 'Fabric' : 'Accessory'} added successfully!',
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onItemAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFabricColorPicker() async {
    final result = await FabricColorPicker.show(
      context,
      initialColor: _selectedColor,
      initialColorName: _colorName,
    );

    if (result != null) {
      setState(() {
        _selectedColor = result.color;
        _colorName = result.colorName;
        _hexColor = result.hexCode;
        _colorController.text = result.colorName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFabric = widget.inventoryType == 'fabric';
    final titleName = isFabric ? 'Fabric' : 'Accessory';
    final titleIcon =
        isFabric
            ? PhosphorIcons.scissors(PhosphorIconsStyle.fill)
            : PhosphorIcons.package(PhosphorIconsStyle.fill);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(titleIcon, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add New $titleName',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
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

            // Form content
            Form(
              key: _formKey,
              child: Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item details section
                      Text(
                        'Item Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name and code in a row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildSimpleField(
                              controller: _nameController,
                              label: '$titleName Name',
                              hintText: 'Enter name',
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSimpleField(
                              controller: _codeController,
                              label: 'Item Code',
                              hintText: 'Enter code',
                              required: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Type and Brand in a row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SearchableAddableDropdownFormField(
                              labelText: '$titleName Type',
                              hintText: 'Select your type',
                              fetchItems: _fetchCategories,
                              onAddItem: _addCategory,
                              onChanged:
                                  (value) =>
                                      setState(() => _selectedCategory = value),
                              initialValue: _selectedCategory,
                              validator:
                                  (value) =>
                                      value == null ? 'Type is required' : null,
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SearchableAddableDropdownFormField(
                              labelText: 'Brand',
                              hintText: 'Select your brand',
                              fetchItems: _fetchBrands,
                              onAddItem: _addBrand,
                              onChanged:
                                  (value) =>
                                      setState(() => _selectedBrand = value),
                              initialValue: _selectedBrand,
                              validator: (value) {
                                if (isFabric && value == null)
                                  return 'Brand is required for fabric';
                                return null;
                              },
                              required: isFabric,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Color field - only show for fabric
                      if (isFabric) ...[
                        _buildColorField(isFabric), // Pass isFabric here
                        const SizedBox(height: 24), // Keep spacing consistent
                      ],

                      // Stock & Pricing section
                      Text(
                        'Stock & Pricing',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Use a grid-like layout for better alignment
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Quantity and Cost
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSimpleField(
                                  controller: _quantityController,
                                  label: 'Quantity',
                                  hintText: 'Enter quantity',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  required: true,
                                ),
                                const SizedBox(height: 16),
                                _buildSimpleField(
                                  controller: _costController,
                                  label: 'Cost per Unit',
                                  hintText: 'Enter cost',
                                  // Remove prefixText: 'AED ',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  required: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right column - Unit and Selling Price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSimpleDropdown(
                                  value: _selectedUnitType,
                                  onChanged:
                                      (value) => setState(
                                        () => _selectedUnitType = value!,
                                      ),
                                  label: 'Unit',
                                  items:
                                      isFabric ? _fabricUnits : _accessoryUnits,
                                  hintText: 'Select your unit',
                                ),
                                const SizedBox(height: 16),
                                _buildSimpleField(
                                  controller: _priceController,
                                  label: 'Selling Price per Unit',
                                  hintText: 'Enter price',
                                  // Remove prefixText: 'AED ',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  required: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _saveItem,
                    icon:
                        _isLoading
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                            : Icon(PhosphorIcons.checkCircle()),
                    label: Text(_isLoading ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? prefixText,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator:
              required
                  ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  }
                  : null,
        ),
      ],
    );
  }

  Widget _buildSimpleDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    required String label,
    required List<String> items,
    required String hintText,
    bool required = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap:
              () => _showDropdownDialog(
                context: context,
                items: items,
                selectedValue: value,
                onChanged: onChanged,
                title: label,
              ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? hintText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        value != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                Icon(
                  PhosphorIcons.caretDown(),
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (required && (value == null || value.trim().isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 0),
            child: Text(
              'This field is required',
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _showDropdownDialog({
    required BuildContext context,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    required String title,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Container(
              width: 320, // Adjusted width
              constraints: const BoxConstraints(
                maxHeight: 450,
              ), // Max height for scrollability
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select $title',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            PhosphorIcons.x(),
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                  Flexible(
                    // Ensures the ListView takes available space and scrolls
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder:
                          (context, index) => Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: colorScheme.outline.withOpacity(0.1),
                          ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item == selectedValue;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              onChanged(item);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(
                              0,
                            ), // For rectangular ink splash
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color:
                                                isSelected
                                                    ? colorScheme.primary
                                                    : colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  if (isSelected)
                                    PhosphorIcon(
                                      PhosphorIcons.checkCircle(
                                        PhosphorIconsStyle.fill,
                                      ),
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildColorField(bool isFabric) {
    // Added isFabric parameter
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If not fabric, don't build this field at all.
    // This check is now redundant due to the conditional rendering in the parent build method,
    // but kept for clarity if this widget were to be used elsewhere without that parent check.
    if (!isFabric) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fabric Color *', // Label clearly indicates it's for fabric and required
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showFabricColorPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Color preview
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _colorName.isEmpty ? 'Select fabric color' : _colorName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              _colorName.isEmpty
                                  ? colorScheme.onSurfaceVariant.withOpacity(
                                    0.6,
                                  )
                                  : colorScheme.onSurface,
                          fontWeight:
                              _colorName.isEmpty ? null : FontWeight.w500,
                        ),
                      ),
                      if (_hexColor.isNotEmpty)
                        Text(
                          _hexColor,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
                PhosphorIcon(
                  PhosphorIcons.caretDown(),
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (isFabric && _colorName.trim().isEmpty) // Validator for fabric color
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Fabric color is required.', // Clearer message
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
