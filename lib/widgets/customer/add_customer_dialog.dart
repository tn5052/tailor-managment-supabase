import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import 'customer_selector_dialog.dart';
import '../inventory/inventory_design_config.dart';

class AddCustomerDialog extends StatefulWidget {
  final Customer? customer;
  final int? index;
  final bool isEditing;
  final VoidCallback? onCustomerAdded;

  const AddCustomerDialog({
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
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AddCustomerDialog(
            customer: customer,
            index: index,
            isEditing: isEditing,
            onCustomerAdded: onCustomerAdded,
          ),
    );
  }

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  final _billNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();

  late Gender _selectedGender;
  bool _useCustomBillNumber = false;
  Customer? _referredBy;
  Customer? _familyMember;
  FamilyRelation? _familyRelation;
  bool _isSaving = false;

  List<Customer> _referredCustomers = [];
  List<Customer> _familyMembers = [];

  final String _draftKey = "add_customer_dialog_draft";

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
    _initializeData();
    _setupFormListeners();
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

      _loadReferredCustomers(customer.id);
      _loadFamilyMembers(customer.id);
    } else {
      _selectedGender = Gender.male;
      _generateBillNumber();
      _loadDraft();
    }
  }

  void _setupFormListeners() {
    if (!widget.isEditing) {
      final controllers = [
        _billNumberController,
        _nameController,
        _phoneController,
        _whatsappController,
        _addressController,
      ];
      for (var controller in controllers) {
        controller.addListener(_saveDraft);
      }
    }

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

  @override
  void dispose() {
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

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftData = {
      "billNumber": _billNumberController.text,
      "name": _nameController.text,
      "phone": _phoneController.text,
      "whatsapp": _whatsappController.text,
      "address": _addressController.text,
      "selectedGender": _selectedGender.toString(),
    };
    prefs.setString(_draftKey, jsonEncode(draftData));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_draftKey)) {
      final draftData = jsonDecode(prefs.getString(_draftKey)!);
      setState(() {
        _billNumberController.text = draftData["billNumber"] ?? "";
        _nameController.text = draftData["name"] ?? "";
        _phoneController.text = draftData["phone"] ?? "";
        _whatsappController.text = draftData["whatsapp"] ?? "";
        _addressController.text = draftData["address"] ?? "";
      });
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_draftKey);
  }

  Future<void> _loadReferringCustomer(String referredById) async {
    try {
      final customer = await _supabaseService.getCustomerById(referredById);
      if (customer != null && mounted) {
        setState(() => _referredBy = customer);
      }
    } catch (e) {
      debugPrint('Error loading referring customer: $e');
    }
  }

  Future<void> _loadFamilyMember(String familyId) async {
    try {
      final member = await _supabaseService.getCustomerById(familyId);
      if (member != null && mounted) {
        setState(() => _familyMember = member);
      }
    } catch (e) {
      debugPrint('Error loading family member: $e');
    }
  }

  Future<void> _loadReferredCustomers(String customerId) async {
    try {
      final customers = await _supabaseService.getReferredCustomers(customerId);
      setState(() => _referredCustomers = customers);
    } catch (e) {
      debugPrint('Error loading referred customers: $e');
    }
  }

  Future<void> _loadFamilyMembers(String customerId) async {
    try {
      final familyMembers = await _supabaseService.getFamilyMembers(customerId);
      setState(() => _familyMembers = familyMembers);
    } catch (e) {
      debugPrint('Error loading family members: $e');
    }
  }

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

  bool _isFormValid() {
    return _formKey.currentState?.validate() ?? false;
  }

  Future<Customer?> _saveCustomer({bool showSnackbar = true}) async {
    if (!_formKey.currentState!.validate()) return null;

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
        await _clearDraft();
      }

      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? '${customer.name} updated successfully'
                  : '${customer.name} added successfully',
            ),
            backgroundColor: InventoryDesignConfig.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return customer;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleSave() async {
    final customer = await _saveCustomer();
    if (customer != null && mounted) {
      widget.onCustomerAdded?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.9;

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
              _buildHeader(),
              Flexible(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              widget.isEditing
                  ? PhosphorIcons.pencilSimple()
                  : PhosphorIcons.userPlus(),
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
                  widget.isEditing ? 'Edit Customer' : 'Add New Customer',
                  style: InventoryDesignConfig.headlineMedium,
                ),
                Text(
                  widget.isEditing
                      ? 'Update customer information'
                      : 'Create a new customer profile',
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Number Section (only for new customers)
            if (!widget.isEditing) ...[
              _buildSection('Bill Number', PhosphorIcons.receipt(), [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _billNumberController,
                        label: 'Bill Number',
                        hint:
                            _useCustomBillNumber
                                ? 'Enter custom bill number'
                                : 'Auto-generated',
                        icon: PhosphorIcons.receipt(),
                        enabled: _useCustomBillNumber,
                        validator: _validateBillNumber,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
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
              ]),
              const SizedBox(height: InventoryDesignConfig.spacingXXL),
            ],

            // Basic Information Section
            _buildSection('Basic Information', PhosphorIcons.user(), [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter customer full name',
                      icon: PhosphorIcons.user(),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Name is required'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: InventoryDesignConfig.spacingL),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      icon: PhosphorIcons.phone(),
                      keyboardType: TextInputType.phone,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Phone is required'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingL),
                  Expanded(
                    child: _buildTextField(
                      controller: _whatsappController,
                      label: 'WhatsApp (Optional)',
                      hint: 'WhatsApp number',
                      icon: PhosphorIcons.whatsappLogo(),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: InventoryDesignConfig.spacingL),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter full address',
                      icon: PhosphorIcons.mapPin(),
                      maxLines: 2,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Address is required'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: InventoryDesignConfig.spacingL),
              _buildGenderSelector(),
            ]),

            const SizedBox(height: InventoryDesignConfig.spacingXXL),

            // Referral & Family Section
            _buildSection('Referral & Family', PhosphorIcons.users(), [
              _buildReferralSelector(),
              const SizedBox(height: InventoryDesignConfig.spacingL),
              _buildFamilySelector(),
            ]),

            // Show referred customers and family members for existing customers
            if (widget.isEditing) ...[
              const SizedBox(height: InventoryDesignConfig.spacingXXL),
              _buildRelationshipsSection(),
            ],
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
              onTap: _isSaving ? null : () => Navigator.of(context).pop(),
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
              onTap: _isSaving ? null : _handleSave,
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
                    if (_isSaving)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        widget.isEditing
                            ? PhosphorIcons.check()
                            : PhosphorIcons.userPlus(),
                        size: 16,
                        color: Colors.white,
                      ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      _isSaving
                          ? 'Saving...'
                          : (widget.isEditing
                              ? 'Update Customer'
                              : 'Add Customer'),
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
    bool enabled = true,
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
          enabled: enabled,
          style: InventoryDesignConfig.bodyLarge.copyWith(
            color:
                enabled
                    ? InventoryDesignConfig.textPrimary
                    : InventoryDesignConfig.textTertiary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color:
                  enabled
                      ? InventoryDesignConfig.textSecondary
                      : InventoryDesignConfig.textTertiary,
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
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
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
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _selectedGender = gender),
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusM,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(
                            InventoryDesignConfig.spacingL,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? InventoryDesignConfig.primaryColor
                                        .withOpacity(0.1)
                                    : InventoryDesignConfig.surfaceLight,
                            borderRadius: BorderRadius.circular(
                              InventoryDesignConfig.radiusM,
                            ),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? InventoryDesignConfig.primaryColor
                                      : InventoryDesignConfig.borderPrimary,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.user(),
                                color:
                                    isSelected
                                        ? InventoryDesignConfig.primaryColor
                                        : InventoryDesignConfig.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(
                                width: InventoryDesignConfig.spacingS,
                              ),
                              Text(
                                gender.name.toUpperCase(),
                                style: InventoryDesignConfig.bodyMedium
                                    .copyWith(
                                      color:
                                          isSelected
                                              ? InventoryDesignConfig
                                                  .primaryColor
                                              : InventoryDesignConfig
                                                  .textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
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

  Widget _buildReferralSelector() {
    return Column(
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
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _selectReferringCustomer,
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
                    color: InventoryDesignConfig.borderPrimary,
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
    );
  }

  Widget _buildFamilySelector() {
    return Column(
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
                if (_familyMember != null) ...[
                  const SizedBox(height: InventoryDesignConfig.spacingM),
                  _buildFamilyRelationSelector(),
                ],
              ],
            ),
          ),
        ] else ...[
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _selectFamilyMember,
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
                    color: InventoryDesignConfig.borderPrimary,
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
                    onTap: () => setState(() => _familyRelation = relation),
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

  Widget _buildRelationshipsSection() {
    if (_referredCustomers.isEmpty && _familyMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection('Relationships', PhosphorIcons.network(), [
      if (_referredCustomers.isNotEmpty) ...[
        _buildRelationshipSubsection(
          'Referred Customers',
          PhosphorIcons.userPlus(),
          _referredCustomers,
        ),
        if (_familyMembers.isNotEmpty)
          const SizedBox(height: InventoryDesignConfig.spacingL),
      ],
      if (_familyMembers.isNotEmpty)
        _buildRelationshipSubsection(
          'Family Members',
          PhosphorIcons.users(),
          _familyMembers,
        ),
    ]);
  }

  Widget _buildRelationshipSubsection(
    String title,
    IconData icon,
    List<Customer> customers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: InventoryDesignConfig.primaryColor),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Text(
              '$title (${customers.length})',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: InventoryDesignConfig.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: customers.length,
            separatorBuilder:
                (context, index) =>
                    const SizedBox(height: InventoryDesignConfig.spacingS),
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceLight,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                  border: Border.all(
                    color: InventoryDesignConfig.borderPrimary,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: InventoryDesignConfig.primaryColor
                          .withOpacity(0.1),
                      child: Text(
                        customer.name[0].toUpperCase(),
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '#${customer.billNumber}',
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color: InventoryDesignConfig.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (customer.familyRelation != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: InventoryDesignConfig.spacingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: InventoryDesignConfig.successColor.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusS,
                          ),
                        ),
                        child: Text(
                          customer.familyRelation!.name.toUpperCase(),
                          style: InventoryDesignConfig.bodySmall.copyWith(
                            color: InventoryDesignConfig.successColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectReferringCustomer() async {
    try {
      final customers = await _supabaseService.getAllCustomers();
      if (!mounted) return;

      final customer = await CustomerSelectorDialog.show(context, customers);
      if (customer != null) {
        setState(() => _referredBy = customer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customers: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectFamilyMember() async {
    try {
      final customers = await _supabaseService.getAllCustomers();
      if (!mounted) return;

      final customer = await CustomerSelectorDialog.show(context, customers);
      if (customer != null) {
        setState(() {
          _familyMember = customer;
          _familyRelation = FamilyRelation.other; // Default relation
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customers: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
