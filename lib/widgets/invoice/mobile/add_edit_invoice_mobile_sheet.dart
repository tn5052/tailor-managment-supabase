import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/customer.dart';
import '../../../models/invoice_product.dart' as model_product;
import '../../../models/measurement.dart';
import 'customer_selector_sheet.dart';
import 'measurement_selector_sheet.dart';
import 'product_selector_sheet.dart';

class AddEditInvoiceMobileSheet extends StatefulWidget {
  final Map<String, dynamic>? invoice;
  final VoidCallback? onInvoiceSaved;

  const AddEditInvoiceMobileSheet({
    Key? key,
    this.invoice,
    this.onInvoiceSaved,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? invoice,
    VoidCallback? onInvoiceSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      useSafeArea: true,
      builder:
          (context) => AddEditInvoiceMobileSheet(
            invoice: invoice,
            onInvoiceSaved: onInvoiceSaved,
          ),
    );
  }

  @override
  State<AddEditInvoiceMobileSheet> createState() =>
      _AddEditInvoiceMobileSheetState();
}

class _AddEditInvoiceMobileSheetState extends State<AddEditInvoiceMobileSheet>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late AnimationController _sheetAnimationController;
  late Animation<double> _sheetAnimation;

  final _sheetFocusNode = FocusNode();

  // Form controllers
  final _invoiceNumberController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _deliveryDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  final _vatController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _advanceController = TextEditingController();
  final _balanceController = TextEditingController();

  // Form state
  Customer? _selectedCustomer;
  Measurement? _selectedMeasurement;
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedDeliveryDate = DateTime.now();
  String _paymentStatus = 'Paid';
  String _deliveryStatus = 'Delivered';
  String _discountType = 'none'; // 'none', 'percentage', 'fixed'
  final _discountValueController = TextEditingController();
  List<model_product.InvoiceProduct> _products = [];
  bool _isSaving = false;
  bool get _isEditMode => widget.invoice != null;
  double _keyboardHeight = 0;
  bool _showSubtotalDetails = false; // For collapsible subtotal/VAT

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupKeyboardListener();
    _setupForm();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sheetFocusNode.requestFocus();
      _sheetAnimationController.forward();
    });
  }

  void _initializeAnimations() {
    _sheetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
        });
      }
    });
  }

  void _setupForm() {
    if (_isEditMode) {
      final invoiceData = widget.invoice!;
      _invoiceNumberController.text = invoiceData['invoice_number'] ?? '';
      _customerNameController.text = invoiceData['customer_name'] ?? '';
      _customerPhoneController.text = invoiceData['customer_phone'] ?? '';
      
      // Parse dates properly
      _selectedDate = DateTime.tryParse(invoiceData['date'] ?? '') ?? DateTime.now();
      _selectedDeliveryDate = DateTime.tryParse(invoiceData['delivery_date'] ?? '') ?? DateTime.now();
      
      // Load status values
      _paymentStatus = invoiceData['payment_status'] ?? 'Unpaid';
      _deliveryStatus = invoiceData['delivery_status'] ?? 'Pending';
      
      // Load discount data
      _discountType = invoiceData['discount_type'] ?? 'none';
      _discountValueController.text = (invoiceData['discount_value'] as num?)?.toString() ?? '0';
      
      // Load notes - handle both string and array formats
      if (invoiceData['notes'] != null) {
        if (invoiceData['notes'] is List) {
          _notesController.text = (invoiceData['notes'] as List).join('\n');
        } else {
          _notesController.text = invoiceData['notes'].toString();
        }
      }
      
      // Load financial data
      _amountController.text = (invoiceData['amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
      _vatController.text = (invoiceData['vat'] as num?)?.toStringAsFixed(2) ?? '0.00';
      _totalAmountController.text = (invoiceData['amount_including_vat'] as num?)?.toStringAsFixed(2) ?? '0.00';
      _advanceController.text = (invoiceData['advance'] as num?)?.toStringAsFixed(2) ?? '0.00';
      _balanceController.text = (invoiceData['balance'] as num?)?.toStringAsFixed(2) ?? '0.00';
      
      // Load customer and measurement data
      _loadCustomerAndMeasurementData(invoiceData);
      
      // Load products data
      _loadProductsFromInvoice(invoiceData);
    } else {
      _generateInvoiceNumber();
    }
    
    // Format date controllers
    _dateController.text = DateFormat('MMM dd').format(_selectedDate);
    _deliveryDateController.text = DateFormat('MMM dd').format(_selectedDeliveryDate);

    // Add listeners to calculate totals
    _amountController.addListener(_calculateTotals);
    _advanceController.addListener(_calculateTotals);
    _discountValueController.addListener(_calculateTotals);
  }

  Future<void> _loadCustomerAndMeasurementData(Map<String, dynamic> invoiceData) async {
    // Load customer data if customer_id exists
    if (invoiceData['customer_id'] != null) {
      try {
        final response = await _supabase
            .from('customers')
            .select('*')
            .eq('id', invoiceData['customer_id'])
            .single();
        
        setState(() {
          _selectedCustomer = Customer.fromMap(response);
        });
      } catch (e) {
        // If customer not found, just skip - we'll use the name from invoice data
        print('Customer not found: $e');
      }
    }

    // Load measurement data if measurement_id exists
    if (invoiceData['measurement_id'] != null) {
      try {
        final response = await _supabase
            .from('measurements')
            .select('*')
            .eq('id', invoiceData['measurement_id'])
            .single();
        
        setState(() {
          _selectedMeasurement = Measurement.fromMap(response);
        });
      } catch (e) {
        // If measurement not found, just skip
        print('Measurement not found: $e');
      }
    }
  }

  void _loadProductsFromInvoice(Map<String, dynamic> invoiceData) {
    if (invoiceData['products'] != null && invoiceData['products'] is List) {
      try {
        setState(() {
          _products = (invoiceData['products'] as List).map((productData) {
            // Create InvoiceProduct using proper constructor
            return model_product.InvoiceProduct(
              id: productData['id'] ?? '',
              inventoryId: productData['inventory_id'] ?? '',
              name: productData['name'] ?? '',
              quantity: (productData['quantity'] as num?)?.toDouble() ?? 1.0,
              unit: productData['unit'] ?? 'pcs',
              unitPrice: (productData['unit_price'] as num?)?.toDouble() ?? 0.0,
              inventoryType: productData['inventory_type'] ?? 'product',
              description: productData['description'] ?? '',
            );
          }).toList();
        });
      } catch (e) {
        print('Error loading products: $e');
        setState(() {
          _products = [];
        });
      }
    }
  }

  Future<void> _generateInvoiceNumber() async {
    try {
      final response = await _supabase
          .from('invoices')
          .select('invoice_number')
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      final lastInvoiceNumber = response['invoice_number'] as String?;
      if (lastInvoiceNumber != null) {
        final number = int.tryParse(lastInvoiceNumber) ?? 0;
        _invoiceNumberController.text = (number + 1).toString().padLeft(4, '0');
      } else {
        _invoiceNumberController.text = '0001';
      }
    } catch (e) {
      _invoiceNumberController.text = '0001';
    }
  }

  Future<void> _loadProducts() async {
    // In a real app, you would fetch products associated with the invoice ID
    // For this example, we'll leave it empty.
  }

  void _calculateTotals() {
    double amount = _products.fold(0.0, (sum, item) => sum + item.totalPrice);
    double advance = double.tryParse(_advanceController.text) ?? 0.0;
    double discountValue = double.tryParse(_discountValueController.text) ?? 0.0;
    double discountAmount = 0.0;

    if (_discountType == 'percentage') {
      discountAmount = amount * (discountValue / 100);
    } else if (_discountType == 'fixed') {
      discountAmount = discountValue;
    }

    double netTotal = amount - discountAmount;
    if (netTotal < 0) netTotal = 0;

    double vatAmount = netTotal * 0.05;
    double amountIncludingVat = netTotal + vatAmount;
    double balance = amountIncludingVat - advance;

    // Auto-set advance if payment status is Paid
    if (_paymentStatus == 'Paid') {
      advance = amountIncludingVat;
      balance = 0;
      _advanceController.text = advance.toStringAsFixed(2);
    }

    setState(() {
      _amountController.text = amount.toStringAsFixed(2);
      _vatController.text = vatAmount.toStringAsFixed(2);
      _totalAmountController.text = amountIncludingVat.toStringAsFixed(2);
      _balanceController.text = balance.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _sheetAnimationController.dispose();
    _scrollController.dispose();
    _sheetFocusNode.dispose();
    _invoiceNumberController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _dateController.dispose();
    _deliveryDateController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    _vatController.dispose();
    _totalAmountController.dispose();
    _advanceController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    await _sheetAnimationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that at least one product is selected
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(PhosphorIcons.warning(), color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'At least one product is required to create an invoice',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: InventoryDesignConfig.warningColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate totals to ensure they're up to date
      _calculateTotals();

      final data = {
        'invoice_number': _invoiceNumberController.text.trim(),
        'date': _selectedDate.toIso8601String(),
        'delivery_date': _selectedDeliveryDate.toIso8601String(),
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'vat': 0.05, // Fixed VAT rate
        'amount_including_vat': double.tryParse(_totalAmountController.text) ?? 0.0,
        'net_total': double.tryParse(_totalAmountController.text) ?? 0.0,
        'advance': double.tryParse(_advanceController.text) ?? 0.0,
        'balance': double.tryParse(_balanceController.text) ?? 0.0,
        'customer_id': _selectedCustomer?.id,
        'customer_name': _selectedCustomer?.name ?? _customerNameController.text.trim(),
        'customer_phone': _selectedCustomer?.phone ?? '',
        'customer_bill_number': _selectedCustomer?.billNumber ?? '',
        'measurement_id': _selectedMeasurement?.id,
        'measurement_name': _selectedMeasurement?.style,
        'payment_status': _paymentStatus,
        'delivery_status': _deliveryStatus,
        'delivered_at': _deliveryStatus == 'Delivered' ? DateTime.now().toIso8601String() : null,
        'paid_at': _paymentStatus == 'Paid' ? DateTime.now().toIso8601String() : null,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim().split('\n'),
        'is_delivered': _deliveryStatus == 'Delivered',
        'products': _products.map((p) => {
          'name': p.name,
          'quantity': p.quantity,
          'unit': p.unit,
          'unit_price': p.unitPrice,
          'total_price': p.totalPrice,
          'inventory_type': p.inventoryType,
          'description': p.description,
        }).toList(),
        'discount_type': _discountType,
        'discount_value': double.tryParse(_discountValueController.text) ?? 0.0,
        'discount_amount': _calculateDiscountAmount(),
        'payments': [], // Empty payments array for new invoices
        'tenant_id': userId,
      };

      if (_isEditMode) {
        data['last_modified_at'] = DateTime.now().toIso8601String();
        data['last_modified_reason'] = 'Edited via mobile app';
        await _supabase.from('invoices').update(data).eq('id', widget.invoice!['id']);
      } else {
        data['id'] = const Uuid().v4(); // Generate new UUID for new invoice
        await _supabase.from('invoices').insert(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(PhosphorIcons.checkCircle(), color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Invoice ${data['invoice_number']} ${_isEditMode ? 'updated' : 'created'} successfully!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: InventoryDesignConfig.successColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onInvoiceSaved?.call();
        _handleClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(PhosphorIcons.warning(), color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error saving invoice: ${e.toString()}',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: InventoryDesignConfig.errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  double _calculateDiscountAmount() {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double discountValue = double.tryParse(_discountValueController.text) ?? 0.0;
    if (_discountType == 'percentage') {
      return amount * (discountValue / 100);
    } else if (_discountType == 'fixed') {
      return discountValue;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final safeAreaTop = mediaQuery.padding.top;

    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.4 * _sheetAnimation.value),
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: safeAreaTop + 40,
                  bottom: 0,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (screenHeight - safeAreaTop - 40) * (1 - _sheetAnimation.value),
                    ),
                    child: _buildSheetContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetContent() {
    return Container(
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Focus(
        focusNode: _sheetFocusNode,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildFormContent()),
            _buildActionButtons(),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingS,
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingL,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                        border: Border.all(
                          color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        _isEditMode ? PhosphorIcons.pencilSimple() : PhosphorIcons.plus(),
                        color: InventoryDesignConfig.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingL),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditMode ? 'Edit Invoice' : 'Create Invoice',
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
                    _buildHeaderActionButton(
                      icon: PhosphorIcons.x(),
                      onTap: _handleClose,
                      semanticLabel: 'Close form',
                    ),
                  ],
                ),
                // Compact Invoice Number Badge
                const SizedBox(height: InventoryDesignConfig.spacingM),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: InventoryDesignConfig.spacingM,
                        vertical: InventoryDesignConfig.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                        border: Border.all(
                          color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.hash(),
                            color: InventoryDesignConfig.primaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _invoiceNumberController.text.isEmpty 
                              ? 'Generating...' 
                              : _invoiceNumberController.text,
                            style: InventoryDesignConfig.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: InventoryDesignConfig.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
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
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
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

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          InventoryDesignConfig.spacingXL,
          InventoryDesignConfig.spacingXL,
          InventoryDesignConfig.spacingXL,
          InventoryDesignConfig.spacingXL + _keyboardHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSection(
              title: 'Invoice Dates',
              icon: PhosphorIcons.calendar(),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDateField(
                        label: 'Invoice Date',
                        controller: _dateController,
                        color: InventoryDesignConfig.primaryColor,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                            _dateController.text = DateFormat('MMM dd').format(date);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Expanded(
                      child: _buildCompactDateField(
                        label: 'Delivery Date',
                        controller: _deliveryDateController,
                        color: InventoryDesignConfig.successColor,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDeliveryDate = date;
                            _deliveryDateController.text = DateFormat('MMM dd').format(date);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
            _buildFormSection(
              title: 'Customer Details',
              icon: PhosphorIcons.user(),
              children: [
                _buildSelectorField(
                  label: 'Customer Name',
                  value: _selectedCustomer?.name,
                  onTap: _openCustomerSelector,
                  validator: (val) =>
                      _selectedCustomer == null ? 'Please select a customer' : null,
                  prefixIcon: PhosphorIcons.user(),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingL),
                _buildSelectorField(
                  label: 'Measurement',
                  value: _selectedMeasurement?.style,
                  onTap: _openMeasurementSelector,
                  prefixIcon: PhosphorIcons.ruler(),
                ),
              ],
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
            _buildFormSection(
              title: 'Products',
              icon: PhosphorIcons.shoppingBag(),
              children: [
                _buildProductList(),
                const SizedBox(height: InventoryDesignConfig.spacingL),
                _buildAddProductButton(),
              ],
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
            _buildFormSection(
              title: 'Payment',
              icon: PhosphorIcons.currencyDollar(),
              children: [
                // Discount section - always visible
                _buildDiscountSection(),
                
                // Advance payment - only if not paid
                if (_paymentStatus != 'Paid') ...[
                  const SizedBox(height: InventoryDesignConfig.spacingL),
                  _buildTextFormField(
                    label: 'Advance Payment',
                    controller: _advanceController,
                    prefixIcon: PhosphorIcons.handCoins(),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _calculateTotals(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
             _buildFormSection(
              title: 'Status',
              icon: PhosphorIcons.toggleLeft(),
              children: [
                _buildDropdownField(
                  label: 'Payment Status',
                  value: _paymentStatus,
                  items: ['Unpaid', 'Paid', 'Partially Paid'],
                  onChanged: (val) => setState(() => _paymentStatus = val ?? 'Unpaid'),
                  prefixIcon: PhosphorIcons.creditCard(),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingL),
                _buildDropdownField(
                  label: 'Delivery Status',
                  value: _deliveryStatus,
                  items: ['Pending', 'Processing', 'Delivered', 'Cancelled'],
                  onChanged: (val) => setState(() => _deliveryStatus = val ?? 'Pending'),
                  prefixIcon: PhosphorIcons.package(),
                ),
              ],
            ),
          ],
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
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
              ),
              child: Icon(icon, size: 16, color: InventoryDesignConfig.primaryColor),
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

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discount',
          style: InventoryDesignConfig.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: InventoryDesignConfig.textPrimary,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Row(
          children: [
            _buildDiscountTypeButton('none', 'None'),
            const SizedBox(width: 8),
            _buildDiscountTypeButton('percentage', '%'),
            const SizedBox(width: 8),
            _buildDiscountTypeButton('fixed', 'AED'),
          ],
        ),
        if (_discountType != 'none') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _discountValueController,
            keyboardType: TextInputType.number,
            onChanged: (val) => _calculateTotals(),
            style: InventoryDesignConfig.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Discount Value (${_discountType == 'percentage' ? '%' : 'AED'})',
              filled: true,
              fillColor: InventoryDesignConfig.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                borderSide: BorderSide(color: InventoryDesignConfig.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                borderSide: BorderSide(color: InventoryDesignConfig.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                borderSide: BorderSide(color: InventoryDesignConfig.primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiscountTypeButton(String type, String label) {
    final isSelected = _discountType == type;
    return Expanded(
      child: Material(
        color: isSelected
            ? InventoryDesignConfig.primaryColor
            : InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        child: InkWell(
          onTap: () {
            setState(() {
              _discountType = type;
              if (type == 'none') {
                _discountValueController.text = '0';
              }
            });
            _calculateTotals();
          },
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
              border: Border.all(
                color: isSelected
                    ? InventoryDesignConfig.primaryColor
                    : InventoryDesignConfig.borderPrimary,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : InventoryDesignConfig.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
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
          validator: validator,
          readOnly: readOnly,
          style: InventoryDesignConfig.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                    child: Icon(
                      prefixIcon,
                      size: 18,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  )
                : null,
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              borderSide: BorderSide(color: InventoryDesignConfig.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              borderSide: BorderSide(color: InventoryDesignConfig.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              borderSide: BorderSide(color: InventoryDesignConfig.primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDateField({
    required String label,
    required TextEditingController controller,
    required Color color,
    required Function(DateTime) onDateSelected,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (picked != null) {
            onDateSelected(picked);
          }
        },
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.calendar(),
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty 
                        ? DateFormat('MMM dd').format(DateTime.now())
                        : controller.text,
                      style: InventoryDesignConfig.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required TextEditingController controller,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
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
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select Date',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
              child: Icon(
                PhosphorIcons.calendar(),
                size: 18,
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              borderSide: BorderSide(color: InventoryDesignConfig.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              borderSide: BorderSide(color: InventoryDesignConfig.borderPrimary),
            ),
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData prefixIcon,
  }) {
    return Column(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(PhosphorIcons.caretDown(), color: InventoryDesignConfig.textSecondary),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: InventoryDesignConfig.bodyLarge),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact Financial Summary
        _buildCompactFinancialSummary(),
        
        // Action Buttons
        Container(
          padding: EdgeInsets.fromLTRB(
            InventoryDesignConfig.spacingXL,
            InventoryDesignConfig.spacingL,
            InventoryDesignConfig.spacingXL,
            InventoryDesignConfig.spacingL + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
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
                  label: _isSaving ? 'Saving...' : 'Save Invoice',
                  icon: _isSaving ? null : PhosphorIcons.check(),
                  color: Colors.white,
                  backgroundColor: InventoryDesignConfig.primaryColor,
                  onTap: _isSaving ? null : _handleSave,
                  loading: _isSaving,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddProductButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          ProductSelectorSheet.show(
            context,
            initialProducts: _products,
            onProductsSelected: (selected) {
              setState(() {
                _products = selected;
                _calculateTotals();
              });
            },
          );
        },
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.3),
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.plus(),
                color: InventoryDesignConfig.primaryColor,
                size: 20,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Text(
                _products.isEmpty ? 'Add Products' : 'Add More Products',
                style: InventoryDesignConfig.bodyLarge.copyWith(
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

  Widget _buildProductList() {
    if (_products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
        decoration: BoxDecoration(
          color: InventoryDesignConfig.surfaceAccent,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          border: Border.all(
            color: InventoryDesignConfig.borderSecondary,
          ),
        ),
        child: Column(
          children: [
            Icon(
              PhosphorIcons.shoppingBag(),
              size: 48,
              color: InventoryDesignConfig.textTertiary,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingM),
            Text(
              'No products added',
              style: InventoryDesignConfig.titleMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              'Tap "Add Product" to get started',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: _products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        
        return Container(
          margin: EdgeInsets.only(
            bottom: index == _products.length - 1 ? 0 : InventoryDesignConfig.spacingS,
          ),
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color: InventoryDesignConfig.borderSecondary,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _parseProductColor(product.description),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: InventoryDesignConfig.borderPrimary,
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  product.inventoryType == 'fabric' 
                      ? PhosphorIcons.scissors()
                      : PhosphorIcons.package(),
                  color: Colors.white,
                  size: 14,
                ),
              ),
              
              const SizedBox(width: InventoryDesignConfig.spacingM),
              
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.quantity.toStringAsFixed(product.quantity.truncateToDouble() == product.quantity ? 0 : 1)} ${product.unit} × AED ${NumberFormat('#,##0').format(product.unitPrice)}',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Quantity controls (vertical)
              Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          product.quantity++;
                          _calculateTotals();
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 24,
                        height: 18,
                        decoration: BoxDecoration(
                          color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          PhosphorIcons.plus(),
                          size: 10,
                          color: InventoryDesignConfig.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.quantity.toInt().toString(),
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (product.quantity > 1) {
                            product.quantity--;
                          } else {
                            _products.removeAt(index);
                          }
                          _calculateTotals();
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 24,
                        height: 18,
                        decoration: BoxDecoration(
                          color: InventoryDesignConfig.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          PhosphorIcons.minus(),
                          size: 10,
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: InventoryDesignConfig.spacingM),
              
              // Price and delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'AED ${NumberFormat('#,##0').format(product.totalPrice)}',
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: InventoryDesignConfig.successColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _products.removeAt(index);
                          _calculateTotals();
                        });
                      },
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          PhosphorIcons.trash(),
                          size: 12,
                          color: InventoryDesignConfig.errorColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantityControl({
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required int quantity,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onDecrement();
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  PhosphorIcons.minus(),
                  size: 14,
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              quantity.toString(),
              style: InventoryDesignConfig.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onIncrement();
              },
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  PhosphorIcons.plus(),
                  size: 14,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseProductColor(String? colorCode) {
    if (colorCode == null || colorCode.isEmpty) {
      return InventoryDesignConfig.primaryColor;
    }
    
    try {
      if (colorCode.startsWith('#')) {
        String hex = colorCode.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        }
      }
      
      // Map common color names to more vibrant colors
      switch (colorCode.toLowerCase()) {
        case 'red':
          return const Color(0xFFE53E3E);
        case 'blue':
          return const Color(0xFF3182CE);
        case 'green':
          return const Color(0xFF38A169);
        case 'yellow':
          return const Color(0xFFD69E2E);
        case 'black':
          return const Color(0xFF2D3748);
        case 'white':
          return const Color(0xFFF7FAFC);
        case 'purple':
          return const Color(0xFF805AD5);
        case 'pink':
          return const Color(0xFFED64A6);
        case 'orange':
          return const Color(0xFFDD6B20);
        case 'brown':
          return const Color(0xFF8B4513);
        case 'grey':
        case 'gray':
          return const Color(0xFF718096);
        case 'navy':
          return const Color(0xFF2C5282);
        case 'teal':
          return const Color(0xFF319795);
        case 'lime':
          return const Color(0xFF68D391);
        case 'cyan':
          return const Color(0xFF0BC5EA);
        case 'amber':
          return const Color(0xFFF6AD55);
        default:
          return InventoryDesignConfig.primaryColor;
      }
    } catch (e) {
      return InventoryDesignConfig.primaryColor;
    }
  }

  void _openCustomerSelector() {
    CustomerSelectorSheet.show(
      context,
      onCustomerSelected: (customer) {
        setState(() {
          _selectedCustomer = customer;
          _customerNameController.text = customer.name;
          _customerPhoneController.text = customer.phone;
          _selectedMeasurement = null;
        });
      },
    );
  }

  void _openMeasurementSelector() {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    MeasurementSelectorSheet.show(
      context,
      customerId: _selectedCustomer!.id,
      onMeasurementSelected: (measurement) {
        setState(() {
          _selectedMeasurement = measurement;
        });
      },
    );
  }

  Widget _buildSelectorField({
    required String label,
    String? value,
    required VoidCallback onTap,
    String? Function(String?)? validator,
    required IconData prefixIcon,
  }) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> state) {
        return Column(
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
                      color: state.hasError
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
            if (state.hasError) ...[
              const SizedBox(height: InventoryDesignConfig.spacingXS),
              Text(
                state.errorText!,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.errorColor,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCompactFinancialSummary() {
    final subtotal = double.tryParse(_amountController.text) ?? 0.0;
    final total = double.tryParse(_totalAmountController.text) ?? 0.0;
    final advance = double.tryParse(_advanceController.text) ?? 0.0;
    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final vat = double.tryParse(_vatController.text) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Main total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Total:',
                    style: InventoryDesignConfig.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: InventoryDesignConfig.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Collapsible details button
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showSubtotalDetails = !_showSubtotalDetails;
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _showSubtotalDetails 
                            ? PhosphorIcons.caretUp() 
                            : PhosphorIcons.info(),
                          size: 14,
                          color: InventoryDesignConfig.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'AED ${NumberFormat('#,##0').format(total)}',
                style: InventoryDesignConfig.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
            ],
          ),
          
          // Collapsible details
          if (_showSubtotalDetails) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: InventoryDesignConfig.borderSecondary,
                ),
              ),
              child: Column(
                children: [
                  _buildFinancialRow('Subtotal', subtotal),
                  if (vat > 0) _buildFinancialRow('VAT (5%)', vat),
                  const Divider(height: 16),
                  _buildFinancialRow('Total', total, isTotal: true),
                ],
              ),
            ),
          ],
          
          // Payment info for unpaid invoices
          if (_paymentStatus != 'Paid' && advance > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: balance > 0 
                  ? InventoryDesignConfig.warningColor.withOpacity(0.1)
                  : InventoryDesignConfig.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: balance > 0 
                    ? InventoryDesignConfig.warningColor.withOpacity(0.3)
                    : InventoryDesignConfig.successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advance: AED ${NumberFormat('#,##0').format(advance)}',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due: AED ${NumberFormat('#,##0').format(balance)}',
                        style: InventoryDesignConfig.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: balance > 0 
                            ? InventoryDesignConfig.warningColor
                            : InventoryDesignConfig.successColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: balance > 0 
                        ? InventoryDesignConfig.warningColor
                        : InventoryDesignConfig.successColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      balance > 0 ? 'Pending' : 'Settled',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.bodyMedium.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal 
              ? InventoryDesignConfig.textPrimary
              : InventoryDesignConfig.textSecondary,
          ),
        ),
        Text(
          'AED ${NumberFormat('#,##0').format(amount)}',
          style: InventoryDesignConfig.bodyMedium.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal 
              ? InventoryDesignConfig.primaryColor
              : InventoryDesignConfig.textPrimary,
          ),
        ),
      ],
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onTap != null && !loading ? () {
          HapticFeedback.mediumImpact();
          onTap();
        } : null,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: InventoryDesignConfig.spacingL,
            horizontal: InventoryDesignConfig.spacingM,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color: backgroundColor == InventoryDesignConfig.surfaceLight
                  ? InventoryDesignConfig.borderPrimary
                  : backgroundColor,
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
    );
  }
}
