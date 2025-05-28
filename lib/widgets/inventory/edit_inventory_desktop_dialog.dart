import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/searchable_addable_dropdown.dart';
import 'fabric_color_picker.dart';

class EditInventoryDesktopDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final String inventoryType;
  final VoidCallback? onItemUpdated;

  const EditInventoryDesktopDialog({
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
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => EditInventoryDesktopDialog(
            item: item,
            inventoryType: inventoryType,
            onItemUpdated: onItemUpdated,
          ),
    );
  }

  @override
  State<EditInventoryDesktopDialog> createState() =>
      _EditInventoryDesktopDialogState();
}

class _EditInventoryDesktopDialogState
    extends State<EditInventoryDesktopDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Controllers
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedUnitType = 'meter';
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
    _initializeFields();
  }

  void _initializeFields() {
    final isFabric = widget.inventoryType == 'fabric';

    // Initialize basic fields
    _codeController.text =
        widget.item[isFabric ? 'fabric_code' : 'accessory_code'] ?? '';
    _nameController.text =
        widget.item[isFabric ? 'fabric_item_name' : 'accessory_item_name'] ??
        '';
    _quantityController.text =
        (widget.item['quantity_available'] ?? 0).toString();
    _costController.text = (widget.item['cost_per_unit'] ?? 0).toString();
    _priceController.text =
        (widget.item['selling_price_per_unit'] ?? 0).toString();
    _selectedUnitType =
        widget.item['unit_type'] ?? (isFabric ? 'meter' : 'piece');

    // Initialize color fields
    if (isFabric) {
      _colorName = widget.item['shade_color'] ?? '';
      _hexColor = widget.item['color_code'] ?? '';
      _colorController.text = _colorName;
      if (_hexColor.isNotEmpty) {
        _selectedColor = _parseColor(_hexColor);
      }
    } else {
      _colorName = widget.item['color'] ?? '';
      _hexColor = widget.item['color_code'] ?? '';
      _colorController.text = _colorName;
      if (_hexColor.isNotEmpty) {
        _selectedColor = _parseColor(_hexColor);
      }
    }

    // Initialize brand
    if (widget.item['brand_id'] != null && widget.item['brand_name'] != null) {
      _selectedBrand = SearchableAddableDropdownItem(
        id: widget.item['brand_id'],
        name: widget.item['brand_name'],
      );
    }

    // Initialize category
    if (widget.item['category_id'] != null) {
      final categoryName =
          widget.item[isFabric ? 'fabric_type' : 'accessory_type'];
      if (categoryName != null) {
        _selectedCategory = SearchableAddableDropdownItem(
          id: widget.item['category_id'],
          name: categoryName,
        );
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _colorController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorCode) {
    if (colorCode.isEmpty) return Colors.grey;
    try {
      if (colorCode.startsWith('#')) {
        String hexCode = colorCode.substring(1);
        if (hexCode.length == 6) {
          return Color(int.parse('FF$hexCode', radix: 16));
        }
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  Future<List<SearchableAddableDropdownItem>> _fetchBrands(
    String? searchText,
  ) async {
    try {
      var query = _supabase
          .from('brands')
          .select('id, name')
          .eq('brand_type', widget.inventoryType);
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
          SnackBar(content: Text('Error fetching brands: ${e.toString()}')),
        );
      }
      return [];
    }
  }

  Future<SearchableAddableDropdownItem?> _addBrand(String brandName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response =
          await _supabase
              .from('brands')
              .insert({
                'name': brandName,
                'brand_type': widget.inventoryType,
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
          SnackBar(content: Text('Error adding brand: ${e.toString()}')),
        );
      }
      return null;
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
          SnackBar(content: Text('Error fetching categories: ${e.toString()}')),
        );
      }
      return [];
    }
  }

  Future<SearchableAddableDropdownItem?> _addCategory(
    String categoryName,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

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
          SnackBar(content: Text('Error adding category: ${e.toString()}')),
        );
      }
      return null;
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

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;
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

    if (widget.inventoryType == 'fabric' && _selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a brand for the fabric.')),
      );
      return;
    }

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

      Map<String, dynamic> data = {
        'category_id': _selectedCategory!.id,
        'brand_id': _selectedBrand?.id,
        'unit_type': _selectedUnitType,
        'quantity_available':
            widget.inventoryType == 'fabric'
                ? double.tryParse(_quantityController.text) ?? 0
                : int.tryParse(_quantityController.text) ?? 0,
        'cost_per_unit': double.tryParse(_costController.text) ?? 0,
        'selling_price_per_unit': double.tryParse(_priceController.text) ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.inventoryType == 'fabric') {
        data.addAll({
          'fabric_code': _codeController.text.trim(),
          'fabric_item_name': _nameController.text.trim(),
          'shade_color': _colorName.trim(),
          'color_code': _hexColor.trim(),
        });
      } else {
        data.addAll({
          'accessory_code': _codeController.text.trim(),
          'accessory_item_name': _nameController.text.trim(),
          'color': _colorName.trim().isEmpty ? null : _colorName.trim(),
          'color_code': _hexColor.trim().isEmpty ? null : _hexColor.trim(),
        });
      }

      await _supabase.from(table).update(data).eq('id', widget.item['id']);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.inventoryType == 'fabric' ? 'Fabric' : 'Accessory'} updated successfully!',
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onItemUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: ${e.toString()}'),
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
        padding: EdgeInsets.zero,
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
                      'Edit $titleName',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
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
                        _buildColorField(isFabric),
                        const SizedBox(height: 24),
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

                      // Quantity and Unit row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildSimpleField(
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
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSimpleDropdown(
                              value: _selectedUnitType,
                              onChanged:
                                  (value) => setState(
                                    () => _selectedUnitType = value!,
                                  ),
                              label: 'Unit',
                              items: isFabric ? _fabricUnits : _accessoryUnits,
                              hintText: 'Select your unit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cost and Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildSimpleField(
                              controller: _costController,
                              label: 'Cost per Unit',
                              hintText: 'Enter cost',
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
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSimpleField(
                              controller: _priceController,
                              label: 'Selling Price per Unit',
                              hintText: 'Enter price',
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
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _updateItem,
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
                    label: Text(_isLoading ? 'Updating...' : 'Update'),
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
          enabled: !_isLoading,
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
        DropdownButtonFormField<String>(
          value: value,
          onChanged: _isLoading ? null : onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items:
              items.map((item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorField(bool isFabric) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isFabric) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fabric Color *',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isLoading ? null : _showFabricColorPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
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
        if (isFabric && _colorName.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Fabric color is required.',
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
