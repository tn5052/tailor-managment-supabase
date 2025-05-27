import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/searchable_addable_dropdown.dart';
import 'fabric_color_picker.dart';

class AddInventoryMobileSheet extends StatefulWidget {
  final String inventoryType;
  final VoidCallback? onItemAdded;

  const AddInventoryMobileSheet({
    super.key,
    required this.inventoryType,
    this.onItemAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required String inventoryType,
    VoidCallback? onItemAdded,
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
            child: AddInventoryMobileSheet(
              inventoryType: inventoryType,
              onItemAdded: onItemAdded,
            ),
          ),
    );
  }

  @override
  State<AddInventoryMobileSheet> createState() =>
      _AddInventoryMobileSheetState();
}

class _AddInventoryMobileSheetState extends State<AddInventoryMobileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Essential controllers
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedUnitType = 'meter'; // Default to meter
  Color _selectedColor = Colors.white;
  String _colorName = '';
  String _colorHex = '#FFFFFF';

  SearchableAddableDropdownItem? _selectedBrand;
  SearchableAddableDropdownItem? _selectedCategory;

  final List<String> _fabricUnits = ['meter', 'gaz', 'yard', 'piece'];
  final List<String> _accessoryUnits = ['piece', 'dozen', 'box'];

  @override
  void initState() {
    super.initState();
    _selectedUnitType = widget.inventoryType == 'fabric' ? 'meter' : 'piece';
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

  // Method to show the color picker
  Future<void> _showColorPicker() async {
    final result = await FabricColorPicker.show(
      context,
      initialColor: _selectedColor,
      initialColorName: _colorName,
    );

    if (result != null) {
      setState(() {
        _selectedColor = result.color;
        _colorName = result.colorName;
        _colorHex = result.hexCode;
        _colorController.text = _colorName;
      });
    }
  }

  // Update the color field in your build method
  Widget _buildColorField(bool isFabric) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If not fabric, don't build this field.
    if (!isFabric) {
      return const SizedBox.shrink();
    }

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
                'Fabric Color', // Label is specific to fabric
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(color: colorScheme.error),
              ), // Required for fabric
            ],
          ),
        ),
        InkWell(
          onTap: _showColorPicker,
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
                      if (_colorHex.isNotEmpty)
                        Text(
                          _colorHex,
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
        if (_colorName.trim().isEmpty) // Validator for fabric color
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
      backgroundColor: Colors.transparent, // Make sheet background transparent
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6, // Start at 60% of screen height
            minChildSize: 0.3, // Min at 30%
            maxChildSize: 0.8, // Max at 80%
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

  Future<List<SearchableAddableDropdownItem>> _fetchBrands(
    String? searchText,
  ) async {
    var query = _supabase
        .from('brands')
        .select('id, name')
        .eq('brand_type', widget.inventoryType); // Filter by inventory type
    if (searchText != null && searchText.isNotEmpty) {
      query = query.ilike('name', '%$searchText%');
    }
    final response = await query;
    return response
        .map((e) => SearchableAddableDropdownItem(id: e['id'], name: e['name']))
        .toList();
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

  Future<List<SearchableAddableDropdownItem>> _fetchCategories(
    String? searchText,
  ) async {
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

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save(); // Important for FormField

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

      Map<String, dynamic> data = {
        'is_active': true,
        'tenant_id': _supabase.auth.currentUser?.id,
        'category_id': _selectedCategory!.id,
        'brand_id': _selectedBrand?.id,
      };

      if (widget.inventoryType == 'fabric') {
        data.addAll({
          'fabric_code': _codeController.text.trim(),
          'fabric_item_name': _nameController.text.trim(),
          'shade_color': _colorName.trim(),
          'color_code': _colorHex.trim(),
          'unit_type': _selectedUnitType,
          'quantity_available': double.tryParse(_quantityController.text) ?? 0,
          'cost_per_unit': double.tryParse(_costController.text) ?? 0,
          'selling_price_per_unit': double.tryParse(_priceController.text) ?? 0,
        });
      } else {
        // Accessory
        data.addAll({
          'accessory_code': _codeController.text.trim(),
          'accessory_item_name': _nameController.text.trim(),
          'color': _colorName.trim().isEmpty ? null : _colorName.trim(),
          'color_code': _colorHex.trim().isEmpty ? null : _colorHex.trim(),
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
                    'Add New $titleName',
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
                    _buildColorField(isFabric), // Pass isFabric
                    const SizedBox(height: 24), // Adjusted spacing
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
                          // Remove prefixText: 'AED ',
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
                          // Remove prefixText: 'AED ',
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

          // Save button
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
                onPressed: _isLoading ? null : _saveItem,
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
                label: Text(_isLoading ? 'Saving...' : 'Save $titleName'),
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
        if (required && (value == null || value.trim().isEmpty))
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
