import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inventory_design_config.dart';

class SearchableAddableDropdownItem {
  final String id;
  final String name;

  SearchableAddableDropdownItem({required this.id, required this.name});
}

class AddInventoryMobileSheet extends StatefulWidget {
  final String inventoryType; // 'fabric' or 'accessory'
  final VoidCallback? onItemAdded;

  const AddInventoryMobileSheet({
    Key? key,
    required this.inventoryType,
    this.onItemAdded,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String inventoryType,
    VoidCallback? onItemAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      useSafeArea: true,
      builder:
          (context) => AddInventoryMobileSheet(
            inventoryType: inventoryType,
            onItemAdded: onItemAdded,
          ),
    );
  }

  @override
  State<AddInventoryMobileSheet> createState() =>
      _AddInventoryMobileSheetState();
}

class _AddInventoryMobileSheetState extends State<AddInventoryMobileSheet>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _sheetAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _sheetAnimation;
  late Animation<double> _contentOpacityAnimation;

  // Focus nodes for keyboard management
  final _sheetFocusNode = FocusNode();
  final _itemNameFocusNode = FocusNode();
  final _itemCodeFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  final _minimumStockFocusNode = FocusNode();
  final _costFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();

  // Form controllers
  final _itemNameController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _colorController = TextEditingController();
  final _colorCodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();

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
    _initializeAnimations();
    _setupKeyboardListener();
    _setupFormListeners();

    // Set default unit type based on inventory type
    _selectedUnitType = widget.inventoryType == 'fabric' ? 'meter' : 'piece';

    // Request focus for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sheetFocusNode.requestFocus();
      _startEntryAnimation();
    });
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

    _contentOpacityAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOut,
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
    // Update UI or show profit margin somewhere if needed
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
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                // Main sheet content
                Positioned(
                  left: 0,
                  right: 0,
                  top: safeAreaTop + 40,
                  bottom: 0,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (screenHeight - safeAreaTop - 40) *
                          (1 - _sheetAnimation.value),
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
            // Header
            _buildHeader(),

            // Form content
            Expanded(
              child: AnimatedBuilder(
                animation: _contentOpacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _contentOpacityAnimation.value,
                    child: _buildFormContent(safeAreaBottom),
                  );
                },
              ),
            ),

            // Action buttons
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
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingL,
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color: InventoryDesignConfig.primaryColor.withOpacity(
                        0.2,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isFabric
                        ? PhosphorIcons.scissors()
                        : PhosphorIcons.package(),
                    color: InventoryDesignConfig.primaryColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: InventoryDesignConfig.spacingL),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add ${isFabric ? 'Fabric' : 'Accessory'}',
                        style: InventoryDesignConfig.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        'Fill in the details below',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Close button
                _buildHeaderActionButton(
                  icon: PhosphorIcons.x(),
                  onTap: _handleClose,
                  semanticLabel: 'Close form',
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
              color: InventoryDesignConfig.textSecondary.withOpacity(0.1),
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
        // Added GestureDetector for tap-outside-to-dismiss
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
                    // nextFocusNode is null here, TextInputAction.done will be handled by default
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? 'Item code is required'
                                : null,
                    textInputAction: TextInputAction.done,
                    prefixIcon: PhosphorIcons.barcode(),
                    // Removed explicit onFieldSubmitted, default handler will take care of it
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
                    // nextFocusNode is null here, TextInputAction.done will be handled by default
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
                    // Removed explicit onFieldSubmitted, default handler will take care of it
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
              // Added to dismiss keyboard on tap outside while field is focused
              focusNode?.unfocus();
            },
            onFieldSubmitted:
                onFieldSubmitted ??
                (String value) {
                  if (textInputAction == TextInputAction.next) {
                    if (nextFocusNode != null) {
                      FocusScope.of(context).requestFocus(nextFocusNode);
                    } else {
                      // If nextFocusNode is null but action is next, unfocus as a fallback
                      focusNode?.unfocus();
                      FocusScope.of(context).unfocus();
                    }
                  } else if (textInputAction == TextInputAction.done) {
                    focusNode?.unfocus();
                    FocusScope.of(context).unfocus();
                  }
                },
            onEditingComplete: () {
              // This is sometimes more reliable for 'done' action, especially with numeric keyboards.
              // However, onFieldSubmitted should generally handle it.
              // If issues persist, this could be a place for more aggressive unfocusing.
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
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
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
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  Expanded(
                    child: Text(
                      _selectedUnitType,
                      style: InventoryDesignConfig.bodyLarge,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profit Analysis',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingS,
                  vertical: InventoryDesignConfig.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: profitColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                ),
                child: Text(
                  healthText,
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: profitColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profit per Unit',
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${profit.toStringAsFixed(2)}',
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      color: profitColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Margin',
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  ),
                  Text(
                    '${marginPercent.toStringAsFixed(1)}%',
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      color: profitColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
            child: _buildActionButton(
              label: _isSaving ? 'Saving...' : 'Save Item',
              icon: _isSaving ? null : PhosphorIcons.check(),
              color: Colors.white,
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
          onTap:
              onTap != null && !loading
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
                if (loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else if (icon != null)
                  Icon(icon, size: 18, color: color),
                if ((icon != null || loading) && label.isNotEmpty)
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                if (label.isNotEmpty)
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
      ),
    );
  }

  // Picker methods
  void _showCategoryPicker() {
    // Dismiss keyboard before showing picker
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
    // Dismiss keyboard before showing picker
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

  void _showColorPicker() {
    // Dismiss keyboard before showing picker
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
    // Dismiss keyboard before showing picker
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

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus(); // Ensure keyboard is dismissed first

    if (!_formKey.currentState!.validate()) {
      // Scroll to first error
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
        'is_active': true,
        'tenant_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(table).insert(data);

      if (mounted) {
        _showSuccessSnackBar(
          '${isFabric ? 'Fabric' : 'Accessory'} added successfully',
        );
        widget.onItemAdded?.call();
        _handleClose();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error saving item: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: InventoryDesignConfig.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: InventoryDesignConfig.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Data fetching methods
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
}

// Separate widget for searchable addable dropdown
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
      _SearchableAddableDropdownState();
}

class _SearchableAddableDropdownState extends State<_SearchableAddableDropdown>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _addController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _addFocusNode = FocusNode();
  List<SearchableAddableDropdownItem> _items = [];
  bool _isLoading = false;
  bool _isAdding = false;
  bool _showAddField = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _loadItems();

    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _addController.dispose();
    _searchFocusNode.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await widget.fetchItems(_searchController.text);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem() async {
    if (_addController.text.trim().isEmpty) return;

    setState(() => _isAdding = true);
    try {
      final newItem = await widget.addItem(_addController.text.trim());
      if (newItem != null) {
        HapticFeedback.lightImpact();
        widget.onItemSelected(newItem);
        Navigator.pop(context);
      }
    } catch (e) {
      // Error handled in parent
    } finally {
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 100),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
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
                  padding: const EdgeInsets.fromLTRB(
                    InventoryDesignConfig.spacingXL,
                    InventoryDesignConfig.spacingS,
                    InventoryDesignConfig.spacingL,
                    InventoryDesignConfig.spacingL,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(
                          InventoryDesignConfig.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: InventoryDesignConfig.primaryColor.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusS,
                          ),
                        ),
                        child: Icon(
                          PhosphorIcons.funnel(),
                          size: 16,
                          color: InventoryDesignConfig.primaryColor,
                        ),
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingM),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: InventoryDesignConfig.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusM,
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusM,
                          ),
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
                              PhosphorIcons.x(),
                              size: 18,
                              color: InventoryDesignConfig.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: InventoryDesignConfig.spacingXL,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      border: Border.all(
                        color: InventoryDesignConfig.borderPrimary,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: InventoryDesignConfig.bodyLarge,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.textTertiary,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(
                            InventoryDesignConfig.spacingM,
                          ),
                          child: Icon(
                            PhosphorIcons.magnifyingGlass(),
                            size: 18,
                            color: InventoryDesignConfig.textSecondary,
                          ),
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadItems();
                                  },
                                  icon: Icon(
                                    PhosphorIcons.x(),
                                    size: 16,
                                    color: InventoryDesignConfig.textSecondary,
                                  ),
                                )
                                : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: InventoryDesignConfig.spacingM,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        _loadItems();
                      },
                      onSubmitted: (_) => _searchFocusNode.unfocus(),
                    ),
                  ),
                ),

                const SizedBox(height: InventoryDesignConfig.spacingL),

                // Add new section
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showAddField ? 80 : 56,
                  padding: const EdgeInsets.symmetric(
                    horizontal: InventoryDesignConfig.spacingXL,
                  ),
                  child:
                      _showAddField
                          ? _buildAddNewField()
                          : _buildAddNewButton(),
                ),

                const SizedBox(height: InventoryDesignConfig.spacingM),

                // Items list
                Expanded(
                  child:
                      _isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: InventoryDesignConfig.primaryColor,
                            ),
                          )
                          : _items.isEmpty
                          ? _buildEmptyState()
                          : _buildItemsList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddNewButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: () {
          setState(() => _showAddField = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _addFocusNode.requestFocus();
          });
        },
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.plus(),
                size: 18,
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Add New ${widget.title}',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewField() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: TextField(
            controller: _addController,
            focusNode: _addFocusNode,
            style: InventoryDesignConfig.bodyLarge,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Enter new ${widget.title.toLowerCase()}...',
              hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textTertiary,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                child: Icon(
                  PhosphorIcons.plus(),
                  size: 18,
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: InventoryDesignConfig.spacingM,
              ),
            ),
            onSubmitted: (_) => _addItem(),
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusS,
                ),
                child: InkWell(
                  onTap: () => setState(() => _showAddField = false),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: InventoryDesignConfig.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                      border: Border.all(
                        color: InventoryDesignConfig.borderPrimary,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      textAlign: TextAlign.center,
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusS,
                ),
                child: InkWell(
                  onTap: _isAdding ? null : _addItem,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: InventoryDesignConfig.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.primaryColor,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                    ),
                    child:
                        _isAdding
                            ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              'Add',
                              textAlign: TextAlign.center,
                              style: InventoryDesignConfig.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXL,
      ),
      itemCount: _items.length,
      separatorBuilder:
          (context, index) => Container(
            height: 1,
            color: InventoryDesignConfig.borderSecondary,
            margin: const EdgeInsets.symmetric(
              vertical: InventoryDesignConfig.spacingXS,
            ),
          ),
      itemBuilder: (context, index) {
        final item = _items[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onItemSelected(item);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: InventoryDesignConfig.spacingM,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.primaryColor.withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                    ),
                    child: Icon(
                      PhosphorIcons.folder(),
                      size: 16,
                      color: InventoryDesignConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Expanded(
                    child: Text(
                      item.name,
                      style: InventoryDesignConfig.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretRight(),
                    size: 16,
                    color: InventoryDesignConfig.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceLight,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusXL,
              ),
            ),
            child: Icon(
              PhosphorIcons.magnifyingGlass(),
              size: 32,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Text('No items found', style: InventoryDesignConfig.titleMedium),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            'Try searching with different keywords',
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Color picker sheet
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
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet>
    with TickerProviderStateMixin {
  final _customColorController = TextEditingController();
  final _customColorFocusNode = FocusNode();
  String _selectedColorName = '';
  String _selectedColorCode = '';

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Predefined color palette
  final List<Map<String, dynamic>> _colorPalette = [
    {'name': 'Red', 'code': '#FF0000', 'color': Colors.red},
    {'name': 'Blue', 'code': '#0000FF', 'color': Colors.blue},
    {'name': 'Green', 'code': '#008000', 'color': Colors.green},
    {'name': 'Yellow', 'code': '#FFFF00', 'color': Colors.yellow},
    {'name': 'Orange', 'code': '#FFA500', 'color': Colors.orange},
    {'name': 'Purple', 'code': '#800080', 'color': Colors.purple},
    {'name': 'Pink', 'code': '#FFC0CB', 'color': Colors.pink},
    {'name': 'Brown', 'code': '#A52A2A', 'color': Colors.brown},
    {'name': 'Grey', 'code': '#808080', 'color': Colors.grey},
    {'name': 'Black', 'code': '#000000', 'color': Colors.black},
    {'name': 'White', 'code': '#FFFFFF', 'color': Colors.white},
    {'name': 'Navy', 'code': '#000080', 'color': Colors.indigo},
    {'name': 'Teal', 'code': '#008080', 'color': Colors.teal},
    {'name': 'Lime', 'code': '#00FF00', 'color': Colors.lime},
    {'name': 'Cyan', 'code': '#00FFFF', 'color': Colors.cyan},
    {'name': 'Amber', 'code': '#FFC107', 'color': Colors.amber},
  ];

  @override
  void initState() {
    super.initState();
    _selectedColorName = widget.initialColor;
    _selectedColorCode = widget.initialColorCode;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customColorController.dispose();
    _customColorFocusNode.dispose();
    super.dispose();
  }

  void _selectColor(String name, String code) {
    setState(() {
      _selectedColorName = name;
      _selectedColorCode = code;
    });
  }

  void _handleCustomColor() {
    final customColor = _customColorController.text.trim();
    if (customColor.isNotEmpty) {
      // Validate hex color
      if (customColor.startsWith('#') && customColor.length == 7) {
        _selectColor('Custom', customColor);
      } else {
        _selectColor(customColor, customColor);
      }
    }
  }

  void _confirmSelection() {
    if (_selectedColorName.isNotEmpty) {
      HapticFeedback.selectionClick();
      widget.onColorSelected(_selectedColorName, _selectedColorCode);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 100),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
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
                  padding: const EdgeInsets.fromLTRB(
                    InventoryDesignConfig.spacingXL,
                    InventoryDesignConfig.spacingS,
                    InventoryDesignConfig.spacingL,
                    InventoryDesignConfig.spacingL,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(
                          InventoryDesignConfig.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: InventoryDesignConfig.primaryColor.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusS,
                          ),
                        ),
                        child: Icon(
                          PhosphorIcons.palette(),
                          size: 16,
                          color: InventoryDesignConfig.primaryColor,
                        ),
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingM),
                      Expanded(
                        child: Text(
                          'Select Color',
                          style: InventoryDesignConfig.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusM,
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusM,
                          ),
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
                              PhosphorIcons.x(),
                              size: 18,
                              color: InventoryDesignConfig.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected color preview
                if (_selectedColorName.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: InventoryDesignConfig.spacingXL,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(
                        InventoryDesignConfig.spacingL,
                      ),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.surfaceLight,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusM,
                        ),
                        border: Border.all(
                          color: InventoryDesignConfig.borderPrimary,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _parseColor(_selectedColorCode),
                              borderRadius: BorderRadius.circular(
                                InventoryDesignConfig.radiusS,
                              ),
                              border: Border.all(
                                color: InventoryDesignConfig.borderPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: InventoryDesignConfig.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedColorName,
                                  style: InventoryDesignConfig.titleMedium,
                                ),
                                Text(
                                  _selectedColorCode,
                                  style: InventoryDesignConfig.code,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            PhosphorIcons.check(),
                            color: InventoryDesignConfig.successColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: InventoryDesignConfig.spacingL),
                ],

                // Color palette
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: InventoryDesignConfig.spacingXL,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Color Palette',
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: InventoryDesignConfig.spacingM),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing:
                                    InventoryDesignConfig.spacingM,
                                mainAxisSpacing: InventoryDesignConfig.spacingM,
                                childAspectRatio: 1,
                              ),
                          itemCount: _colorPalette.length,
                          itemBuilder: (context, index) {
                            final colorData = _colorPalette[index];
                            final isSelected =
                                _selectedColorName == colorData['name'];

                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                InventoryDesignConfig.radiusM,
                              ),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _selectColor(
                                    colorData['name'],
                                    colorData['code'],
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorData['color'],
                                    borderRadius: BorderRadius.circular(
                                      InventoryDesignConfig.radiusM,
                                    ),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? InventoryDesignConfig
                                                  .primaryColor
                                              : InventoryDesignConfig
                                                  .borderPrimary,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    boxShadow:
                                        isSelected
                                            ? [
                                              BoxShadow(
                                                color: InventoryDesignConfig
                                                    .primaryColor
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                            : null,
                                  ),
                                  child:
                                      isSelected
                                          ? Icon(
                                            PhosphorIcons.check(),
                                            color: _getContrastColor(
                                              colorData['color'],
                                            ),
                                            size: 20,
                                          )
                                          : null,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: InventoryDesignConfig.spacingXL),

                        // Custom color input
                        Text(
                          'Custom Color',
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: InventoryDesignConfig.spacingM),

                        Container(
                          decoration: BoxDecoration(
                            color: InventoryDesignConfig.surfaceLight,
                            borderRadius: BorderRadius.circular(
                              InventoryDesignConfig.radiusM,
                            ),
                            border: Border.all(
                              color: InventoryDesignConfig.borderPrimary,
                            ),
                          ),
                          child: TextField(
                            controller: _customColorController,
                            focusNode: _customColorFocusNode,
                            style: InventoryDesignConfig.bodyLarge,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText:
                                  'Enter color name or hex code (#FF0000)',
                              hintStyle: InventoryDesignConfig.bodyMedium
                                  .copyWith(
                                    color: InventoryDesignConfig.textTertiary,
                                  ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(
                                  InventoryDesignConfig.spacingM,
                                ),
                                child: Icon(
                                  PhosphorIcons.eyedropper(),
                                  size: 18,
                                  color: InventoryDesignConfig.textSecondary,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: InventoryDesignConfig.spacingM,
                              ),
                            ),
                            onSubmitted: (_) => _handleCustomColor(),
                            onChanged: (_) => _handleCustomColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: EdgeInsets.fromLTRB(
                    InventoryDesignConfig.spacingXL,
                    InventoryDesignConfig.spacingL,
                    InventoryDesignConfig.spacingXL,
                    InventoryDesignConfig.spacingL +
                        MediaQuery.of(context).padding.bottom,
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
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusM,
                          ),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(
                              InventoryDesignConfig.radiusM,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: InventoryDesignConfig.spacingL,
                              ),
                              decoration: BoxDecoration(
                                color: InventoryDesignConfig.surfaceLight,
                                borderRadius: BorderRadius.circular(
                                  InventoryDesignConfig.radiusM,
                                ),
                                border: Border.all(
                                  color: InventoryDesignConfig.borderPrimary,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                textAlign: TextAlign.center,
                                style: InventoryDesignConfig.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingM),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusM,
                          ),
                          child: InkWell(
                            onTap:
                                _selectedColorName.isNotEmpty
                                    ? _confirmSelection
                                    : null,
                            borderRadius: BorderRadius.circular(
                              InventoryDesignConfig.radiusM,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: InventoryDesignConfig.spacingL,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _selectedColorName.isNotEmpty
                                        ? InventoryDesignConfig.primaryColor
                                        : InventoryDesignConfig.textTertiary,
                                borderRadius: BorderRadius.circular(
                                  InventoryDesignConfig.radiusM,
                                ),
                              ),
                              child: Text(
                                'Select Color',
                                textAlign: TextAlign.center,
                                style: InventoryDesignConfig.bodyMedium
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String colorCode) {
    if (colorCode.isEmpty) return InventoryDesignConfig.textTertiary;

    try {
      if (colorCode.startsWith('#')) {
        String hexCode = colorCode.substring(1);
        if (hexCode.length == 6) {
          return Color(int.parse('FF$hexCode', radix: 16));
        }
      }
      return InventoryDesignConfig.textTertiary;
    } catch (e) {
      return InventoryDesignConfig.textTertiary;
    }
  }

  Color _getContrastColor(Color color) {
    // Calculate relative luminance
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

// Unit type picker sheet
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
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
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
                    PhosphorIcons.ruler(),
                    size: 16,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  'Select Unit Type',
                  style: InventoryDesignConfig.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Options
          ...unitTypes.map((unit) {
            final isSelected = unit == selectedUnit;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onUnitSelected(unit);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: InventoryDesignConfig.spacingXL,
                    vertical: InventoryDesignConfig.spacingL,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? InventoryDesignConfig.primaryColor.withOpacity(
                              0.1,
                            )
                            : Colors.transparent,
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
                                isSelected ? FontWeight.w600 : FontWeight.w400,
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
          }),

          SizedBox(
            height:
                MediaQuery.of(context).padding.bottom +
                InventoryDesignConfig.spacingL,
          ),
        ],
      ),
    );
  }
}
