import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../inventory/inventory_design_config.dart';

class AddCustomerMobileSheet extends StatefulWidget {
  final Customer? customer;
  final int? index;
  final bool isEditing;
  final VoidCallback? onCustomerAdded;

  const AddCustomerMobileSheet({
    super.key,
    this.customer,
    this.index,
    this.isEditing = false,
    this.onCustomerAdded,
  });

  static Future<void> show(
    BuildContext context, {
    Customer? customer,
    int? index,
    bool isEditing = false,
    VoidCallback? onCustomerAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      useSafeArea: true,
      builder:
          (context) => AddCustomerMobileSheet(
            customer: customer,
            index: index,
            isEditing: isEditing,
            onCustomerAdded: onCustomerAdded,
          ),
    );
  }

  @override
  State<AddCustomerMobileSheet> createState() => _AddCustomerMobileSheetState();
}

class _AddCustomerMobileSheetState extends State<AddCustomerMobileSheet>
    with TickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _sheetAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _sheetAnimation;
  late Animation<double> _contentOpacityAnimation;

  // Focus nodes for keyboard management
  final _sheetFocusNode = FocusNode();
  final _billNumberFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _whatsappFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  // Form controllers
  final _billNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();

  // Form state
  Gender _selectedGender = Gender.male;
  bool _useCustomBillNumber = false;
  Customer? _referredBy;
  Customer? _familyMember;
  FamilyRelation? _familyRelation;
  bool _isSaving = false;

  // Keyboard state
  double _keyboardHeight = 0;
  bool _isKeyboardVisible = false;

  // Gender options
  final List<Gender> _genderOptions = [Gender.male, Gender.female];

  // Family relation options
  final List<FamilyRelation> _familyRelationOptions = [
    FamilyRelation.parent,
    FamilyRelation.spouse,
    FamilyRelation.child,
    FamilyRelation.sibling,
    FamilyRelation.other,
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupKeyboardListener();
    _setupFormListeners();
    _initializeData();

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
    // Auto-capitalize first letter of each word in name
    _nameController.addListener(() {
      final text = _nameController.text;
      final selection = _nameController.selection;
      if (text.isNotEmpty) {
        final words = text.split(' ');
        final capitalizedWords = words
            .map((word) {
              if (word.isNotEmpty) {
                return word[0].toUpperCase() + word.substring(1).toLowerCase();
              }
              return word;
            })
            .join(' ');

        if (capitalizedWords != text) {
          _nameController.value = TextEditingValue(
            text: capitalizedWords,
            selection: selection,
          );
        }
      }
    });
  }

  void _initializeData() {
    if (widget.isEditing && widget.customer != null) {
      final customer = widget.customer!;
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _whatsappController.text = customer.whatsapp;
      _addressController.text = customer.address;
      _selectedGender = customer.gender;
      _billNumberController.text = customer.billNumber;

      if (customer.referredBy != null) {
        _loadReferringCustomer(customer.referredBy!);
      }
      if (customer.familyId != null) {
        _loadFamilyMember(customer.familyId!);
        _familyRelation = customer.familyRelation;
      }
    } else {
      _selectedGender = Gender.male;
      _generateBillNumber();
    }
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
    _billNumberFocusNode.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _whatsappFocusNode.dispose();
    _addressFocusNode.dispose();

    // Dispose controllers
    _billNumberController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();

    super.dispose();
  }

  Future<void> _generateBillNumber() async {
    if (!widget.isEditing) {
      try {
        final billNumber = await _supabaseService.generateUniqueBillNumber();
        _billNumberController.text = billNumber;
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _loadReferringCustomer(String referredById) async {
    try {
      final customer = await _supabaseService.getCustomerById(referredById);
      if (customer != null && mounted) {
        setState(() => _referredBy = customer);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadFamilyMember(String familyId) async {
    try {
      final member = await _supabaseService.getCustomerById(familyId);
      if (member != null && mounted) {
        setState(() => _familyMember = member);
      }
    } catch (e) {
      // Handle error silently
    }
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
                    widget.isEditing
                        ? PhosphorIcons.pencilSimple()
                        : PhosphorIcons.userPlus(),
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
                        widget.isEditing ? 'Edit Customer' : 'Add Customer',
                        style: InventoryDesignConfig.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        widget.isEditing
                            ? 'Update customer information'
                            : 'Fill in the customer details',
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
        onTap: () => FocusScope.of(context).unfocus(),
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
              // Bill Number Section (only for new customers)
              if (!widget.isEditing) ...[
                _buildFormSection(
                  title: 'Bill Number',
                  icon: PhosphorIcons.receipt(),
                  children: [
                    _buildTextFormField(
                      label: 'Bill Number',
                      controller: _billNumberController,
                      focusNode: _billNumberFocusNode,
                      nextFocusNode: _nameFocusNode,
                      enabled: _useCustomBillNumber,
                      validator: _validateBillNumber,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      prefixIcon: PhosphorIcons.receipt(),
                      helperText:
                          _useCustomBillNumber
                              ? 'Enter a custom bill number'
                              : 'Auto-generated bill number',
                    ),

                    const SizedBox(height: InventoryDesignConfig.spacingL),

                    _buildSwitchTile(
                      title: 'Use custom bill number',
                      subtitle: 'Enable to set a custom bill number',
                      value: _useCustomBillNumber,
                      onChanged: (value) {
                        setState(() {
                          _useCustomBillNumber = value;
                          if (!value) {
                            _generateBillNumber();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: InventoryDesignConfig.spacingXXL),
              ],

              // Basic Information Section
              _buildFormSection(
                title: 'Basic Information',
                icon: PhosphorIcons.user(),
                children: [
                  _buildTextFormField(
                    label: 'Full Name',
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    nextFocusNode: _phoneFocusNode,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                    textInputAction: TextInputAction.next,
                    prefixIcon: PhosphorIcons.user(),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: InventoryDesignConfig.spacingL),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          nextFocusNode: _whatsappFocusNode,
                          keyboardType: TextInputType.phone,
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true
                                      ? 'Phone is required'
                                      : null,
                          textInputAction: TextInputAction.next,
                          prefixIcon: PhosphorIcons.phone(),
                        ),
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingM),
                      Expanded(
                        child: _buildTextFormField(
                          label: 'WhatsApp (Optional)',
                          controller: _whatsappController,
                          focusNode: _whatsappFocusNode,
                          nextFocusNode: _addressFocusNode,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          prefixIcon: PhosphorIcons.whatsappLogo(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: InventoryDesignConfig.spacingL),

                  _buildTextFormField(
                    label: 'Address',
                    controller: _addressController,
                    focusNode: _addressFocusNode,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? 'Address is required'
                                : null,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    prefixIcon: PhosphorIcons.mapPin(),
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  const SizedBox(height: InventoryDesignConfig.spacingL),

                  _buildGenderSelector(),
                ],
              ),

              const SizedBox(height: InventoryDesignConfig.spacingXXL),

              // Referral & Family Section
              _buildFormSection(
                title: 'Referral & Family',
                icon: PhosphorIcons.users(),
                children: [
                  _buildReferralSection(),
                  const SizedBox(height: InventoryDesignConfig.spacingL),
                  _buildFamilySection(),
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
    IconData? prefixIcon,
    String? helperText,
    int maxLines = 1,
    bool enabled = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
            maxLines: maxLines,
            enabled: enabled,
            textCapitalization: textCapitalization,
            style: InventoryDesignConfig.bodyLarge.copyWith(
              color:
                  enabled
                      ? InventoryDesignConfig.textPrimary
                      : InventoryDesignConfig.textTertiary,
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
                          color:
                              enabled
                                  ? InventoryDesignConfig.textSecondary
                                  : InventoryDesignConfig.textTertiary,
                        ),
                      )
                      : null,
              helperText: helperText,
              helperStyle: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.textTertiary,
              ),
              filled: true,
              fillColor:
                  enabled
                      ? InventoryDesignConfig.surfaceLight
                      : InventoryDesignConfig.surfaceAccent,
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
            onTapOutside: (_) => focusNode?.unfocus(),
            onFieldSubmitted: (String value) {
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
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.toggleLeft(),
            color: InventoryDesignConfig.primaryColor,
            size: 20,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: InventoryDesignConfig.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: InventoryDesignConfig.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: InventoryDesignConfig.textPrimary,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        Row(
          children:
              _genderOptions.map((gender) {
                final isSelected = _selectedGender == gender;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right:
                          gender != _genderOptions.last
                              ? InventoryDesignConfig.spacingM
                              : 0,
                    ),
                    child: _buildGenderOption(
                      gender: gender,
                      label: gender.name.toUpperCase(),
                      icon: PhosphorIcons.user(),
                      isSelected: isSelected,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenderOption({
    required Gender gender,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedGender = gender);
        },
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? InventoryDesignConfig.primaryColor.withOpacity(0.1)
                    : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color:
                  isSelected
                      ? InventoryDesignConfig.primaryColor
                      : InventoryDesignConfig.borderPrimary,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? InventoryDesignConfig.primaryColor
                        : InventoryDesignConfig.textSecondary,
                size: 18,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color:
                      isSelected
                          ? InventoryDesignConfig.primaryColor
                          : InventoryDesignConfig.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralSection() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.userPlus(),
                size: 16,
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Referral Information',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),

          if (_referredBy != null) ...[
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceColor,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: InventoryDesignConfig.primaryColor
                        .withOpacity(0.1),
                    child: Text(
                      _referredBy!.name[0].toUpperCase(),
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _referredBy!.name,
                          style: InventoryDesignConfig.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '#${_referredBy!.billNumber}',
                          style: InventoryDesignConfig.bodySmall.copyWith(
                            color: InventoryDesignConfig.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _referredBy = null),
                    icon: Icon(
                      PhosphorIcons.x(),
                      size: 16,
                      color: InventoryDesignConfig.errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: InkWell(
                onTap: _selectReferringCustomer,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.surfaceColor,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color: InventoryDesignConfig.borderPrimary,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.userPlus(),
                        size: 16,
                        color: InventoryDesignConfig.primaryColor,
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingS),
                      Text(
                        'Select Referring Customer',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilySection() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.users(),
                size: 16,
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Family Information',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),

          if (_familyMember != null) ...[
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceColor,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: InventoryDesignConfig.successColor
                            .withOpacity(0.1),
                        child: Text(
                          _familyMember!.name[0].toUpperCase(),
                          style: InventoryDesignConfig.bodySmall.copyWith(
                            color: InventoryDesignConfig.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _familyMember!.name,
                              style: InventoryDesignConfig.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '#${_familyMember!.billNumber}',
                              style: InventoryDesignConfig.bodySmall.copyWith(
                                color: InventoryDesignConfig.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            () => setState(() {
                              _familyMember = null;
                              _familyRelation = null;
                            }),
                        icon: Icon(
                          PhosphorIcons.x(),
                          size: 16,
                          color: InventoryDesignConfig.errorColor,
                        ),
                      ),
                    ],
                  ),
                  if (_familyRelation != null) ...[
                    const SizedBox(height: InventoryDesignConfig.spacingM),
                    _buildFamilyRelationSelector(),
                  ],
                ],
              ),
            ),
          ] else ...[
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: InkWell(
                onTap: _selectFamilyMember,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.surfaceColor,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color: InventoryDesignConfig.borderPrimary,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.users(),
                        size: 16,
                        color: InventoryDesignConfig.primaryColor,
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingS),
                      Text(
                        'Select Family Member',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilyRelationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relationship',
          style: InventoryDesignConfig.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Wrap(
          spacing: InventoryDesignConfig.spacingS,
          runSpacing: InventoryDesignConfig.spacingS,
          children:
              _familyRelationOptions.map((relation) {
                final isSelected = _familyRelation == relation;
                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _familyRelation = relation);
                    },
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: InventoryDesignConfig.spacingM,
                        vertical: InventoryDesignConfig.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? InventoryDesignConfig.primaryColor
                                : InventoryDesignConfig.surfaceLight,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                        border: Border.all(
                          color:
                              isSelected
                                  ? InventoryDesignConfig.primaryColor
                                  : InventoryDesignConfig.borderPrimary,
                        ),
                      ),
                      child: Text(
                        relation.name.toUpperCase(),
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color:
                              isSelected
                                  ? InventoryDesignConfig.surfaceColor
                                  : InventoryDesignConfig.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
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
              label:
                  _isSaving
                      ? 'Saving...'
                      : (widget.isEditing ? 'Update Customer' : 'Add Customer'),
              icon:
                  _isSaving
                      ? null
                      : (widget.isEditing
                          ? PhosphorIcons.check()
                          : PhosphorIcons.plus()),
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

  // Validation and helper methods
  String? _validateBillNumber(String? value) {
    if (widget.isEditing) return null;
    if (!_useCustomBillNumber) return null;
    if (value == null || value.isEmpty) {
      return 'Please enter a bill number';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Please enter only numbers';
    }
    return null;
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

    setState(() => _isSaving = true);

    try {
      String billNumber;
      if (widget.isEditing) {
        billNumber = widget.customer!.billNumber;
      } else {
        if (_useCustomBillNumber) {
          billNumber = _billNumberController.text;
          final isUnique = await _supabaseService.isBillNumberUnique(
            billNumber,
          );
          if (!isUnique) {
            throw Exception(
              'This bill number already exists. Please try another.',
            );
          }
        } else {
          billNumber = await _supabaseService.generateUniqueBillNumber();
        }
      }

      final customer = Customer(
        id: widget.isEditing ? widget.customer!.id : const Uuid().v4(),
        billNumber: billNumber,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        address: _addressController.text.trim(),
        gender: _selectedGender,
        referredBy: _referredBy?.id,
        familyId: _familyMember?.id,
        familyRelation: _familyRelation,
      );

      if (widget.isEditing) {
        await _supabaseService.updateCustomer(customer);
      } else {
        await _supabaseService.addCustomer(customer);
      }

      if (mounted) {
        _showSuccessSnackBar(
          widget.isEditing
              ? '${customer.name} updated successfully'
              : '${customer.name} added successfully',
        );
        widget.onCustomerAdded?.call();
        _handleClose();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
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

  Future<void> _selectReferringCustomer() async {
    try {
      final customers = await _supabaseService.getAllCustomers();
      if (!mounted) return;

      final customer = await _showCustomerSelector(
        context,
        customers,
        title: 'Select Referring Customer',
      );
      if (customer != null) {
        setState(() => _referredBy = customer);
      }
    } catch (e) {
      _showErrorSnackBar('Error loading customers: ${e.toString()}');
    }
  }

  Future<void> _selectFamilyMember() async {
    try {
      final customers = await _supabaseService.getAllCustomers();
      if (!mounted) return;

      final customer = await _showCustomerSelector(
        context,
        customers,
        title: 'Select Family Member',
      );
      if (customer != null) {
        setState(() {
          _familyMember = customer;
          _familyRelation = FamilyRelation.other; // Default relation
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading customers: ${e.toString()}');
    }
  }

  Future<Customer?> _showCustomerSelector(
    BuildContext context,
    List<Customer> customers, {
    required String title,
  }) {
    return showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              _CustomerSelectorSheet(customers: customers, title: title),
    );
  }
}

// Customer Selector Sheet Widget
class _CustomerSelectorSheet extends StatefulWidget {
  final List<Customer> customers;
  final String title;

  const _CustomerSelectorSheet({required this.customers, required this.title});

  @override
  State<_CustomerSelectorSheet> createState() => _CustomerSelectorSheetState();
}

class _CustomerSelectorSheetState extends State<_CustomerSelectorSheet> {
  final _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = widget.customers;
      } else {
        _filteredCustomers =
            widget.customers.where((customer) {
              return customer.name.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  customer.phone.contains(query) ||
                  customer.billNumber.contains(query);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.users(),
                  color: InventoryDesignConfig.primaryColor,
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(PhosphorIcons.x()),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
            ),
            child: TextField(
              controller: _searchController,
              style: InventoryDesignConfig.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                ),
              ),
              onChanged: _filterCustomers,
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingL),

          // Customer list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: InventoryDesignConfig.spacingL,
              ),
              itemCount: _filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = _filteredCustomers[index];
                return Card(
                  margin: const EdgeInsets.only(
                    bottom: InventoryDesignConfig.spacingS,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: InventoryDesignConfig.primaryColor
                          .withOpacity(0.1),
                      child: Text(
                        customer.name[0].toUpperCase(),
                        style: TextStyle(
                          color: InventoryDesignConfig.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(customer.name),
                    subtitle: Text(
                      '#${customer.billNumber} • ${customer.phone}',
                    ),
                    onTap: () => Navigator.pop(context, customer),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Extension for string capitalization
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
