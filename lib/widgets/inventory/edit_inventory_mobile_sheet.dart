import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/searchable_addable_dropdown.dart';
import 'fabric_color_picker.dart';

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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: EditInventoryMobileSheet(
              item: item,
              inventoryType: inventoryType,
              onItemUpdated: onItemUpdated,
            ),
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Icon(
                  isFabric
                      ? PhosphorIcons.scissors(PhosphorIconsStyle.fill)
                      : PhosphorIcons.package(PhosphorIconsStyle.fill),
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Edit $titleName',
                    style: theme.textTheme.titleLarge?.copyWith(
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
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withAlpha(50),
          ),

          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Basic info section
                  Text(
                    'Item Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name field
                  _buildSimpleField(
                    controller: _nameController,
                    label: '$titleName Name',
                    icon: PhosphorIcons.textAa(),
                    hintText: 'Enter name',
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  // Code field
                  _buildSimpleField(
                    controller: _codeController,
                    label: 'Item Code',
                    icon: PhosphorIcons.barcode(),
                    hintText: 'Enter code',
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  // Type field
                  SearchableAddableDropdownFormField(
                    labelText: '$titleName Type',
                    hintText: 'Select your type',
                    icon: PhosphorIcons.stack(),
                    fetchItems: _fetchCategories,
                    onAddItem: _addCategory,
                    onChanged:
                        (value) => setState(() => _selectedCategory = value),
                    initialValue: _selectedCategory,
                    validator: (value) => value == null ? 'Required' : null,
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  // Brand field
                  SearchableAddableDropdownFormField(
                    labelText: 'Brand',
                    hintText: 'Select your brand',
                    icon: PhosphorIcons.tag(),
                    fetchItems: _fetchBrands,
                    onAddItem: _addBrand,
                    onChanged:
                        (value) => setState(() => _selectedBrand = value),
                    initialValue: _selectedBrand,
                    validator: (value) {
                      if (isFabric && value == null)
                        return 'Required for fabric';
                      return null;
                    },
                    required: isFabric,
                  ),
                  const SizedBox(height: 16),

                  // Color field - only show for fabric
                  if (isFabric) ...[
                    _buildColorField(isFabric),
                    const SizedBox(height: 24),
                  ],

                  // Stock section
                  Text(
                    'Stock & Pricing',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // First row: Quantity and Unit
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quantity field
                      Expanded(
                        child: _buildSimpleField(
                          controller: _quantityController,
                          label: 'Quantity',
                          icon: PhosphorIcons.package(),
                          hintText: 'Enter quantity',
                          keyboardType: const TextInputType.numberWithOptions(
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
                      const SizedBox(width: 12),
                      // Unit dropdown
                      Expanded(
                        child: _buildSimpleDropdown(
                          value: _selectedUnitType,
                          onChanged:
                              (value) =>
                                  setState(() => _selectedUnitType = value!),
                          label: 'Unit',
                          icon: PhosphorIcons.ruler(),
                          items: isFabric ? _fabricUnits : _accessoryUnits,
                          hintText: 'Select your unit',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Second row: Cost and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cost field
                      Expanded(
                        child: _buildSimpleField(
                          controller: _costController,
                          label: 'Cost',
                          icon: PhosphorIcons.currencyDollar(),
                          hintText: 'Enter cost',
                          keyboardType: const TextInputType.numberWithOptions(
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
                      const SizedBox(width: 12),
                      // Price field
                      Expanded(
                        child: _buildSimpleField(
                          controller: _priceController,
                          label: 'Selling Price',
                          icon: PhosphorIcons.tag(),
                          hintText: 'Enter price',
                          keyboardType: const TextInputType.numberWithOptions(
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

          // Update button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _updateItem,
                icon:
                    _isLoading
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                        : Icon(PhosphorIcons.checkCircle()),
                label: Text(_isLoading ? 'Updating...' : 'Update $titleName'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: theme.textTheme.labelLarge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    String? prefixText,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2.0, bottom: 6.0),
          child: Row(
            children: [
              Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (required)
                Text(' *', style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
          validator:
              required
                  ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
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
    required IconData icon,
    required List<String> items,
    required String hintText,
    bool required = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2.0, bottom: 6.0),
          child: Row(
            children: [
              Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (required)
                Text(' *', style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
        GestureDetector(
          onTap:
              () => _showDropdownOptions(
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
      ],
    );
  }

  void _showDropdownOptions({
    required BuildContext context,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    required String title,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select $title',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              PhosphorIcons.x(),
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: items.length,
                        separatorBuilder:
                            (context, index) => Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w600
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
                                        size: 22,
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
              );
            },
          ),
    );
  }

  Widget _buildColorField(bool isFabric) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isFabric) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2.0, bottom: 6.0),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.palette(),
                size: 15,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Fabric Color',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(' *', style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
        InkWell(
          onTap: _showFabricColorPicker,
          borderRadius: BorderRadius.circular(8),
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
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withOpacity(0.3),
                        blurRadius: 3,
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
                Icon(
                  PhosphorIcons.drop(),
                  color: colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_colorName.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'Required',
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
