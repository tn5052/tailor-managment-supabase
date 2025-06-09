import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fabric_color_picker.dart';
import 'brand_selector_dialog.dart';
import 'category_selector_dialog.dart';
import 'inventory_design_config.dart';

class AddInventoryDesktopDialog extends StatefulWidget {
  final String inventoryType;
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
    return showDialog<void>(
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

  // Controllers
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

  String? _selectedBrandName;
  String? _selectedCategoryName;

  final List<String> _unitTypes = [
    'Meter',
    'Yard',
    'Piece',
    'Kg',
    'Gram',
    'Set',
  ];

  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _itemNameController = TextEditingController();
    _itemCodeController = TextEditingController();
    _colorController = TextEditingController();
    _colorCodeController = TextEditingController();
    _quantityController = TextEditingController();
    _minStockController = TextEditingController();
    _costController = TextEditingController();
    _priceController = TextEditingController();
    _notesController = TextEditingController();
  }

  Future<void> _openColorPicker() async {
    final result = await FabricColorPicker.show(
      context,
      initialColor: _selectedColor,
      initialColorName: _colorController.text,
    );

    if (result != null) {
      setState(() {
        _selectedColor = result.color;
        _colorController.text = result.colorName;
        _colorCodeController.text = result.hexCode;
      });
    }
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

  Future<void> _addItem() async {
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
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(table).insert(data);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onItemAdded?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.inventoryType == 'fabric' ? 'Fabric' : 'Accessory'} added successfully',
            ),
            backgroundColor: InventoryDesignConfig.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openBrandSelector() async {
    await BrandSelectorDialog.show(
      context,
      selectedBrandId: _selectedBrand,
      onBrandSelected: (brandId, brandName) {
        setState(() {
          _selectedBrand = brandId;
          _selectedBrandName = brandName;
        });
      },
    );
  }

