import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../models/customer.dart';
import '../../../models/measurement.dart';
import '../../../models/invoice.dart';
import '../../../models/invoice_product.dart';
import '../../../services/customer_service.dart';
import '../../../services/invoice_service.dart';
import '../../../theme/inventory_design_config.dart';
import '../../customer/desktop/customer_selector_dialog.dart';
import 'measurement_selector_dialog.dart';
import 'inventory_item_selector_dialog.dart' as inventory_item;

class AddInvoiceDesktopDialog extends StatefulWidget {
  final Invoice? invoice;
  final VoidCallback? onInvoiceAdded;

  const AddInvoiceDesktopDialog({
    super.key,
    this.invoice,
    this.onInvoiceAdded,
  });

  static Future<Invoice?> show(
    BuildContext context, {
    Invoice? invoice,
    VoidCallback? onInvoiceAdded,
  }) {
    return showDialog<Invoice?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddInvoiceDesktopDialog(
        invoice: invoice,
        onInvoiceAdded: onInvoiceAdded,
      ),
    );
  }

  @override
  State<AddInvoiceDesktopDialog> createState() =>
      _AddInvoiceDesktopDialogState();
}

class _AddInvoiceDesktopDialogState extends State<AddInvoiceDesktopDialog> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceService = InvoiceService();
  final _customerService = SupabaseService();

  // State Management
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showValidationErrors = false;
  String? _validationError;
  
  // Customer & Measurement Data
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  Measurement? _selectedMeasurement;
  
  // Product Management
  final List<InvoiceProduct> _selectedProducts = [];
  
  // Form Controllers
  final _invoiceNumberController = TextEditingController();
  final _detailsController = TextEditingController();
  final _vatController = TextEditingController(text: '5');
  final _advanceController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  
  // Notes Management
  final List<String> _notes = [];
  final _newNoteController = TextEditingController();
  
  // Payment Management
  final List<Payment> _payments = [];
  final _paymentAmountController = TextEditingController();
  final _paymentNoteController = TextEditingController();
  
  // Date Management
  DateTime _invoiceDate = DateTime.now();
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _estimatedFittingDate;
  
  // Status Management
  String _deliveryStatus = 'pending';
  String _paymentStatus = 'unpaid';
  String _priority = 'normal'; // normal, urgent, rush
  
  // Financial Calculations
  double _subtotal = 0;
  double _vatAmount = 0;
  double _netTotal = 0;
  double _balance = 0;
  double _totalPaid = 0;
  
  // Business Rules
  final double _minAdvancePercentage = 30.0; // Minimum 30% advance
  final int _maxDeliveryDays = 30; // Maximum 30 days for delivery
  final double _maxVatRate = 15.0; // Maximum VAT rate
  
  bool get _isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupListeners();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _setupListeners() {
    _vatController.addListener(_calculateTotals);
    _advanceController.addListener(_calculateTotals);
    _paymentAmountController.addListener(_validatePaymentAmount);
  }

  void _disposeControllers() {
    _invoiceNumberController.dispose();
    _detailsController.dispose();
    _vatController.dispose();
    _advanceController.dispose();
    _specialInstructionsController.dispose();
    _newNoteController.dispose();
    _paymentAmountController.dispose();
    _paymentNoteController.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);
      
      final customers = await _customerService.getAllCustomers();
      String invoiceNumber;
      
      if (_isEditing) {
        invoiceNumber = widget.invoice!.invoiceNumber;
        await _populateEditData();
      } else {
        invoiceNumber = await _invoiceService.generateInvoiceNumber();
      }

      if (mounted) {
        setState(() {
          _customers = customers;
          _invoiceNumberController.text = invoiceNumber;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Error loading data: $e');
      }
    }
  }

  Future<void> _populateEditData() async {
    final invoice = widget.invoice!;
    
    // Basic Information
    _detailsController.text = invoice.details ;
    _specialInstructionsController.text = invoice.details ;
    _vatController.text = ((invoice.vat / invoice.amount) * 100).toStringAsFixed(1);
    _advanceController.text = invoice.advance.toString();
    
    // Dates
    _invoiceDate = invoice.date;
    _deliveryDate = invoice.deliveryDate;
    
    // Status
    _deliveryStatus = _enumValueToSnakeCase(invoice.deliveryStatus.name);
    _paymentStatus = invoice.paymentStatus.name;
    
    // Notes and Payments
    _notes.addAll(invoice.notes);
    _payments.addAll(invoice.payments);
    
    // Find customer
    _selectedCustomer = _customers.firstWhere(
      (c) => c.id == invoice.customerId,
      orElse: () => Customer(
        id: invoice.customerId,
        billNumber: invoice.customerBillNumber,
        name: invoice.customerName,
        phone: invoice.customerPhone,
        whatsapp: '',
        address: '',
        gender: Gender.male,
      ),
    );
    
    // Convert products
    _selectedProducts.addAll(
      invoice.products.map((product) => InvoiceProduct(
        id: const Uuid().v4(),
        name: product.name,
        description: 'Invoice product',
        unitPrice: product.price,
        quantity: 1.0,
        unit: 'pcs',
      )),
    );
    
    _calculateTotals();
  }

  String _enumValueToSnakeCase(String value) {
    if (value == 'inProgress') return 'in_progress';
    return value.toLowerCase();
  }

  void _calculateTotals() {
    _subtotal = _selectedProducts.fold(
      0.0,
      (sum, product) => sum + product.totalPrice,
    );

    final vatRate = double.tryParse(_vatController.text) ?? 0;
    _vatAmount = _subtotal * (vatRate / 100);
    _netTotal = _subtotal + _vatAmount;

    _totalPaid = _payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final advance = double.tryParse(_advanceController.text) ?? 0;
    _balance = _netTotal - _totalPaid - advance;

    setState(() {});
  }

  bool _validateBusinessRules() {
    // Reset validation
    _validationError = null;
    
    // Check customer selection
    if (_selectedCustomer == null) {
      _validationError = 'Please select a customer';
      return false;
    }
    
    // Check products
    if (_selectedProducts.isEmpty) {
      _validationError = 'Please add at least one product or service';
      return false;
    }
    
    // Check delivery date
    final daysDifference = _deliveryDate.difference(_invoiceDate).inDays;
    if (daysDifference > _maxDeliveryDays) {
      _validationError = 'Delivery date cannot be more than $_maxDeliveryDays days from invoice date';
      return false;
    }
    
    if (_deliveryDate.isBefore(_invoiceDate)) {
      _validationError = 'Delivery date cannot be before invoice date';
      return false;
    }
    
    // Check VAT rate
    final vatRate = double.tryParse(_vatController.text) ?? 0;
    if (vatRate > _maxVatRate) {
      _validationError = 'VAT rate cannot exceed $_maxVatRate%';
      return false;
    }
    
    // Check minimum advance for new invoices
    if (!_isEditing && _paymentStatus != 'paid') {
      final advance = double.tryParse(_advanceController.text) ?? 0;
      final minAdvance = (_netTotal * _minAdvancePercentage) / 100;
      if (advance < minAdvance) {
        _validationError = 'Minimum advance required: ${_minAdvancePercentage.toInt()}% (AED ${minAdvance.toStringAsFixed(2)})';
        return false;
      }
    }
    
    // Check if total paid exceeds invoice total
    if (_totalPaid + (double.tryParse(_advanceController.text) ?? 0) > _netTotal) {
      _validationError = 'Total payments cannot exceed invoice amount';
      return false;
    }
    
    return true;
  }

  void _validatePaymentAmount() {
    final amount = double.tryParse(_paymentAmountController.text) ?? 0;
    final remaining = _balance + (double.tryParse(_advanceController.text) ?? 0);
    
    if (amount > remaining) {
      setState(() {
        _validationError = 'Payment amount cannot exceed remaining balance (AED ${remaining.toStringAsFixed(2)})';
      });
    } else {
      setState(() {
        _validationError = null;
      });
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _showValidationErrors = true);
      return;
    }
    
    if (!_validateBusinessRules()) {
      setState(() => _showValidationErrors = true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Prepare products
      final products = _selectedProducts
          .map((invoiceProduct) => Product(
                name: invoiceProduct.name,
                price: invoiceProduct.unitPrice * invoiceProduct.quantity,
              ))
          .toList();

      // Calculate payment status
      final advance = double.tryParse(_advanceController.text) ?? 0;
      final totalPayments = _totalPaid + advance;
      PaymentStatus paymentStatus;
      
      if (totalPayments >= _netTotal) {
        paymentStatus = PaymentStatus.paid;
      } else if (totalPayments > 0) {
        paymentStatus = PaymentStatus.partial;
      } else {
        paymentStatus = PaymentStatus.unpaid;
      }

      // Create invoice
      final invoice = Invoice(
        id: _isEditing ? widget.invoice!.id : const Uuid().v4(),
        invoiceNumber: _invoiceNumberController.text,
        date: _invoiceDate,
        deliveryDate: _deliveryDate,
        amount: _subtotal,
        vat: _vatAmount,
        amountIncludingVat: _netTotal,
        netTotal: _netTotal,
        advance: advance,
        balance: _balance,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        customerPhone: _selectedCustomer!.phone,
        details: _detailsController.text,
        customerBillNumber: _selectedCustomer!.billNumber,
        measurementId: _selectedMeasurement?.id,
        measurementName: _selectedMeasurement?.style,
        deliveryStatus: InvoiceStatus.values.firstWhere(
          (status) => _enumValueToSnakeCase(status.name) == _deliveryStatus,
          orElse: () => InvoiceStatus.pending,
        ),
        paymentStatus: paymentStatus,
        notes: List.from(_notes),
        payments: List.from(_payments),
        products: products,
        paidAt: paymentStatus == PaymentStatus.paid ? DateTime.now() : null,
      );

      // Add advance as initial payment if applicable
      if (advance > 0 && !_isEditing) {
        invoice.addPayment(advance, 'Initial advance payment');
      }

      // Save invoice
      if (_isEditing) {
        await _invoiceService.updateInvoice(invoice);
      } else {
        await _invoiceService.addInvoice(invoice);
      }

      if (mounted) {
        widget.onInvoiceAdded?.call();
        Navigator.of(context).pop(invoice);
        
        _showSuccessSnackbar(
          _isEditing 
            ? 'Invoice updated successfully' 
            : 'Invoice created successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error ${_isEditing ? 'updating' : 'creating'} invoice: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: InventoryDesignConfig.errorColor,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: InventoryDesignConfig.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.95;
    final maxWidth = screenSize.width * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth > 1200 ? 1200 : maxWidth,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: _isLoading ? _buildLoadingState() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 500,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  InventoryDesignConfig.primaryColor,
                ),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
            Text(
              'Loading invoice data...',
              style: InventoryDesignConfig.titleMedium,
            ),
            if (_isEditing) ...[
              const SizedBox(height: InventoryDesignConfig.spacingS),
              Text(
                'Retrieving existing invoice details',
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        // Validation Error Banner
        if (_showValidationErrors && _validationError != null)
          _buildValidationBanner(),
        Expanded(
          child: Row(
            children: [
              // Left Panel - Main Form (65%)
              Expanded(
                flex: 65,
                child: Container(
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.surfaceColor,
                    border: Border(
                      right: BorderSide(
                        color: InventoryDesignConfig.borderSecondary,
                      ),
                    ),
                  ),
                  child: _buildLeftPanel(),
                ),
              ),
              // Right Panel - Products & Summary (35%)
              Expanded(
                flex: 35,
                child: Container(
                  color: InventoryDesignConfig.surfaceLight,
                  child: _buildRightPanel(),
                ),
              ),
            ],
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildValidationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.errorColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: InventoryDesignConfig.errorColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.warning(PhosphorIconsStyle.fill),
            color: InventoryDesignConfig.errorColor,
            size: 20,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Text(
              _validationError!,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _showValidationErrors = false;
              _validationError = null;
            }),
            icon: Icon(
              PhosphorIcons.x(),
              color: InventoryDesignConfig.errorColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            ),
            child: Icon(
              _isEditing
                  ? PhosphorIcons.pencilSimple(PhosphorIconsStyle.fill)
                  : PhosphorIcons.receipt(PhosphorIconsStyle.fill),
              size: 20,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Invoice' : 'Create Tailor Invoice',
                  style: InventoryDesignConfig.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _isEditing 
                    ? 'Update invoice details and track progress'
                    : 'Generate a professional invoice for tailor services',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing && _selectedCustomer != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: InventoryDesignConfig.spacingM,
                vertical: InventoryDesignConfig.spacingS,
              ),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                border: Border.all(
                  color: InventoryDesignConfig.infoColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Customer: ${_selectedCustomer!.name}',
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.infoColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
          ],
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              PhosphorIcons.x(PhosphorIconsStyle.regular),
              color: InventoryDesignConfig.textSecondary,
            ),
            tooltip: 'Close Dialog',
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerSection(),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            _buildInvoiceDetailsSection(),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            _buildTailorSpecificSection(),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            _buildStatusFinancialSection(),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            _buildNotesSection(),
            if (_payments.isNotEmpty) ...[
              const SizedBox(height: InventoryDesignConfig.spacingXL),
              _buildPaymentHistorySection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return _buildSection(
      'Customer Information',
      PhosphorIcons.user(PhosphorIconsStyle.fill),
      InventoryDesignConfig.primaryColor,
      [
        _buildCustomerSelector(),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        if (_selectedCustomer != null) ...[
          _buildCustomerInfoCard(),
          const SizedBox(height: InventoryDesignConfig.spacingM),
        ],
        _buildMeasurementSelector(),
      ],
    );
  }

  Widget _buildCustomerInfoCard() {
    if (_selectedCustomer == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(
          color: InventoryDesignConfig.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.identificationCard(),
                size: 16,
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Bill #${_selectedCustomer!.billNumber}',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingS,
                  vertical: InventoryDesignConfig.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                ),
                child: Text(
                  _selectedCustomer!.gender.name.toUpperCase(),
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Row(
            children: [
              Icon(
                PhosphorIcons.phone(),
                size: 14,
                color: InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                _selectedCustomer!.phone,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
              if (_selectedCustomer!.address.isNotEmpty) ...[
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Icon(
                  PhosphorIcons.mapPin(),
                  size: 14,
                  color: InventoryDesignConfig.textSecondary,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingS),
                Expanded(
                  child: Text(
                    _selectedCustomer!.address,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailsSection() {
    return _buildSection(
      'Invoice Details',
      PhosphorIcons.receipt(PhosphorIconsStyle.fill),
      InventoryDesignConfig.infoColor,
      [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _invoiceNumberController,
                label: 'Invoice Number',
                hint: 'INV-001',
                icon: PhosphorIcons.hash(),
                enabled: false, // Invoice number should not be editable
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Invoice number is required' : null,
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildDateField(
                label: 'Invoice Date',
                date: _invoiceDate,
                onDateSelected: (date) => setState(() => _invoiceDate = date),
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildDateField(
          label: 'Delivery Date',
          date: _deliveryDate,
          onDateSelected: (date) => setState(() => _deliveryDate = date),
          validator: (date) {
            if (date.isBefore(_invoiceDate)) {
              return 'Delivery date must be after invoice date';
            }
            final daysDiff = date.difference(_invoiceDate).inDays;
            if (daysDiff > _maxDeliveryDays) {
              return 'Maximum $_maxDeliveryDays days allowed';
            }
            return null;
          },
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildTextField(
          controller: _detailsController,
          label: 'Order Details',
          hint: 'Describe the work to be done...',
          icon: PhosphorIcons.note(),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTailorSpecificSection() {
    return _buildSection(
      'Tailor Services',
      PhosphorIcons.scissors(PhosphorIconsStyle.fill),
      InventoryDesignConfig.warningColor,
      [
        Row(
          children: [
            Expanded(
              child: _buildPriorityDropdown(),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildDateField(
                label: 'Fitting Date (Optional)',
                date: _estimatedFittingDate ?? DateTime.now().add(const Duration(days: 3)),
                onDateSelected: (date) => setState(() => _estimatedFittingDate = date),
                isOptional: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildTextField(
          controller: _specialInstructionsController,
          label: 'Special Instructions',
          hint: 'Any special requirements, alterations, or notes...',
          icon: PhosphorIcons.notepad(),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Priority',
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        DropdownButtonFormField<String>(
          value: _priority,
          style: InventoryDesignConfig.bodyMedium,
          dropdownColor: InventoryDesignConfig.surfaceColor,
          decoration: InputDecoration(
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingM,
              vertical: InventoryDesignConfig.spacingS,
            ),
            prefixIcon: Icon(
              PhosphorIcons.flag(),
              size: 16,
              color: _priority == 'rush' 
                ? InventoryDesignConfig.errorColor
                : _priority == 'urgent'
                  ? InventoryDesignConfig.warningColor
                  : InventoryDesignConfig.textSecondary,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'normal',
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.successColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  const Text('Normal'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'urgent',
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.warningColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  const Text('Urgent'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'rush',
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.errorColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  const Text('Rush Order'),
                ],
              ),
            ),
          ],
          onChanged: (value) => setState(() => _priority = value!),
          icon: Icon(
            PhosphorIcons.caretDown(),
            size: 14,
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFinancialSection() {
    return _buildSection(
      'Status & Financial',
      PhosphorIcons.gear(PhosphorIconsStyle.fill),
      InventoryDesignConfig.successColor,
      [
        Row(
          children: [
            Expanded(
              child: _buildStatusDropdown(
                label: 'Delivery Status',
                value: _deliveryStatus,
                items: const ['pending', 'in_progress', 'delivered'],
                onChanged: (val) => setState(() => _deliveryStatus = val!),
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildStatusDropdown(
                label: 'Payment Status',
                value: _paymentStatus,
                items: const ['unpaid', 'partial', 'paid'],
                onChanged: (val) {
                  setState(() {
                    _paymentStatus = val!;
                    if (_paymentStatus == 'paid') {
                      _advanceController.text = _netTotal.toString();
                    }
                  });
                  _calculateTotals();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _vatController,
                label: 'VAT Rate (%)',
                hint: '5.0',
                icon: PhosphorIcons.percent(),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final rate = double.tryParse(value ?? '');
                  if (rate != null && rate > _maxVatRate) {
                    return 'Max ${_maxVatRate}%';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildTextField(
                controller: _advanceController,
                label: 'Advance Amount',
                hint: '0.00',
                icon: PhosphorIcons.wallet(),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final advance = double.tryParse(value ?? '') ?? 0;
                  if (!_isEditing && advance > 0) {
                    final minAdvance = (_netTotal * _minAdvancePercentage) / 100;
                    if (advance < minAdvance) {
                      return 'Min ${_minAdvancePercentage.toInt()}%';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      'Notes & Comments',
      PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
      InventoryDesignConfig.infoColor,
      [
        // Add new note
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newNoteController,
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  prefixIcon: Icon(PhosphorIcons.plus()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: InventoryDesignConfig.surfaceLight,
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            ElevatedButton.icon(
              onPressed: _addNote,
              icon: Icon(PhosphorIcons.plus(), size: 16),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: InventoryDesignConfig.infoColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                ),
              ),
            ),
          ],
        ),
        if (_notes.isNotEmpty) ...[
          const SizedBox(height: InventoryDesignConfig.spacingM),
          // Display notes
          Column(
            children: _notes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;
              return _buildNoteItem(note, index);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildNoteItem(String note, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingS),
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIcons.note(),
            size: 16,
            color: InventoryDesignConfig.textSecondary,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingS),
          Expanded(
            child: Text(
              note,
              style: InventoryDesignConfig.bodyMedium,
            ),
          ),
          IconButton(
            onPressed: () => _removeNote(index),
            icon: Icon(
              PhosphorIcons.trash(),
              size: 16,
              color: InventoryDesignConfig.errorColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    return _buildSection(
      'Payment History',
      PhosphorIcons.creditCard(PhosphorIconsStyle.fill),
      InventoryDesignConfig.successColor,
      [
        Column(
          children: _payments.asMap().entries.map((entry) {
            final index = entry.key;
            final payment = entry.value;
            return _buildPaymentItem(payment, index);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentItem(Payment payment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingS),
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        border: Border.all(
          color: InventoryDesignConfig.successColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.currencyDollar(),
            size: 16,
            color: InventoryDesignConfig.successColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NumberFormat.currency(symbol: 'AED ').format(payment.amount),
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: InventoryDesignConfig.successColor,
                  ),
                ),
                Text(
                  payment.note,
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM dd, yyyy').format(payment.date),
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _addNote() {
    final note = _newNoteController.text.trim();
    if (note.isNotEmpty) {
      setState(() {
        _notes.add(note);
        _newNoteController.clear();
      });
    }
  }

  void _removeNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
  }

  Widget _buildRightPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceAccent.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
            ),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.package(PhosphorIconsStyle.fill),
                size: 18,
                color: InventoryDesignConfig.successColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Products & Services',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  color: InventoryDesignConfig.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingS,
                  vertical: InventoryDesignConfig.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                ),
                child: Text(
                  '${_selectedProducts.length}',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.successColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            border: Border(
              bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
            ),
          ),
          child: _buildProductActions(),
        ),
        Expanded(
          child: _selectedProducts.isEmpty
              ? _buildEmptyProductsState()
              : _buildProductsList(),
        ),
        _buildFinancialSummary(),
      ],
    );
  }

  Widget _buildProductActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIcons.scissors(),
                label: 'Add Fabric',
                color: InventoryDesignConfig.infoColor,
                onPressed: () => _addFromInventory('fabric'),
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIcons.package(),
                label: 'Add Accessory',
                color: InventoryDesignConfig.successColor,
                onPressed: () => _addFromInventory('accessory'),
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            icon: PhosphorIcons.plus(),
            label: 'Add Custom Product',
            color: InventoryDesignConfig.warningColor,
            onPressed: _addCustomProduct,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: InventoryDesignConfig.spacingM,
            horizontal: InventoryDesignConfig.spacingL,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: InventoryDesignConfig.spacingS),
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

  Widget _buildEmptyProductsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
              ),
              child: Icon(
                PhosphorIcons.package(),
                size: 48,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Text(
              'No Products Added',
              style: InventoryDesignConfig.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              'Add products from inventory or create custom products',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      itemCount: _selectedProducts.length,
      separatorBuilder: (context, index) => const SizedBox(
        height: InventoryDesignConfig.spacingM,
      ),
      itemBuilder: (context, index) => _buildProductCard(_selectedProducts[index], index),
    );
  }

  Widget _buildProductCard(InvoiceProduct product, int index) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                decoration: BoxDecoration(
                  color: (product.inventoryType ?? 'custom') == 'fabric'
                      ? InventoryDesignConfig.infoColor.withOpacity(0.1)
                      : InventoryDesignConfig.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                ),
                child: Icon(
                  (product.inventoryType ?? 'custom') == 'fabric'
                      ? PhosphorIcons.scissors()
                      : PhosphorIcons.package(),
                  size: 16,
                  color: (product.inventoryType ?? 'custom') == 'fabric'
                      ? InventoryDesignConfig.infoColor
                      : InventoryDesignConfig.successColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        product.description,
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeProduct(index),
                icon: Icon(
                  PhosphorIcons.trash(),
                  size: 16,
                  color: InventoryDesignConfig.errorColor,
                ),
                tooltip: 'Remove Product',
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          Row(
            children: [
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceAccent,
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                  border: Border.all(color: InventoryDesignConfig.borderPrimary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: product.quantity > 0.5
                          ? () => _updateProductQuantity(
                                index,
                                product.quantity -
                                    ((product.inventoryType == 'fabric') ? 0.5 : 1.0),
                              )
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                        child: Icon(
                          PhosphorIcons.minus(),
                          size: 14,
                          color: product.quantity > 0.5
                              ? InventoryDesignConfig.textSecondary
                              : InventoryDesignConfig.textTertiary,
                        ),
                      ),
                    ),
                    Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(
                        vertical: InventoryDesignConfig.spacingS,
                      ),
                      child: Text(
                        product.quantity % 1 == 0
                            ? product.quantity.toInt().toString()
                            : product.quantity.toStringAsFixed(1),
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    InkWell(
                      onTap: () => _updateProductQuantity(
                        index,
                        product.quantity +
                            ((product.inventoryType == 'fabric') ? 0.5 : 1.0),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                        child: Icon(
                          PhosphorIcons.plus(),
                          size: 14,
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              // Price info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat.currency(symbol: 'AED ').format(product.unitPrice)}/${product.unit}',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: 'AED ').format(product.totalPrice),
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: InventoryDesignConfig.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          top: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.calculator(PhosphorIconsStyle.fill),
                size: 18,
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Financial Summary',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  color: InventoryDesignConfig.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          _buildSummaryRow('Subtotal', _subtotal),
          _buildSummaryRow('VAT (${_vatController.text}%)', _vatAmount),
          const Divider(color: InventoryDesignConfig.borderSecondary),
          _buildSummaryRow('Total', _netTotal, isTotal: true),
          _buildSummaryRow(
            'Advance',
            double.tryParse(_advanceController.text) ?? 0,
          ),
          if (_totalPaid > 0)
            _buildSummaryRow('Total Paid', _totalPaid),
          _buildSummaryRow('Balance', _balance, isBalance: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isBalance = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InventoryDesignConfig.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: InventoryDesignConfig.bodyMedium.copyWith(
              fontWeight: isTotal || isBalance ? FontWeight.w700 : FontWeight.w500,
              color: isBalance
                  ? InventoryDesignConfig.warningColor
                  : InventoryDesignConfig.textPrimary,
            ),
          ),
          Text(
            NumberFormat.currency(symbol: 'AED ').format(amount),
            style: InventoryDesignConfig.bodyMedium.copyWith(
              fontWeight: isTotal || isBalance ? FontWeight.w700 : FontWeight.w500,
              color: isBalance
                  ? InventoryDesignConfig.warningColor
                  : isTotal
                      ? InventoryDesignConfig.primaryColor
                      : InventoryDesignConfig.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
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
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
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
              onTap: _isSaving ? null : _saveInvoice,
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
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
                        _isEditing
                            ? PhosphorIcons.check()
                            : PhosphorIcons.receipt(),
                        size: 16,
                        color: Colors.white,
                      ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      _isSaving
                          ? (_isEditing ? 'Updating...' : 'Creating...')
                          : (_isEditing ? 'Update Invoice' : 'Create Invoice'),
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

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      decoration: InventoryDesignConfig.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
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
          style: InventoryDesignConfig.bodySmall.copyWith(
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
          style: InventoryDesignConfig.bodyMedium.copyWith(
            color: enabled
                ? InventoryDesignConfig.textPrimary
                : InventoryDesignConfig.textTertiary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: Icon(
              icon,
              size: 16,
              color: enabled
                  ? InventoryDesignConfig.textSecondary
                  : InventoryDesignConfig.textTertiary,
            ),
            filled: true,
            fillColor: enabled
                ? InventoryDesignConfig.surfaceLight
                : InventoryDesignConfig.surfaceAccent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingM,
              vertical: maxLines > 1
                  ? InventoryDesignConfig.spacingM
                  : InventoryDesignConfig.spacingS,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required Function(DateTime) onDateSelected,
    String? Function(DateTime)? validator,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 4),
              Text(
                '(Optional)',
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          child: InkWell(
            onTap: () async {
              final newDate = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: InventoryDesignConfig.primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (newDate != null) {
                onDateSelected(newDate);
                // Validate after selection
                final error = validator?.call(newDate);
                if (error != null) {
                  setState(() => _validationError = error);
                }
              }
            },
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: InventoryDesignConfig.spacingM,
                vertical: InventoryDesignConfig.spacingM,
              ),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.calendar(),
                    size: 16,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  Expanded(
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: InventoryDesignConfig.bodyMedium,
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretDown(),
                    size: 14,
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

  Widget _buildStatusDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        DropdownButtonFormField<String>(
          value: value,
          style: InventoryDesignConfig.bodyMedium.copyWith(
            color: InventoryDesignConfig.textPrimary,
          ),
          dropdownColor: InventoryDesignConfig.surfaceColor,
          decoration: InputDecoration(
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingM,
              vertical: InventoryDesignConfig.spacingS,
            ),
          ),
          items: items.map((item) {
            Color statusColor = InventoryDesignConfig.textPrimary;
            if (label.contains('Delivery')) {
              statusColor = item == 'delivered' 
                ? InventoryDesignConfig.successColor
                : item == 'in_progress'
                  ? InventoryDesignConfig.warningColor
                  : InventoryDesignConfig.textSecondary;
            } else if (label.contains('Payment')) {
              statusColor = item == 'paid'
                ? InventoryDesignConfig.successColor
                : item == 'partial'
                  ? InventoryDesignConfig.warningColor
                  : InventoryDesignConfig.errorColor;
            }
            
            return DropdownMenuItem(
              value: item,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  Text(
                    item.replaceAll('_', ' ').toUpperCase(),
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Icon(
            PhosphorIcons.caretDown(),
            size: 14,
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSelector() {
    return _buildSelectorField(
      label: 'Customer',
      hint: 'Select customer',
      icon: PhosphorIcons.user(),
      value: _selectedCustomer?.name,
      onTap: _selectCustomer,
      isRequired: true,
    );
  }

  Widget _buildMeasurementSelector() {
    final isEnabled = _selectedCustomer != null;
    return _buildSelectorField(
      label: 'Measurement (Optional)',
      hint: isEnabled ? 'Select measurement' : 'Select customer first',
      icon: PhosphorIcons.ruler(),
      value: _selectedMeasurement?.style,
      onTap: isEnabled ? _selectMeasurement : null,
      isEnabled: isEnabled,
    );
  }

  Widget _buildSelectorField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required VoidCallback? onTap,
    bool isEnabled = true,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: InventoryDesignConfig.labelLarge.copyWith(
                color: InventoryDesignConfig.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: InventoryDesignConfig.labelLarge.copyWith(
                  color: InventoryDesignConfig.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
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
                vertical: InventoryDesignConfig.spacingM + 2,
              ),
              decoration: BoxDecoration(
                color: isEnabled
                    ? InventoryDesignConfig.surfaceLight
                    : InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                border: Border.all(
                  color: value != null && isEnabled
                      ? InventoryDesignConfig.primaryColor.withOpacity(0.3)
                      : InventoryDesignConfig.borderPrimary,
                  width: value != null && isEnabled ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isEnabled
                        ? InventoryDesignConfig.textSecondary
                        : InventoryDesignConfig.textTertiary,
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingL),
                  Expanded(
                    child: Text(
                      value ?? hint,
                      style: value != null
                          ? InventoryDesignConfig.bodyLarge.copyWith(
                              color: InventoryDesignConfig.textPrimary,
                            )
                          : InventoryDesignConfig.bodyMedium.copyWith(
                              color: isEnabled
                                  ? InventoryDesignConfig.textTertiary
                                  : InventoryDesignConfig.textTertiary
                                      .withOpacity(0.5),
                            ),
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretDown(),
                    size: 16,
                    color: isEnabled
                        ? InventoryDesignConfig.textSecondary
                        : InventoryDesignConfig.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateProductQuantity(int index, double newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _selectedProducts[index].quantity = newQuantity;
      });
      _calculateTotals();
    }
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
    _calculateTotals();
  }

  Future<void> _selectCustomer() async {
    final customer = await CustomerSelectorDialog.show(context, _customers);
    if (customer != null) {
      setState(() {
        _selectedCustomer = customer;
        _selectedMeasurement = null;
      });
    }
  }

  Future<void> _selectMeasurement() async {
    if (_selectedCustomer == null) return;
    final measurement = await MeasurementSelectorDialog.show(
      context,
      customerId: _selectedCustomer!.id,
    );
    if (measurement != null) {
      setState(() => _selectedMeasurement = measurement);
    }
  }

  Future<void> _addFromInventory(String inventoryType) async {
    final selectedItems = await inventory_item.InventoryItemSelectorDialog.show(
      context,
      inventoryType: inventoryType,
    );

    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() => _selectedProducts.addAll(selectedItems));
      _calculateTotals();
    }
  }

  Future<void> _addCustomProduct() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'pcs');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            InventoryDesignConfig.radiusL,
          ),
        ),
        title: Row(
          children: [
            Icon(
              PhosphorIcons.plus(),
              color: InventoryDesignConfig.primaryColor,
              size: 20,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Text(
              'Add Custom Product',
              style: InventoryDesignConfig.titleLarge,
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(PhosphorIcons.textT()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: InventoryDesignConfig.spacingL),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Unit Price',
                  prefixIcon: Icon(PhosphorIcons.currencyDollar()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: InventoryDesignConfig.spacingL),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(PhosphorIcons.hash()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusM,
                          ),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        prefixIcon: Icon(PhosphorIcons.ruler()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusM,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? 0,
                  'quantity': double.tryParse(quantityController.text) ?? 1.0,
                  'unit': unitController.text.isNotEmpty
                      ? unitController.text
                      : 'pcs',
                });
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: InventoryDesignConfig.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
              ),
            ),
            icon: Icon(PhosphorIcons.plus(), size: 16),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );

    if (result != null) {
      final product = InvoiceProduct(
        id: const Uuid().v4(),
        name: result['name'],
        description: 'Custom product',
        unitPrice: result['price'],
        quantity: result['quantity'],
        unit: result['unit'],
      );
      setState(() => _selectedProducts.add(product));
      _calculateTotals();
    }
  }
}
