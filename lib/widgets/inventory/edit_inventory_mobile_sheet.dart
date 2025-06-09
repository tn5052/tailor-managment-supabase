import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inventory_design_config.dart';

class EditInventoryMobileSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String inventoryType; // 'fabric' or 'accessory'
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
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
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

class _EditInventoryMobileSheetState extends State<EditInventoryMobileSheet>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _sheetAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _sheetAnimation;

  // Focus nodes for keyboard management
  final _sheetFocusNode = FocusNode();
  final _itemNameFocusNode = FocusNode();
  final _itemCodeFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  final _minimumStockFocusNode = FocusNode();
  final _costFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();

  // Form controllers
  late final TextEditingController _itemNameController;
  late final TextEditingController _itemCodeController;
  late final TextEditingController _colorController;
  late final TextEditingController _colorCodeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minimumStockController;
  late final TextEditingController _costController;
  late final TextEditingController _priceController;

  // Form state
  SearchableAddableDropdownItem? _selectedBrand;
  SearchableAddableDropdownItem? _selectedCategory;
  String _selectedUnitType = 'meter';
  bool _isSaving = false;

  // Keyboard state
  double _keyboardHeight = 0;
  bool _isKeyboardVisible = false;

  // Unit type options
  final List<String> _unitTypes = ['meter', 'yard', 'piece', 'kg', 'gram'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _setupKeyboardListener();
    _setupFormListeners();

    // Request focus for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sheetFocusNode.requestFocus();
      _startEntryAnimation();
    });
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
      text: widget.item['quantity_available']?.toString() ?? '0',
    );
    _minimumStockController = TextEditingController(
      text: widget.item['minimum_stock_level']?.toString() ?? '0',
    );
    _costController = TextEditingController(
      text: widget.item['cost_per_unit']?.toString() ?? '0.00',
    );
    _priceController = TextEditingController(
      text: widget.item['selling_price_per_unit']?.toString() ?? '0.00',
    );

    // Initialize selected values
    _selectedUnitType = widget.item['unit_type'] ?? 'meter';

    // Initialize brand if exists
    if (widget.item['brand_name'] != null) {
      _selectedBrand = SearchableAddableDropdownItem(
        id: widget.item['brand_id'] ?? '',
        name: widget.item['brand_name'],
      );
    }

    // Initialize category if exists
    final categoryName =
        widget.item[isFabric ? 'fabric_type' : 'accessory_type'];
    if (categoryName != null) {
      _selectedCategory = SearchableAddableDropdownItem(
        id: widget.item['category_id'] ?? '',
        name: categoryName,
      );
    }
  }

  void _initializeAnimations() {
    _sheetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sheetAnimation = CurvedAnimation(
      parent: _sheetAnimationController,
      curve: Curves.easeOutCubic,
    );
  }

  void _setupKeyboardListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mediaQuery = MediaQuery.of(context);
      final keyboardHeight = mediaQuery.viewInsets.bottom;

      if (keyboardHeight != _keyboardHeight) {
        setState(() {
          _keyboardHeight = keyboardHeight;
          _isKeyboardVisible = keyboardHeight > 0;
        });

        // Auto-scroll to focused field when keyboard appears
        if (_isKeyboardVisible) {
          _scrollToFocusedField();
        }
      }
    });
  }

  void _setupFormListeners() {
    // Auto-generate profit margin when cost/price changes
    _costController.addListener(_calculateProfitMargin);
    _priceController.addListener(_calculateProfitMargin);
  }

  void _calculateProfitMargin() {
    final cost = double.tryParse(_costController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    // Trigger rebuild to update profit margin indicator
    setState(() {});
  }

  void _scrollToFocusedField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startEntryAnimation() async {
    await _sheetAnimationController.forward();
    await _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _sheetAnimationController.dispose();
    _contentAnimationController.dispose();
    _scrollController.dispose();

    // Dispose focus nodes
    _sheetFocusNode.dispose();
    _itemNameFocusNode.dispose();
    _itemCodeFocusNode.dispose();
    _quantityFocusNode.dispose();
    _minimumStockFocusNode.dispose();
    _costFocusNode.dispose();
    _priceFocusNode.dispose();

    // Dispose controllers
    _itemNameController.dispose();
    _itemCodeController.dispose();
    _colorController.dispose();
    _colorCodeController.dispose();
    _quantityController.dispose();
    _minimumStockController.dispose();
    _costController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  Future<void> _handleClose() async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Animate out
    await _contentAnimationController.reverse();
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
    final safeAreaBottom = mediaQuery.padding.bottom;

    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(
            0.4 * _sheetAnimation.value,
          ),
          body: GestureDetector(
            onTap: _handleClose,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: screenHeight * 0.95,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (screenHeight * 0.95) * (1 - _sheetAnimation.value),
                    ),
                    child: _buildSheetContent(safeAreaBottom),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetContent(double safeAreaBottom) {
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
      child: Focus(
        focusNode: _sheetFocusNode,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildFormContent(safeAreaBottom)),
            _buildActionButtons(safeAreaBottom),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isFabric = widget.inventoryType == 'fabric';

    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(
              top: InventoryDesignConfig.spacingM,
              bottom: InventoryDesignConfig.spacingS,
            ),
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
              InventoryDesignConfig.spacingL,
              InventoryDesignConfig.spacingL,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                  ),
                  child: Icon(
                    PhosphorIcons.pencilSimple(),
                    size: 20,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit ${isFabric ? 'Fabric' : 'Accessory'}',
                        style: InventoryDesignConfig.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Update item details',
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHeaderActionButton(
                  icon: PhosphorIcons.x(),
                  onTap: _handleClose,
                  semanticLabel: 'Close',
                ),
              ],
            ),
          ),

          // Divider
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
              color: InventoryDesignConfig.surfaceLight,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
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

  Widget _buildFormContent(double safeAreaBottom) {
    return Form(
      key: _formKey,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: InventoryDesignConfig.spacingXL,
            right: InventoryDesignConfig.spacingXL,
            top: InventoryDesignConfig.spacingL,
            bottom: InventoryDesignConfig.spacingXL + _keyboardHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildFormSection(
                title: 'Basic Information',
                icon: PhosphorIcons.info(),
                children: [
                  _buildTextFormField(
                    label: 'Item Name',
                    controller: _itemNameController,
                    focusNode: _itemNameFocusNode,
                    nextFocusNode: _itemCodeFocusNode,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? 'Item name is required'
                                : null,
                    textInputAction: TextInputAction.next,
                    prefixIcon: PhosphorIcons.tag(),
                  ),

                  const SizedBox(height: InventoryDesignConfig.spacingL),

                  _buildTextFormField(
                    label: 'Item Code',
                    controller: _itemCodeController,
                    focusNode: _itemCodeFocusNode,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? 'Item code is required'
                                : null,
                    textInputAction: TextInputAction.done,
                    prefixIcon: PhosphorIcons.barcode(),
                  ),

                  const SizedBox(height: InventoryDesignConfig.spacingL),

                  _buildDropdownField(
                    label: 'Category',
                    value: _selectedCategory?.name,
                    onTap: () => _showCategoryPicker(),
                    validator:
                        _selectedCategory == null
                            ? 'Category is required'
                            : null,
                    prefixIcon: PhosphorIcons.folder(),
                  ),

                  const SizedBox(height: InventoryDesignConfig.spacingL),

                  _buildDropdownField(
                    label: 'Brand',
                    value: _selectedBrand?.name,
                    onTap: () => _showBrandPicker(),
                    validator:
                        widget.inventoryType == 'fabric' &&
                                _selectedBrand == null
                            ? 'Brand is required for fabrics'
                            : null,
                    prefixIcon: PhosphorIcons.certificate(),
                  ),
                ],
              ),

              const SizedBox(height: InventoryDesignConfig.spacingXXL),

              // Color Information Section
              _buildFormSection(
                title: 'Color Information',
                icon: PhosphorIcons.paintBrush(),
                children: [
                  _buildDropdownField(
                    label: 'Color',
                    value:
                        _colorController.text.isEmpty
                            ? null
                            : _colorController.text,
                    onTap: () => _showColorPicker(),
                    validator:
                        widget.inventoryType == 'fabric' &&
                                _colorController.text.isEmpty
                            ? 'Color is required for fabrics'
                            : null,
                    prefixIcon: PhosphorIcons.palette(),
                  ),
                ],
              ),

              const SizedBox(height: InventoryDesignConfig.spacingXXL),

              // Inventory Details Section
              _buildFormSection(
                title: 'Inventory Details',
                icon: PhosphorIcons.warehouse(),
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextFormField(
                          label: 'Quantity',
                          controller: _quantityController,
                          focusNode: _quantityFocusNode,
                          nextFocusNode: _minimumStockFocusNode,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Quantity is required';
                            final num? parsed = num.tryParse(value!);
                            if (parsed == null || parsed < 0)
                              return 'Enter valid quantity';
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          prefixIcon: PhosphorIcons.package(),
                        ),
                      ),

                      const SizedBox(width: InventoryDesignConfig.spacingM),

                      Expanded(child: _buildUnitTypeDropdown()),
                    ],
                  ),

                  const SizedBox(height: InventoryDesignConfig.spacingL),

                  _buildTextFormField(
                    label: 'Minimum Stock Level',
                    controller: _minimumStockController,
                    focusNode: _minimumStockFocusNode,
                    nextFocusNode: _costFocusNode,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Minimum stock is required';
                      final num? parsed = num.tryParse(value!);
                      if (parsed == null || parsed < 0)
                        return 'Enter valid minimum stock';
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    prefixIcon: PhosphorIcons.warning(),
                  ),
                ],
              ),

              const SizedBox(height: InventoryDesignConfig.spacingXXL),

              // Pricing Information Section
              _buildFormSection(
                title: 'Pricing Information',
                icon: PhosphorIcons.currencyDollar(),
                children: [
                  _buildTextFormField(
                    label: 'Cost per Unit',
                    controller: _costController,
                    focusNode: _costFocusNode,
                    nextFocusNode: _priceFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Cost is required';
                      final num? parsed = num.tryParse(value!);
                      if (parsed == null || parsed < 0)
                        return 'Enter valid cost';
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    prefixIcon: PhosphorIcons.coins(),
                    prefixText: '\$ ',
                  ),

                  const SizedBox(height: InventoryDesignConfig.spacingL),

                  _buildTextFormField(
                    label: 'Selling Price per Unit',
                    controller: _priceController,
                    focusNode: _priceFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Price is required';
                      final num? parsed = num.tryParse(value!);
                      if (parsed == null || parsed < 0)
                        return 'Enter valid price';
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    prefixIcon: PhosphorIcons.tag(),
                    prefixText: '\$ ',
                  ),

                  const SizedBox(height: InventoryDesignConfig.spacingL),

                  _buildProfitMarginIndicator(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              style: InventoryDesignConfig.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        ...children,
      ],
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    IconData? prefixIcon,
    String? prefixText,
    String? helperText,
  }) {
    return Semantics(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: InventoryDesignConfig.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: InventoryDesignConfig.textPrimary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            style: InventoryDesignConfig.bodyLarge.copyWith(
              color: InventoryDesignConfig.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textTertiary,
              ),
              prefixIcon:
                  prefixIcon != null
                      ? Padding(
                        padding: const EdgeInsets.all(
                          InventoryDesignConfig.spacingM,
                        ),
                        child: Icon(
                          prefixIcon,
                          size: 18,
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      )
                      : null,
              prefixText: prefixText,
              prefixStyle: InventoryDesignConfig.bodyLarge.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
              helperText: helperText,
              helperStyle: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.textTertiary,
              ),
              filled: true,
              fillColor: InventoryDesignConfig.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                borderSide: BorderSide(
                  color: InventoryDesignConfig.borderPrimary,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                borderSide: BorderSide(
                  color: InventoryDesignConfig.borderPrimary,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                borderSide: BorderSide(
                  color: InventoryDesignConfig.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                borderSide: BorderSide(
                  color: InventoryDesignConfig.errorColor,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.all(
                InventoryDesignConfig.spacingL,
              ),
            ),
            onTapOutside: (_) {
              focusNode?.unfocus();
            },
            onFieldSubmitted:
                onFieldSubmitted ??
                (String value) {
                  if (textInputAction == TextInputAction.next) {
                    if (nextFocusNode != null) {
                      FocusScope.of(context).requestFocus(nextFocusNode);
                    } else {
                      focusNode?.unfocus();
                      FocusScope.of(context).unfocus();
                    }
                  } else if (textInputAction == TextInputAction.done) {
                    focusNode?.unfocus();
                    FocusScope.of(context).unfocus();
                  }
                },
            onEditingComplete: () {
              if (textInputAction == TextInputAction.done) {
                focusNode?.unfocus();
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    String? value,
    required VoidCallback onTap,
    String? validator,
    required IconData prefixIcon,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: InventoryDesignConfig.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: InventoryDesignConfig.textPrimary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceLight,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  border: Border.all(
                    color:
                        validator != null
                            ? InventoryDesignConfig.errorColor
                            : InventoryDesignConfig.borderPrimary,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      prefixIcon,
                      size: 18,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Expanded(
                      child: Text(
                        value ?? 'Select $label',
                        style: InventoryDesignConfig.bodyLarge.copyWith(
                          color:
                              value != null
                                  ? InventoryDesignConfig.textPrimary
                                  : InventoryDesignConfig.textTertiary,
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
          if (validator != null) ...[
            const SizedBox(height: InventoryDesignConfig.spacingXS),
            Text(
              validator,
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.errorColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unit',
          style: InventoryDesignConfig.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: InventoryDesignConfig.textPrimary,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showUnitTypePicker(),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                border: Border.all(
                  color: InventoryDesignConfig.borderPrimary,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.ruler(),
                    size: 18,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Expanded(
                    child: Text(
                      _selectedUnitType,
                      style: InventoryDesignConfig.bodyLarge.copyWith(
                        color: InventoryDesignConfig.textPrimary,
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

  Widget _buildProfitMarginIndicator() {
    final cost = double.tryParse(_costController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final profit = price - cost;
    final marginPercent = cost > 0 ? (profit / cost) * 100 : 0;

    Color profitColor;
    String healthText;

    if (marginPercent <= 0) {
      profitColor = InventoryDesignConfig.errorColor;
      healthText = 'Loss';
    } else if (marginPercent < 15) {
      profitColor = InventoryDesignConfig.warningColor;
      healthText = 'Low Margin';
    } else if (marginPercent < 30) {
      profitColor = InventoryDesignConfig.successColor;
      healthText = 'Good Margin';
    } else {
      profitColor = InventoryDesignConfig.successColor;
      healthText = 'Excellent Margin';
    }

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: profitColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: profitColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.trendUp(), size: 16, color: profitColor),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Profit Margin',
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: profitColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                healthText,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: profitColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${profit.toStringAsFixed(2)} profit',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  color: profitColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${marginPercent.toStringAsFixed(1)}%',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  color: profitColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double safeAreaBottom) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingL + safeAreaBottom,
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
      child: Row(
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
              label: 'Update Item',
              icon: PhosphorIcons.check(),
              color: InventoryDesignConfig.surfaceColor,
              backgroundColor: InventoryDesignConfig.primaryColor,
              onTap: _isSaving ? null : _handleSave,
              loading: _isSaving,
            ),
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
    bool loading = false,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: InventoryDesignConfig.spacingL,
              horizontal: InventoryDesignConfig.spacingM,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              border: Border.all(
                color:
                    backgroundColor == InventoryDesignConfig.surfaceLight
                        ? InventoryDesignConfig.borderPrimary
                        : backgroundColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ] else ...[
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Picker methods (same as add sheet)
  void _showCategoryPicker() {
    FocusScope.of(context).unfocus();
    _showSearchableAddableBottomSheet(
      title: 'Select Category',
      searchHint: 'Search categories...',
      fetchItems: _fetchCategories,
      addItem: _addCategory,
      onItemSelected: (item) {
        setState(() => _selectedCategory = item);
      },
    );
  }

  void _showBrandPicker() {
    FocusScope.of(context).unfocus();
    _showSearchableAddableBottomSheet(
      title: 'Select Brand',
      searchHint: 'Search brands...',
      fetchItems: _fetchBrands,
      addItem: _addBrand,
      onItemSelected: (item) {
        setState(() => _selectedBrand = item);
      },
    );
  }

  void _showColorPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder:
          (context) => _ColorPickerSheet(
            initialColor: _colorController.text,
            initialColorCode: _colorCodeController.text,
            onColorSelected: (colorName, colorCode) {
              setState(() {
                _colorController.text = colorName;
                _colorCodeController.text = colorCode;
              });
            },
          ),
    );
  }

  void _showUnitTypePicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _UnitTypePickerSheet(
            selectedUnit: _selectedUnitType,
            unitTypes: _unitTypes,
            onUnitSelected: (unit) {
              setState(() => _selectedUnitType = unit);
            },
          ),
    );
  }

  // Data methods (same as add sheet)
  Future<List<SearchableAddableDropdownItem>> _fetchBrands(
    String? searchText,
  ) async {
    var query = _supabase
        .from('brands')
        .select('id, name')
        .eq('is_active', true)
        .eq('tenant_id', _supabase.auth.currentUser?.id ?? '');

    if (searchText != null && searchText.isNotEmpty) {
      query = query.ilike('name', '%$searchText%');
    }

    final response = await query.order('name', ascending: true);
    return response
        .map((e) => SearchableAddableDropdownItem(id: e['id'], name: e['name']))
        .toList();
  }

  Future<SearchableAddableDropdownItem?> _addBrand(String brandName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response =
          await _supabase
              .from('brands')
              .insert({
                'name': brandName.trim(),
                'brand_type': 'general',
                'is_active': true,
                'tenant_id': userId,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select('id, name')
              .single();

      return SearchableAddableDropdownItem(
        id: response['id'],
        name: response['name'],
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error adding brand: ${e.toString()}');
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
        .eq('category_type', widget.inventoryType)
        .eq('is_active', true)
        .eq('tenant_id', _supabase.auth.currentUser?.id ?? '');

    if (searchText != null && searchText.isNotEmpty) {
      query = query.ilike('category_name', '%$searchText%');
    }

    final response = await query.order('category_name', ascending: true);
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
      if (userId == null) throw Exception('User not authenticated');

      final response =
          await _supabase
              .from('inventory_categories')
              .insert({
                'category_name': categoryName.trim(),
                'category_type': widget.inventoryType,
                'is_active': true,
                'tenant_id': userId,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select('id, category_name')
              .single();

      return SearchableAddableDropdownItem(
        id: response['id'],
        name: response['category_name'],
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error adding category: ${e.toString()}');
      }
      return null;
    }
  }

  void _showSearchableAddableBottomSheet({
    required String title,
    required String searchHint,
    required Future<List<SearchableAddableDropdownItem>> Function(String?)
    fetchItems,
    required Future<SearchableAddableDropdownItem?> Function(String) addItem,
    required Function(SearchableAddableDropdownItem) onItemSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder:
          (context) => _SearchableAddableDropdown(
            title: title,
            searchHint: searchHint,
            fetchItems: fetchItems,
            addItem: addItem,
            onItemSelected: onItemSelected,
          ),
    );
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    if (widget.inventoryType == 'fabric' && _selectedBrand == null) {
      _showErrorSnackBar('Please select a brand for fabric items');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final isFabric = widget.inventoryType == 'fabric';
      final table = isFabric ? 'fabric_inventory' : 'accessories_inventory';

      final data = {
        if (isFabric)
          'fabric_item_name': _itemNameController.text.trim()
        else
          'accessory_item_name': _itemNameController.text.trim(),
        if (isFabric)
          'fabric_code': _itemCodeController.text.trim()
        else
          'accessory_code': _itemCodeController.text.trim(),
        if (isFabric)
          'shade_color': _colorController.text.trim()
        else
          'color': _colorController.text.trim(),
        'color_code': _colorCodeController.text.trim(),
        'quantity_available': int.parse(_quantityController.text),
        'minimum_stock_level': int.parse(_minimumStockController.text),
        'cost_per_unit': double.parse(_costController.text),
        'selling_price_per_unit': double.parse(_priceController.text),
        'unit_type': _selectedUnitType,
        'category_id': _selectedCategory!.id,
        'brand_id': _selectedBrand?.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(table)
          .update(data)
          .eq('id', widget.item['id'])
          .eq('tenant_id', userId);

      if (mounted) {
        _showSuccessSnackBar(
          '${isFabric ? 'Fabric' : 'Accessory'} updated successfully',
        );
        widget.onItemUpdated?.call();
        _handleClose();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating item: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: InventoryDesignConfig.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: InventoryDesignConfig.errorColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Supporting classes (from add sheet)
class SearchableAddableDropdownItem {
  final String id;
  final String name;

  SearchableAddableDropdownItem({required this.id, required this.name});
}

class _SearchableAddableDropdown extends StatefulWidget {
  final String title;
  final String searchHint;
  final Future<List<SearchableAddableDropdownItem>> Function(String?)
  fetchItems;
  final Future<SearchableAddableDropdownItem?> Function(String) addItem;
  final Function(SearchableAddableDropdownItem) onItemSelected;

  const _SearchableAddableDropdown({
    required this.title,
    required this.searchHint,
    required this.fetchItems,
    required this.addItem,
    required this.onItemSelected,
  });

  @override
  State<_SearchableAddableDropdown> createState() =>
      __SearchableAddableDropdownState();
}

class __SearchableAddableDropdownState extends State<_SearchableAddableDropdown>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _sheetAnimation;

  bool _isLoading = false;
  bool _isAdding = false;
  List<SearchableAddableDropdownItem> _items = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadItems();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sheetAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await widget.fetchItems(
        _searchQuery.isEmpty ? null : _searchQuery,
      );
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewItem() async {
    if (_searchQuery.trim().isEmpty) return;

    setState(() => _isAdding = true);
    try {
      final newItem = await widget.addItem(_searchQuery.trim());
      if (newItem != null) {
        widget.onItemSelected(newItem);
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error handling is done in the parent
    } finally {
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Container(
          height: screenHeight * 0.8,
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(InventoryDesignConfig.radiusXL),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchSection(),
              Expanded(child: _buildItemsList()),
              if (_searchQuery.isNotEmpty &&
                  !_items.any(
                    (item) =>
                        item.name.toLowerCase() == _searchQuery.toLowerCase(),
                  ))
                _buildAddNewSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.magnifyingGlass(),
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Text(widget.title, style: InventoryDesignConfig.titleLarge),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(PhosphorIcons.x()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: InventoryDesignConfig.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.searchHint,
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
          filled: true,
          fillColor: InventoryDesignConfig.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: InventoryDesignConfig.spacingM,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _loadItems();
        },
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: InventoryDesignConfig.primaryColor,
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.package(),
              size: 48,
              color: InventoryDesignConfig.textTertiary,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Text('No items found', style: InventoryDesignConfig.titleMedium),
            Text(
              _searchQuery.isEmpty
                  ? 'No items available'
                  : 'Try a different search term',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingL,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              widget.onItemSelected(item);
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: InventoryDesignConfig.borderSecondary,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.primaryColor.withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                    ),
                    child: Icon(
                      PhosphorIcons.tag(),
                      size: 20,
                      color: InventoryDesignConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Expanded(
                    child: Text(
                      item.name,
                      style: InventoryDesignConfig.bodyLarge,
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretRight(),
                    size: 16,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddNewSection() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        border: Border(
          top: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isAdding ? null : _addNewItem,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              border: Border.all(
                color: InventoryDesignConfig.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isAdding) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        InventoryDesignConfig.primaryColor,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    PhosphorIcons.plus(),
                    size: 18,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  Text(
                    'Add "${_searchQuery.trim()}"',
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      color: InventoryDesignConfig.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorPickerSheet extends StatefulWidget {
  final String initialColor;
  final String initialColorCode;
  final Function(String colorName, String colorCode) onColorSelected;

  const _ColorPickerSheet({
    required this.initialColor,
    required this.initialColorCode,
    required this.onColorSelected,
  });

  @override
  State<_ColorPickerSheet> createState() => __ColorPickerSheetState();
}

class __ColorPickerSheetState extends State<_ColorPickerSheet> {
  late String _selectedColor;
  late String _selectedColorCode;
  final _customColorController = TextEditingController();

  final List<Map<String, String>> _predefinedColors = [
    {'name': 'Red', 'code': '#FF0000'},
    {'name': 'Blue', 'code': '#0000FF'},
    {'name': 'Green', 'code': '#008000'},
    {'name': 'Yellow', 'code': '#FFFF00'},
    {'name': 'Orange', 'code': '#FFA500'},
    {'name': 'Purple', 'code': '#800080'},
    {'name': 'Pink', 'code': '#FFC0CB'},
    {'name': 'Brown', 'code': '#A52A2A'},
    {'name': 'Black', 'code': '#000000'},
    {'name': 'White', 'code': '#FFFFFF'},
    {'name': 'Gray', 'code': '#808080'},
    {'name': 'Navy', 'code': '#000080'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _selectedColorCode = widget.initialColorCode;
  }

  @override
  void dispose() {
    _customColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Color',
                    style: InventoryDesignConfig.titleMedium,
                  ),
                  const SizedBox(height: InventoryDesignConfig.spacingL),
                  _buildColorGrid(),
                  const SizedBox(height: InventoryDesignConfig.spacingXXL),
                  Text(
                    'Or enter custom color',
                    style: InventoryDesignConfig.titleMedium,
                  ),
                  const SizedBox(height: InventoryDesignConfig.spacingL),
                  _buildCustomColorInput(),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.palette(),
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Text(
              'Select Color',
              style: InventoryDesignConfig.titleLarge,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(PhosphorIcons.x()),
          ),
        ],
      ),
    );
  }

  Widget _buildColorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: InventoryDesignConfig.spacingM,
        mainAxisSpacing: InventoryDesignConfig.spacingM,
        childAspectRatio: 1,
      ),
      itemCount: _predefinedColors.length,
      itemBuilder: (context, index) {
        final color = _predefinedColors[index];
        final isSelected = _selectedColor == color['name'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color['name']!;
              _selectedColorCode = color['code']!;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: _parseColor(color['code']!),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              border: Border.all(
                color:
                    isSelected
                        ? InventoryDesignConfig.primaryColor
                        : InventoryDesignConfig.borderPrimary,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Icon(
                    PhosphorIcons.check(),
                    color:
                        color['name'] == 'White' || color['name'] == 'Yellow'
                            ? Colors.black
                            : Colors.white,
                    size: 24,
                  ),
                const SizedBox(height: InventoryDesignConfig.spacingXS),
                Text(
                  color['name']!,
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color:
                        color['name'] == 'White' || color['name'] == 'Yellow'
                            ? Colors.black
                            : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomColorInput() {
    return TextField(
      controller: _customColorController,
      style: InventoryDesignConfig.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Enter color name',
        hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
          color: InventoryDesignConfig.textTertiary,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
          child: Icon(
            PhosphorIcons.textT(),
            size: 18,
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
        filled: true,
        fillColor: InventoryDesignConfig.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: InventoryDesignConfig.spacingM,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _selectedColor = value;
          _selectedColorCode = '';
        });
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final colorName =
                    _customColorController.text.isNotEmpty
                        ? _customColorController.text.trim()
                        : _selectedColor;
                widget.onColorSelected(colorName, _selectedColorCode);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: InventoryDesignConfig.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Select'),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorCode) {
    try {
      return Color(int.parse(colorCode.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return InventoryDesignConfig.textTertiary;
    }
  }
}

class _UnitTypePickerSheet extends StatelessWidget {
  final String selectedUnit;
  final List<String> unitTypes;
  final Function(String) onUnitSelected;

  const _UnitTypePickerSheet({
    required this.selectedUnit,
    required this.unitTypes,
    required this.onUnitSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: InventoryDesignConfig.spacingL,
              ),
              itemCount: unitTypes.length,
              itemBuilder: (context, index) {
                final unit = unitTypes[index];
                final isSelected = selectedUnit == unit;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      onUnitSelected(unit);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(
                        InventoryDesignConfig.spacingL,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? InventoryDesignConfig.primaryColor
                                    .withOpacity(0.1)
                                : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: InventoryDesignConfig.borderSecondary,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? InventoryDesignConfig.primaryColor
                                      : InventoryDesignConfig.surfaceLight,
                              borderRadius: BorderRadius.circular(
                                InventoryDesignConfig.radiusS,
                              ),
                            ),
                            child: Icon(
                              PhosphorIcons.ruler(),
                              size: 16,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : InventoryDesignConfig.textSecondary,
                            ),
                          ),
                          const SizedBox(width: InventoryDesignConfig.spacingM),
                          Expanded(
                            child: Text(
                              unit,
                              style: InventoryDesignConfig.bodyLarge.copyWith(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                color:
                                    isSelected
                                        ? InventoryDesignConfig.primaryColor
                                        : InventoryDesignConfig.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              PhosphorIcons.check(),
                              size: 18,
                              color: InventoryDesignConfig.primaryColor,
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
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.ruler(),
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Text(
              'Select Unit Type',
              style: InventoryDesignConfig.titleLarge,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(PhosphorIcons.x()),
          ),
        ],
      ),
    );
  }
}