  Future<void> _openCategorySelector() async {
    await CategorySelectorDialog.show(
      context,
      inventoryType: widget.inventoryType,
      selectedCategoryId: _selectedCategory,
      onCategorySelected: (categoryId, categoryName) {
        setState(() {
          _selectedCategory = categoryId;
          _selectedCategoryName = categoryName;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.9;
    final isFabric = widget.inventoryType == 'fabric';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 700, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isFabric),
              Flexible(child: _buildContent(isFabric)),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isFabric) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXXL,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
            ),
            child: Icon(
              PhosphorIcons.plus(),
              size: 18,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New ${isFabric ? 'Fabric' : 'Accessory'}',
                  style: InventoryDesignConfig.headlineMedium,
                ),
                Text(
                  'Create a new inventory item',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                child: Icon(
                  PhosphorIcons.x(),
                  size: 18,
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isFabric) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            _buildSection('Basic Information', PhosphorIcons.info(), [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
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
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingL),
                  Expanded(
                    child: _buildTextField(
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
                  ),
                ],
              ),
              const SizedBox(height: InventoryDesignConfig.spacingL),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectorField(
                      label: 'Brand',
                      hint: 'Select brand',
                      icon: PhosphorIcons.tag(),
                      value: _selectedBrandName,
                      onTap: _openBrandSelector,
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingL),
                  Expanded(
                    child: _buildSelectorField(
                      label: 'Category',
                      hint: 'Select category',
                      icon: PhosphorIcons.folder(),
                      value: _selectedCategoryName,
                      onTap: _openCategorySelector,
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: InventoryDesignConfig.spacingXXL),

            // Color Information Section
            _buildSection('Color Information', PhosphorIcons.palette(), [
              Row(
                children: [
                  Expanded(
                    child: _buildColorTextField(
                      controller: _colorController,
                      label: isFabric ? 'Shade Color' : 'Color',
                      hint: 'Tap to choose color',
                      icon: PhosphorIcons.eyedropper(),
                      selectedColor: _selectedColor,
                      onColorTap: _openColorPicker,
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingL),
                  Expanded(
                    child: _buildTextField(
                      controller: _colorCodeController,
                      label: 'Color Code',
                      hint: '#FFFFFF or color name',
                      icon: PhosphorIcons.hash(),
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: InventoryDesignConfig.spacingXXL),

            // Inventory Details Section
            _buildSection('Inventory Details', PhosphorIcons.package(), [
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
                  const SizedBox(width: InventoryDesignConfig.spacingL),
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
                  const SizedBox(width: InventoryDesignConfig.spacingL),
                  Expanded(
                    child: _buildDropdown<String>(
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
                          (value) => setState(() => _selectedUnitType = value),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select unit type';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: InventoryDesignConfig.spacingXXL),

            // Pricing Information Section
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
                    const SizedBox(width: InventoryDesignConfig.spacingL),
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

            const SizedBox(height: InventoryDesignConfig.spacingXXL),

            // Additional Notes Section
            _buildSection('Additional Notes', PhosphorIcons.notepad(), [
              _buildTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Any additional information...',
                icon: PhosphorIcons.note(),
                maxLines: 3,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 72,
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _isLoading ? null : () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXXL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: InventoryDesignConfig.buttonSecondaryDecoration,
                child: Text(
                  'Cancel',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _isLoading ? null : _addItem,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXXL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: InventoryDesignConfig.buttonPrimaryDecoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(PhosphorIcons.plus(), size: 16, color: Colors.white),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      _isLoading ? 'Adding...' : 'Add Item',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
              ),
              border: Border(
                bottom: BorderSide(
                  color: InventoryDesignConfig.borderSecondary,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  title,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: InventoryDesignConfig.textSecondary,
            ),
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical:
                  maxLines > 1
                      ? InventoryDesignConfig.spacingL
                      : InventoryDesignConfig.spacingM,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        DropdownButtonFormField<T>(
          value: value,
          validator: validator,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
          ),
          dropdownColor: InventoryDesignConfig.surfaceColor,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: InventoryDesignConfig.textSecondary,
            ),
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical: InventoryDesignConfig.spacingM,
            ),
          ),
          items:
              items.map((item) {
                return DropdownMenuItem<T>(
                  value: item.value,
                  child: Text(
                    item.child is Text
                        ? (item.child as Text).data ?? ''
                        : item.value.toString(),
                    style: InventoryDesignConfig.bodyLarge,
                  ),
                );
              }).toList(),
          onChanged: onChanged,
          icon: Icon(
            PhosphorIcons.caretDown(),
            size: 16,
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildColorTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Color? selectedColor,
    VoidCallback? onColorTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onColorTap,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: GestureDetector(
              onTap: onColorTap,
              child: Container(
                margin: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selectedColor ?? InventoryDesignConfig.surfaceAccent,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                  border: Border.all(
                    color: InventoryDesignConfig.borderPrimary,
                    width: 1.5,
                  ),
                ),
                child:
                    selectedColor == null
                        ? Icon(
                          PhosphorIcons.palette(),
                          size: 12,
                          color: InventoryDesignConfig.textSecondary,
                        )
                        : null,
              ),
            ),
            suffixIcon: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
              child: InkWell(
                onTap: onColorTap,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusS,
                ),
                child: Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                  child: Icon(
                    PhosphorIcons.palette(),
                    size: 18,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ),
            ),
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical: InventoryDesignConfig.spacingM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: InventoryDesignConfig.spacingL,
                vertical:
                    InventoryDesignConfig.spacingM +
                    2, // Match text field height
              ),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingL),
                  Expanded(
                    child: Text(
                      value ?? hint,
                      style:
                          value != null
                              ? InventoryDesignConfig.bodyLarge.copyWith(
                                color: InventoryDesignConfig.textPrimary,
                              )
                              : InventoryDesignConfig.bodyMedium.copyWith(
                                color: InventoryDesignConfig.textTertiary,
                              ),
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretDown(),
                    size: 16,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
