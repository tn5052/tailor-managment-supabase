// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/customer.dart';
import '../../../models/measurement.dart';
import '../../../models/invoice_product.dart';
import '../../../models/invoice.dart';
import '../invoice_template.dart';
import '../../../services/inventory_service.dart';

import 'customer_selector_dialog.dart';
import 'measurement_selector_dialog.dart';
import 'product_selector_dialog.dart';
import 'kandora_selector_dialog.dart';
import '../../../models/kandora_order.dart';

class AddEditInvoiceDesktopDialog extends StatefulWidget {
  final Map<String, dynamic>? invoice; // Null for add, present for edit
  final VoidCallback? onInvoiceSaved;
  final Customer? customer; // Optional customer to pre-fill

  const AddEditInvoiceDesktopDialog({
    super.key,
    this.invoice,
    this.onInvoiceSaved,
    this.customer,
  });

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? invoice,
    VoidCallback? onInvoiceSaved,
    Customer? customer, // Accept optional customer
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AddEditInvoiceDesktopDialog(
            invoice: invoice,
            onInvoiceSaved: onInvoiceSaved,
            customer: customer, // Pass customer to the widget
          ),
    );
  }

  @override
  State<AddEditInvoiceDesktopDialog> createState() =>
      _AddEditInvoiceDesktopDialogState();
}

class _AddEditInvoiceDesktopDialogState
    extends State<AddEditInvoiceDesktopDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isEditMode = false;

  // Controllers
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _customerBillNumberController;
  late final TextEditingController _detailsController;
  late final TextEditingController _notesController;
  late final TextEditingController
  _amountController; // This will now represent total from products
  late final TextEditingController _amountIncludingVatController;
  late final TextEditingController _netTotalController;
  late final TextEditingController _advanceController;
  late final TextEditingController _balanceController;
  late final TextEditingController _refundAmountController;
  late final TextEditingController _refundReasonController;
  late final TextEditingController _discountValueController;

  DateTime? _selectedDate;
  DateTime? _selectedDeliveryDate;
  DateTime? _selectedRefundedAt;

  String? _selectedCustomerId;
  Customer? _selectedCustomer; // Store full customer object
  String? _selectedMeasurementId;
  Measurement? _selectedMeasurement; // Store full measurement object

  String? _selectedPaymentStatus;
  String? _selectedDeliveryStatus;
  String _discountType = 'none'; // 'none', 'percentage', 'fixed'

  List<InvoiceProduct> _selectedProducts = []; // Changed type to InvoiceProduct
  List<KandoraOrder> _selectedKandoras = []; // Add kandora orders list
  List<Map<String, dynamic>> _payments = [];

  final List<String> _paymentStatusOptions = [
    'Pending',
    'Partially Paid',
    'Paid',
    'Refunded',
  ];

  final List<String> _deliveryStatusOptions = [
    'Pending',
    'Processing',
    'Ready for Pickup',
    'Out for Delivery',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.invoice != null;
    _initializeControllers();
    _generateInvoiceNumberIfNeeded(); // New: Auto-generate invoice number
    _calculateTotals(); // Initial calculation
  }

  void _onPaymentStatusChanged(String? value) {
    setState(() {
      _selectedPaymentStatus = value;
      if (value?.toLowerCase() == 'paid') {
        // When status is 'Paid', set advance to the total amount.
        _advanceController.text = _amountIncludingVatController.text;
      }
      // Recalculate totals to update the balance.
      _calculateTotals();
    });
  }

  void _generateInvoiceNumberIfNeeded() async {
    if (!_isEditMode) {
      try {
        final response =
            await _supabase
                .from('invoices')
                .select('invoice_number')
                .order('invoice_number', ascending: false)
                .limit(1)
                .single();

        final lastNumber = int.parse(response['invoice_number']);
        setState(() {
          _invoiceNumberController.text = (lastNumber + 1).toString();
        });
      } catch (e) {
        // No previous invoices, start from a default
        setState(() {
          _invoiceNumberController.text = '1001';
        });
      }
    }
  }

  void _initializeControllers() {
    _invoiceNumberController = TextEditingController(
      text: widget.invoice?['invoice_number'] ?? '',
    );
    _customerNameController = TextEditingController(
      text: widget.invoice?['customer_name'] ?? '',
    );
    _customerPhoneController = TextEditingController(
      text: widget.invoice?['customer_phone'] ?? '',
    );
    _customerBillNumberController = TextEditingController(
      text: widget.invoice?['customer_bill_number'] ?? '',
    );
    _detailsController = TextEditingController(
      text: widget.invoice?['details'] ?? '',
    );
    _notesController = TextEditingController(
      text: (widget.invoice?['notes'] as List?)?.join('\n') ?? '',
    );

    // Amount will be calculated from products, so it's read-only here
    _amountController = TextEditingController(
      text: (widget.invoice?['amount'] ?? 0.0).toStringAsFixed(2),
    );
    _amountIncludingVatController = TextEditingController(
      text: (widget.invoice?['amount_including_vat'] ?? 0.0).toStringAsFixed(2),
    );
    _netTotalController = TextEditingController(
      text: (widget.invoice?['net_total'] ?? 0.0).toStringAsFixed(2),
    );
    _advanceController = TextEditingController(
      text: (widget.invoice?['advance'] ?? 0.0).toStringAsFixed(2),
    );
    _balanceController = TextEditingController(
      text: (widget.invoice?['balance'] ?? 0.0).toStringAsFixed(2),
    );
    _refundAmountController = TextEditingController(
      text: (widget.invoice?['refund_amount'] ?? 0.0).toStringAsFixed(2),
    );
    _refundReasonController = TextEditingController(
      text: widget.invoice?['refund_reason'] ?? '',
    );
    _discountValueController = TextEditingController(
      text: (widget.invoice?['discount_value'] ?? 0.0).toString(),
    );

    _selectedDate =
        widget.invoice?['date'] != null
            ? DateTime.parse(widget.invoice!['date'])
            : DateTime.now();
    _selectedDeliveryDate =
        widget.invoice?['delivery_date'] != null
            ? DateTime.parse(widget.invoice!['delivery_date'])
            : DateTime.now().add(const Duration(days: 7));
    _selectedRefundedAt =
        widget.invoice?['refunded_at'] != null
            ? DateTime.parse(widget.invoice!['refunded_at'])
            : null;

    // Set default status values for new invoices
    if (!_isEditMode) {
      _selectedPaymentStatus = 'Paid';
      _selectedDeliveryStatus = 'Delivered';
    } else {
      _selectedPaymentStatus = widget.invoice?['payment_status'];
      _selectedDeliveryStatus = widget.invoice?['delivery_status'];
      _discountType = widget.invoice?['discount_type'] ?? 'none';
    }

    // Initialize selected customer and measurement if in edit mode
    if (_isEditMode) {
      _selectedCustomerId = widget.invoice?['customer_id'];
      _selectedMeasurementId = widget.invoice?['measurement_id'];
      if (_selectedCustomerId != null) {
        _loadCustomerData(_selectedCustomerId!);
      }
      if (_selectedMeasurementId != null) {
        _loadMeasurementData(_selectedMeasurementId!);
      }
    }

    // Pre-fill customer details if provided on initial creation
    if (widget.customer != null && !_isEditMode) {
      _selectedCustomerId = widget.customer!.id;
      _selectedCustomer = widget.customer; // Use passed customer
      _customerNameController.text = widget.customer!.name;
      _customerPhoneController.text = widget.customer!.phone;
    } else if (_isEditMode && widget.invoice?['customer_id'] != null) {
      // If in edit mode and customer_id exists, try to load customer data
      _selectedCustomerId = widget.invoice!['customer_id'];
      _customerNameController.text = widget.invoice!['customer_name'];
      _customerPhoneController.text = widget.invoice!['customer_phone'];
      // You might want to fetch the full Customer object here if needed elsewhere
    }

    // Parse products and payments if in edit mode
    if (_isEditMode) {
      if (widget.invoice!['products'] is List) {
        _selectedProducts = List<InvoiceProduct>.from(
          widget.invoice!['products'].map((p) => InvoiceProduct.fromJson(p)),
        );
      }
      if (widget.invoice!['payments'] is List) {
        _payments = List<Map<String, dynamic>>.from(
          widget.invoice!['payments'],
        );
      }
    }

    _amountController.addListener(_calculateTotals);
    _advanceController.addListener(_calculateTotals);
    _discountValueController.addListener(_calculateTotals);
  }

  void _calculateTotals() {
    double amount = _selectedProducts.fold(
      0.0,
      (sum, product) => sum + product.totalPrice,
    ); // Sum from products
    amount += _selectedKandoras.fold(
      0.0,
      (sum, kandora) => sum + kandora.totalPrice,
    ); // Add kandora totals
    const double vatRate = 0.05; // Fixed 5% VAT
    double advance = double.tryParse(_advanceController.text) ?? 0.0;
    double discountValue =
        double.tryParse(_discountValueController.text) ?? 0.0;
    double discountAmount = 0.0;

    if (_discountType == 'percentage') {
      discountAmount = amount * (discountValue / 100);
    } else if (_discountType == 'fixed') {
      discountAmount = discountValue;
    }

    double netTotal = amount - discountAmount;
    if (netTotal < 0) netTotal = 0;

    double vatAmount = netTotal * vatRate;
    double amountIncludingVat = netTotal + vatAmount;
    double balance = amountIncludingVat - advance;

    _amountController.text = amount.toStringAsFixed(
      2,
    ); // Update amount based on products
    _amountIncludingVatController.text = amountIncludingVat.toStringAsFixed(2);
    _netTotalController.text = netTotal.toStringAsFixed(2);
    _balanceController.text = balance.toStringAsFixed(2);

    // Force UI update for real-time display
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerBillNumberController.dispose();
    _detailsController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    _amountIncludingVatController.dispose();
    _netTotalController.dispose();
    _advanceController.dispose();
    _balanceController.dispose();
    _refundAmountController.dispose();
    _refundReasonController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? initialDate,
    ValueChanged<DateTime> onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      onDateSelected(picked);
    }
  }

  // Enhanced styled date picker
  Future<void> _selectStyledDate(
    BuildContext context,
    DateTime? initialDate,
    ValueChanged<DateTime> onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: InventoryDesignConfig.primaryColor,
              onPrimary: Colors.white,
              surface: InventoryDesignConfig.surfaceColor,
              onSurface: InventoryDesignConfig.textPrimary,
            ),
            dialogBackgroundColor: InventoryDesignConfig.surfaceColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != initialDate) {
      onDateSelected(picked);
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one product or kandora is selected
    if (_selectedProducts.isEmpty && _selectedKandoras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(PhosphorIcons.warning(), color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'At least one product or kandora is required to create an invoice',
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

    setState(() => _isLoading = true);

    try {
      final data = {
        'invoice_number': _invoiceNumberController.text.trim(),
        'date': _selectedDate?.toIso8601String(),
        'delivery_date': _selectedDeliveryDate?.toIso8601String(),
        'amount': double.parse(_amountController.text),
        'vat': 0.05, // Fixed VAT
        'amount_including_vat': double.parse(
          _amountIncludingVatController.text,
        ),
        'net_total': double.parse(_netTotalController.text),
        'advance': double.parse(_advanceController.text),
        'balance': double.parse(_balanceController.text),
        'customer_id': _selectedCustomerId,
        'customer_name': _customerNameController.text.trim(),
        'customer_phone': _customerPhoneController.text.trim(),
        'details':
            _detailsController.text.trim().isEmpty
                ? null
                : _detailsController.text.trim(),
        'customer_bill_number': _customerBillNumberController.text.trim(),
        'measurement_id': _selectedMeasurementId,
        'measurement_name':
            _selectedMeasurement?.style, // Use selectedMeasurement object
        'delivery_status': _selectedDeliveryStatus,
        'payment_status': _selectedPaymentStatus,
        'delivered_at':
            _selectedDeliveryStatus == 'Delivered'
                ? DateTime.now().toIso8601String()
                : null,
        'paid_at':
            _selectedPaymentStatus == 'Paid'
                ? DateTime.now().toIso8601String()
                : null,
        'notes':
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim().split('\n'),
        'payments': _payments,
        'is_delivered': _selectedDeliveryStatus == 'Delivered',
        'products':
            _selectedProducts
                .map((p) => p.toJson())
                .toList(), // Convert InvoiceProduct to JSON
        'discount_type': _discountType,
        'discount_value': double.tryParse(_discountValueController.text) ?? 0.0,
        'discount_amount': _calculateDiscountAmount(),
        'refund_amount': double.tryParse(_refundAmountController.text) ?? 0.0,
        'refunded_at': _selectedRefundedAt?.toIso8601String(),
        'refund_reason':
            _refundReasonController.text.trim().isEmpty
                ? null
                : _refundReasonController.text.trim(),
        'tenant_id':
            _supabase.auth.currentUser!.id, // Ensure tenant_id is always set
      };

      if (_isEditMode) {
        data['last_modified_at'] = DateTime.now().toIso8601String();
        data['last_modified_reason'] =
            'Edited via desktop dialog'; // Or prompt user for reason
        await _supabase
            .from('invoices')
            .update(data)
            .eq('id', widget.invoice!['id']);
      } else {
        data['id'] = const Uuid().v4(); // Generate new UUID for new invoice
        await _supabase.from('invoices').insert(data);
        // Update inventory quantities for the selected products
        await InventoryService.updateInventoryQuantities(_selectedProducts);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onInvoiceSaved?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invoice ${data['invoice_number']} ${_isEditMode ? 'updated' : 'added'} successfully',
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
            content: Text('Error saving invoice: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  double _calculateDiscountAmount() {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double discountValue =
        double.tryParse(_discountValueController.text) ?? 0.0;
    if (_discountType == 'percentage') {
      return amount * (discountValue / 100);
    } else if (_discountType == 'fixed') {
      return discountValue;
    }
    return 0.0;
  }

  Future<void> _previewInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that a customer is selected
    if (_selectedCustomerId == null ||
        _customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(PhosphorIcons.warning(), color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please select a customer before previewing the invoice.',
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

    // Validate that at least one product is selected
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(PhosphorIcons.warning(), color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'At least one product is required to preview an invoice',
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

    try {
      // Create temporary Invoice object for preview
      final tempInvoice = Invoice(
        id: _isEditMode ? widget.invoice!['id'] : const Uuid().v4(),
        invoiceNumber: _invoiceNumberController.text.trim(),
        date: _selectedDate ?? DateTime.now(),
        deliveryDate:
            _selectedDeliveryDate ??
            DateTime.now().add(const Duration(days: 7)),
        amount: double.parse(_amountController.text),
        vat: double.parse(_amountController.text) * 0.05,
        amountIncludingVat: double.parse(_amountIncludingVatController.text),
        netTotal: double.parse(_netTotalController.text),
        advance: double.parse(_advanceController.text),
        balance: double.parse(_balanceController.text),
        customerId: _selectedCustomerId ?? '',
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        details: _detailsController.text.trim(),
        customerBillNumber: _customerBillNumberController.text.trim(),
        measurementId: _selectedMeasurementId,
        measurementName: _selectedMeasurement?.style,
        deliveryStatus: _getInvoiceStatus(_selectedDeliveryStatus ?? 'Pending'),
        paymentStatus: _getPaymentStatus(_selectedPaymentStatus ?? 'Pending'),
        deliveredAt:
            _selectedDeliveryStatus == 'Delivered' ? DateTime.now() : null,
        paidAt: _selectedPaymentStatus == 'Paid' ? DateTime.now() : null,
        notes:
            _notesController.text.trim().isEmpty
                ? []
                : _notesController.text.trim().split('\n'),
        payments:
            _payments
                .map(
                  (p) => Payment(
                    amount: p['amount'],
                    date: DateTime.parse(p['date']),
                    note: p['note'] ?? '',
                  ),
                )
                .toList(),
        isDelivered: _selectedDeliveryStatus == 'Delivered',
        products:
            _selectedProducts
                .map((p) => Product(name: p.name, price: p.totalPrice))
                .toList(),
        refundAmount: double.tryParse(_refundAmountController.text) ?? 0.0,
        refundedAt: _selectedRefundedAt,
        refundReason:
            _refundReasonController.text.trim().isEmpty
                ? null
                : _refundReasonController.text.trim(),
      );

      // Generate PDF
      final pdfBytes = await InvoiceTemplate.generateInvoice(tempInvoice);

      // Show PDF preview dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (context) => _InvoicePdfPreviewDialog(
                pdfBytes: pdfBytes,
                invoiceNumber: tempInvoice.invoiceNumber,
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating invoice preview: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Placeholder for customer selection dialog
  Future<void> _openCustomerSelector() async {
    final selectedCustomer = await CustomerSelectorDialog.show(
      context,
      selectedCustomerId: _selectedCustomerId,
      onCustomerSelected: (customer) {
        setState(() {
          _selectedCustomer = customer;
          _selectedCustomerId = customer.id;
          _customerNameController.text = customer.name;
          _customerPhoneController.text = customer.phone;
          _customerBillNumberController.text = customer.billNumber;
          _selectedMeasurement = null; // Clear selected measurement
          _selectedMeasurementId = null;
          // Load measurements for the newly selected customer
          _loadMeasurementsForSelectedCustomer(customer.id);
        });
      },
    );
    // The dialog handles setting the state via onCustomerSelected, no need to check return here.
  }

  Future<void> _loadMeasurementsForSelectedCustomer(String customerId) async {
    try {
      final response = await _supabase
          .from('measurements')
          .select('*')
          .eq('customer_id', customerId)
          .order('date', ascending: false)
          .limit(1); // Get the most recent measurement

      if (response.isNotEmpty) {
        final latestMeasurement = Measurement.fromMap(response.first);
        setState(() {
          _selectedMeasurement = latestMeasurement;
          _selectedMeasurementId = latestMeasurement.id;
        });
      } else {
        setState(() {
          _selectedMeasurement = null;
          _selectedMeasurementId = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading measurements for customer: $e');
    }
  }

  // Placeholder for measurement selection dialog
  Future<void> _openMeasurementSelector() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a customer first to choose a measurement.',
          ),
          backgroundColor: InventoryDesignConfig.warningColor,
        ),
      );
      return;
    }
    await MeasurementSelectorDialog.show(
      context,
      customerId: _selectedCustomerId!,
      selectedMeasurementId: _selectedMeasurementId,
      onMeasurementSelected: (measurement) {
        setState(() {
          _selectedMeasurement = measurement;
          _selectedMeasurementId = measurement.id;
        });
      },
    );
    // The dialog handles setting the state via onMeasurementSelected, no need to check return here.
  }

  // Placeholder for product selection dialog
  Future<void> _addProduct() async {
    final selectedProductsResult = await ProductSelectorDialog.show(
      context,
      initialProducts: _selectedProducts,
      onProductsSelected: (products) {
        setState(() {
          _selectedProducts = products;
        });
        _calculateTotals(); // Recalculate totals based on selected products
      },
    );
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
      _calculateTotals(); // Recalculate totals after removing product
    });
  }

  // Add kandora to invoice
  Future<void> _addKandora() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer first'),
          backgroundColor: InventoryDesignConfig.warningColor,
        ),
      );
      return;
    }

    // We need a temporary invoice ID for the kandora selector
    String tempInvoiceId =
        _isEditMode ? widget.invoice!['id'] : const Uuid().v4();

    await KandoraSelectorDialog.show(
      context,
      invoiceId: tempInvoiceId,
      onKandoraSelected: (kandoraOrder) {
        setState(() {
          _selectedKandoras.add(kandoraOrder);
        });
        _calculateTotals(); // Recalculate totals
      },
    );
  }

  void _removeKandora(int index) {
    setState(() {
      _selectedKandoras.removeAt(index);
      _calculateTotals(); // Recalculate totals after removing kandora
    });
  }

  // This method is now implicitly handled by _calculateTotals
  void _calculateTotalsFromProducts() {}

  Future<void> _loadCustomerData(String customerId) async {
    try {
      final response =
          await _supabase
              .from('customers')
              .select()
              .eq('id', customerId)
              .single();
      setState(() {
        _selectedCustomer = Customer.fromMap(response);
        _customerNameController.text = _selectedCustomer!.name;
        _customerPhoneController.text = _selectedCustomer!.phone;
        _customerBillNumberController.text = _selectedCustomer!.billNumber;
      });
    } catch (e) {
      debugPrint('Error loading customer data: $e');
    }
  }

  Future<void> _loadMeasurementData(String measurementId) async {
    try {
      final response =
          await _supabase
              .from('measurements')
              .select()
              .eq('id', measurementId)
              .single();
      setState(() {
        _selectedMeasurement = Measurement.fromMap(response);
      });
    } catch (e) {
      debugPrint('Error loading measurement data: $e');
    }
  }

  Future<void> _showExitConfirmationDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'Are you sure you want to discard your changes? Any unsaved information will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      Navigator.of(context).pop();
    }
  }

  // Helper methods to convert string status to enum
  InvoiceStatus _getInvoiceStatus(String status) {
    switch (status) {
      case 'Pending':
        return InvoiceStatus.pending;
      case 'Processing':
        return InvoiceStatus.inProgress;
      case 'Ready for Pickup':
        return InvoiceStatus.inProgress;
      case 'Out for Delivery':
        return InvoiceStatus.inProgress;
      case 'Delivered':
        return InvoiceStatus.delivered;
      default:
        return InvoiceStatus.pending;
    }
  }

  PaymentStatus _getPaymentStatus(String status) {
    switch (status) {
      case 'Pending':
        return PaymentStatus.unpaid;
      case 'Partially Paid':
        return PaymentStatus.partial;
      case 'Paid':
        return PaymentStatus.paid;
      case 'Refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.unpaid;
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
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: maxHeight,
        ), // Increased maxWidth
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
              Expanded(child: _buildContent()), // Use Expanded for content
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
              _isEditMode ? PhosphorIcons.pencilSimple() : PhosphorIcons.plus(),
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
                  _isEditMode ? 'Edit Invoice' : 'Create New Invoice',
                  style: InventoryDesignConfig.headlineMedium,
                ),
                Text(
                  _isEditMode
                      ? 'Invoice No: ${widget.invoice?['invoice_number'] ?? 'N/A'}'
                      : 'Fill in the details to create a new invoice',
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
              onTap: () => _showExitConfirmationDialog(),
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
    return Padding(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Invoice Details, Customer & Measurement, Financial Summary
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                // Add SingleChildScrollView here
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Invoice Info Section
                    _buildSectionWithInvoiceNumber(
                      'Basic Information',
                      PhosphorIcons.receipt(),
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStyledDateField(
                                label: 'Invoice Date',
                                hint: 'Select date',
                                icon: PhosphorIcons.calendar(),
                                selectedDate: _selectedDate,
                                onTap:
                                    () => _selectStyledDate(
                                      context,
                                      _selectedDate,
                                      (date) {
                                        setState(() => _selectedDate = date);
                                      },
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select invoice date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(
                              width: InventoryDesignConfig.spacingL,
                            ),
                            Expanded(
                              child: _buildStyledDateField(
                                label: 'Delivery Date',
                                hint: 'Select delivery date',
                                icon: PhosphorIcons.truck(),
                                selectedDate: _selectedDeliveryDate,
                                onTap:
                                    () => _selectStyledDate(
                                      context,
                                      _selectedDeliveryDate,
                                      (date) {
                                        setState(
                                          () => _selectedDeliveryDate = date,
                                        );
                                      },
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select delivery date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: InventoryDesignConfig.spacingL),
                        _buildSelectorField(
                          label: 'Customer Name',
                          hint: 'Select customer',
                          icon: PhosphorIcons.user(),
                          value: _selectedCustomer?.name,
                          onTap: _openCustomerSelector,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a customer';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: InventoryDesignConfig.spacingL),
                        _buildSelectorField(
                          label: 'Measurement Profile (Optional)',
                          hint:
                              _selectedCustomer == null
                                  ? 'Select customer first'
                                  : 'Select measurement profile (optional)',
                          icon: PhosphorIcons.ruler(),
                          value: _selectedMeasurement?.style,
                          onTap: _openMeasurementSelector,
                          validator: (value) {
                            return null; // Optional field
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: InventoryDesignConfig.spacingXL),

                    // Status Section
                    _buildSection('Status', PhosphorIcons.info(), [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown<String>(
                              value: _selectedPaymentStatus,
                              label: 'Payment Status',
                              hint: 'Select status',
                              icon: PhosphorIcons.money(),
                              items:
                                  _paymentStatusOptions
                                      .map(
                                        (status) => DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(status),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentStatus = value;
                                  if (value == 'Paid') {
                                    _advanceController.text = (double.tryParse(
                                              _amountIncludingVatController
                                                  .text,
                                            ) ??
                                            0.0)
                                        .toStringAsFixed(2);
                                  } else {}
                                  if (value == 'Refunded' &&
                                      _selectedRefundedAt == null) {
                                    _selectedRefundedAt = DateTime.now();
                                  } else if (value != 'Refunded') {
                                    _selectedRefundedAt = null;
                                  }
                                  _calculateTotals();
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select payment status';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: InventoryDesignConfig.spacingL),
                          Expanded(
                            child: _buildDropdown<String>(
                              value: _selectedDeliveryStatus,
                              label: 'Delivery Status',
                              hint: 'Select status',
                              icon: PhosphorIcons.truck(),
                              items:
                                  _deliveryStatusOptions
                                      .map(
                                        (status) => DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(status),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDeliveryStatus = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select delivery status';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      // Refund Section - Only show if refunded
                      if (_selectedPaymentStatus == 'Refunded') ...[
                        const SizedBox(height: InventoryDesignConfig.spacingL),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _refundAmountController,
                                label: 'Refund Amount',
                                hint: '0.00',
                                icon: PhosphorIcons.currencyDollar(),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_selectedPaymentStatus == 'Refunded' &&
                                      (value == null ||
                                          double.tryParse(value) == null ||
                                          double.parse(value) <= 0)) {
                                    return 'Enter valid refund amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(
                              width: InventoryDesignConfig.spacingL,
                            ),
                            Expanded(
                              child: _buildStyledDateField(
                                label: 'Refunded At',
                                hint: 'Select date',
                                icon: PhosphorIcons.calendar(),
                                selectedDate: _selectedRefundedAt,
                                onTap:
                                    () => _selectStyledDate(
                                      context,
                                      _selectedRefundedAt,
                                      (date) {
                                        setState(
                                          () => _selectedRefundedAt = date,
                                        );
                                      },
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select refunded date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: InventoryDesignConfig.spacingL),
                        _buildTextField(
                          controller: _refundReasonController,
                          label: 'Refund Reason',
                          hint: 'Reason for refund...',
                          icon: PhosphorIcons.note(),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter refund reason';
                            }
                            return null;
                          },
                        ),
                      ],
                    ]),

                    const SizedBox(height: InventoryDesignConfig.spacingXL),

                    // Order Details Section - Moved to end
                    _buildSection('Order Details', PhosphorIcons.note(), [
                      _buildTextField(
                        controller: _detailsController,
                        label: 'Additional Details (Optional)',
                        hint:
                            'Describe the order, special instructions, etc...',
                        icon: PhosphorIcons.notepad(),
                        maxLines: 4,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(
              width: InventoryDesignConfig.spacingXXL,
            ), // Added gap
            // Right Panel: Products Section
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Products Section - Expandable
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_buildProductSection()],
                      ),
                    ),
                  ),

                  // Financial Summary - Sticky at bottom
                  Container(
                    margin: const EdgeInsets.only(
                      top: InventoryDesignConfig.spacingL,
                    ),
                    child: _buildFinancialSummarySection(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Financial Summary Section - Sticky at bottom
  Widget _buildFinancialSummarySection() {
    final subtotal = double.tryParse(_amountController.text) ?? 0.0;
    final discountAmount = _calculateDiscountAmount();
    final netTotal = subtotal - discountAmount;
    final vatAmount =
        (double.tryParse(_amountIncludingVatController.text) ?? 0.0) - netTotal;
    final total = double.tryParse(_amountIncludingVatController.text) ?? 0.0;
    final advance = double.tryParse(_advanceController.text) ?? 0.0;
    final balance = double.tryParse(_balanceController.text) ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(
          color: InventoryDesignConfig.primaryColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical: InventoryDesignConfig.spacingM,
            ),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.calculator(),
                  size: 16,
                  color: InventoryDesignConfig.primaryColor,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  'Summary',
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Financial Details
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFinancialRow('Subtotal', subtotal, false),
                _buildDiscountSection(), // New discount section
                if (discountAmount > 0)
                  _buildFinancialRow(
                    'Discount',
                    -discountAmount,
                    false,
                    color: InventoryDesignConfig.successColor,
                  ),
                _buildFinancialRow('VAT (5%)', vatAmount, false),
                const Divider(),
                _buildFinancialRow('Total', total, true),

                // Conditional Advance and Balance
                if (_selectedPaymentStatus != 'Paid') ...[
                  const SizedBox(height: InventoryDesignConfig.spacingM),

                  // Advance Payment Input
                  TextFormField(
                    controller: _advanceController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _calculateTotals(),
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Advance Payment',
                      prefixText: 'AED ',
                      filled: true,
                      fillColor: InventoryDesignConfig.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: InventoryDesignConfig.spacingM,
                        vertical: InventoryDesignConfig.spacingS,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                        borderSide: BorderSide(
                          color: InventoryDesignConfig.borderPrimary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                        borderSide: BorderSide(
                          color: InventoryDesignConfig.borderPrimary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                        borderSide: BorderSide(
                          color: InventoryDesignConfig.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null) {
                        return 'Enter valid advance';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: InventoryDesignConfig.spacingM),
                  const Divider(),
                  _buildFinancialRow(
                    'Balance Due',
                    balance,
                    true,
                    color:
                        balance > 0
                            ? InventoryDesignConfig.errorColor
                            : InventoryDesignConfig.successColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
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
              textAlign: TextAlign.center,
              style: InventoryDesignConfig.headlineMedium.copyWith(
                color: InventoryDesignConfig.primaryColor,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText:
                    'Discount Value (${_discountType == 'percentage' ? '%' : 'AED'})',
                labelStyle: InventoryDesignConfig.bodyMedium,
                filled: true,
                fillColor: InventoryDesignConfig.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                  borderSide: BorderSide(
                    color: InventoryDesignConfig.borderPrimary,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                  borderSide: BorderSide(
                    color: InventoryDesignConfig.borderPrimary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusS,
                  ),
                  borderSide: BorderSide(
                    color: InventoryDesignConfig.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscountTypeButton(String type, String label) {
    final isSelected = _discountType == type;
    return Expanded(
      child: Material(
        color:
            isSelected
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
            child: Center(
              child: Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected
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

  // Helper for financial summary rows
  Widget _buildFinancialRow(
    String label,
    double value,
    bool isTotal, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: InventoryDesignConfig.spacingXS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isTotal
                    ? InventoryDesignConfig.titleMedium
                    : InventoryDesignConfig.bodyMedium)
                .copyWith(
                  color: color ?? InventoryDesignConfig.textPrimary,
                  fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
          Text(
            NumberFormat.currency(
              symbol: 'AED ',
              decimalDigits: 2,
            ).format(value),
            style: (isTotal
                    ? InventoryDesignConfig.titleMedium
                    : InventoryDesignConfig.bodyMedium)
                .copyWith(
                  color: color ?? InventoryDesignConfig.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  // Original helper widget for textual financial summary rows (kept for compatibility)
  Widget _buildFinancialSummaryRow({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: InventoryDesignConfig.spacingS,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: InventoryDesignConfig.textSecondary),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Text(
              label,
              style: InventoryDesignConfig.bodyLarge.copyWith(
                color: InventoryDesignConfig.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            NumberFormat.currency(
              symbol: 'AED ',
              decimalDigits: 2,
            ).format(value),
            style: InventoryDesignConfig.bodyLarge.copyWith(
              color: InventoryDesignConfig.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Add Product Button
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
                    PhosphorIcons.shoppingBag(),
                    size: 16,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Expanded(
                  child: Text(
                    'Items (${_selectedProducts.length + _selectedKandoras.length})',
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      color: InventoryDesignConfig.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Add Product Button
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: InkWell(
                    onTap: _addProduct,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: InventoryDesignConfig.spacingM,
                        vertical: InventoryDesignConfig.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.primaryColor,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusM,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.plus(),
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: InventoryDesignConfig.spacingS),
                          Text(
                            'Product',
                            style: InventoryDesignConfig.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product List
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: _buildProductList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_selectedProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
        decoration: BoxDecoration(
          color: InventoryDesignConfig.warningColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          border: Border.all(
            color: InventoryDesignConfig.warningColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.warningColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.warning(),
                  size: 32,
                  color: InventoryDesignConfig.warningColor,
                ),
              ),
              const SizedBox(height: InventoryDesignConfig.spacingM),
              Text(
                'No products added yet',
                style: InventoryDesignConfig.bodyLarge.copyWith(
                  color: InventoryDesignConfig.warningColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'At least 1 product is required for invoice creation',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: InventoryDesignConfig.spacingM),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _addProduct,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.plus(),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add Products Now',
                          style: InventoryDesignConfig.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 280),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _selectedProducts.length,
        itemBuilder: (context, index) {
          final product = _selectedProducts[index];
          final isFabric = product.inventoryType == 'fabric';

          return Container(
            margin: const EdgeInsets.only(
              bottom: InventoryDesignConfig.spacingS,
            ),
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              border: Border.all(
                color: InventoryDesignConfig.borderPrimary,
                width: 1,
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
                // Color Swatch & Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isFabric && product.description != null
                            ? _parseColor(product.description)
                            : InventoryDesignConfig.primaryColor.withOpacity(
                              0.1,
                            ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: InventoryDesignConfig.borderPrimary.withOpacity(
                        0.5,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isFabric
                        ? PhosphorIcons.scissors()
                        : PhosphorIcons.package(),
                    size: 16,
                    color:
                        isFabric && product.description != null
                            ? _getContrastColor(
                              _parseColor(product.description),
                            )
                            : InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        style: InventoryDesignConfig.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: InventoryDesignConfig.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Quantity & Unit Price Row
                      Row(
                        children: [
                          // Quantity Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: InventoryDesignConfig.primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${product.quantity.toStringAsFixed(isFabric ? 1 : 0)} ${product.unit}',
                              style: InventoryDesignConfig.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: InventoryDesignConfig.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Unit Price
                          Text(
                            '× ${NumberFormat.currency(symbol: 'AED ', decimalDigits: 0).format(product.unitPrice)}',
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color: InventoryDesignConfig.textSecondary,
                              fontSize: 11,
                            ),
                          ),

                          // Color Name for Fabrics
                          if (isFabric && product.description != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _parseColor(product.description),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: InventoryDesignConfig.borderPrimary,
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Total Price & Remove Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat.currency(
                        symbol: 'AED ',
                        decimalDigits: 0,
                      ).format(product.totalPrice),
                      style: InventoryDesignConfig.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: InventoryDesignConfig.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        onTap: () => _removeProduct(index),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            PhosphorIcons.trash(),
                            size: 14,
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
        },
      ),
    );
  }

  // Helper to parse color codes
  Color _parseColor(String colorCode) {
    if (colorCode.isEmpty) return Colors.grey;
    try {
      if (colorCode.startsWith('#')) {
        String hex = colorCode.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        }
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  // Helper to get contrasting color for text on colored backgrounds
  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we should use light or dark text
    double luminance =
        (0.299 * backgroundColor.red +
            0.587 * backgroundColor.green +
            0.114 * backgroundColor.blue) /
        255;
    return luminance > 0.5 ? Colors.black : Colors.white;
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

          // Preview Invoice Button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _isLoading ? null : _previewInvoice,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.warningColor,
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  border: Border.all(
                    color: InventoryDesignConfig.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.eye(), size: 16, color: Colors.white),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      'Preview PDF',
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

          const SizedBox(width: InventoryDesignConfig.spacingL),

          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _isLoading ? null : _saveInvoice,
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
                      Icon(
                        _isEditMode
                            ? PhosphorIcons.floppyDisk()
                            : PhosphorIcons.check(),
                        size: 16,
                        color: Colors.white,
                      ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      _isLoading
                          ? (_isEditMode ? 'Updating...' : 'Saving...')
                          : (_isEditMode ? 'Update Invoice' : 'Create Invoice'),
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
        mainAxisSize: MainAxisSize.min, // Use min to avoid infinite height
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
              mainAxisSize: MainAxisSize.min, // Use min here too
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWithInvoiceNumber(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                Expanded(
                  child: Text(
                    title,
                    style: InventoryDesignConfig.titleMedium.copyWith(
                      color: InventoryDesignConfig.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Invoice Number Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: InventoryDesignConfig.spacingM,
                    vertical: InventoryDesignConfig.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(
                      0.2,
                    ), // Increased opacity
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color: InventoryDesignConfig.primaryColor.withOpacity(
                        0.4,
                      ), // Stronger border
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: InventoryDesignConfig.primaryColor.withOpacity(
                          0.1,
                        ), // Slightly stronger shadow
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    _invoiceNumberController.text.isEmpty
                        ? 'Auto-generated'
                        : '# ${_invoiceNumberController.text}',
                    style: InventoryDesignConfig.headlineMedium.copyWith(
                      color: InventoryDesignConfig.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
    bool readOnly = false,
    ValueChanged<String>? onChanged,
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
          readOnly: readOnly,
          onChanged: onChanged,
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

  Widget _buildDateField({
    required String label,
    required String hint,
    required IconData icon,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    String? Function(String?)? validator,
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
          readOnly: true,
          controller: TextEditingController(
            text:
                selectedDate == null
                    ? ''
                    : DateFormat('MMM d, yyyy').format(selectedDate),
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
            suffixIcon: Icon(
              PhosphorIcons.calendar(),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical: InventoryDesignConfig.spacingM,
            ),
          ),
          onTap: onTap,
          validator: validator,
        ),
      ],
    );
  }

  // Enhanced styled date field with better design
  Widget _buildStyledDateField({
    required String label,
    required String hint,
    required IconData icon,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    String? Function(String?)? validator,
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
                vertical: InventoryDesignConfig.spacingM + 2,
              ),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                border: Border.all(
                  color: InventoryDesignConfig.borderPrimary,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
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
                      selectedDate == null
                          ? hint
                          : DateFormat(
                            'EEEE, MMM d, yyyy',
                          ).format(selectedDate), // Enhanced date format
                      style:
                          selectedDate != null
                              ? InventoryDesignConfig.bodyLarge.copyWith(
                                color: InventoryDesignConfig.textPrimary,
                                fontWeight: FontWeight.w500,
                              )
                              : InventoryDesignConfig.bodyMedium.copyWith(
                                color: InventoryDesignConfig.textTertiary,
                              ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(
                      InventoryDesignConfig.spacingXS,
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
                      PhosphorIcons.calendar(),
                      size: 14,
                      color: InventoryDesignConfig.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (validator != null)
          Builder(
            builder: (context) {
              final error = validator(selectedDate?.toString());
              if (error != null) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: InventoryDesignConfig.spacingS,
                  ),
                  child: Text(
                    error,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.errorColor,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
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
    final validValue = items.any((item) => item.value == value) ? value : null;

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
          value: validValue,
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

  Widget _buildSelectorField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required VoidCallback onTap,
    String? Function(String?)? validator,
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

  Widget _buildModernPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          height: 40, // Match other elements height
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: InventoryDesignConfig.buttonPrimaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: Colors.white,
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

// PDF Preview Dialog
class _InvoicePdfPreviewDialog extends StatelessWidget {
  final Uint8List pdfBytes;
  final String invoiceNumber;

  const _InvoicePdfPreviewDialog({
    required this.pdfBytes,
    required this.invoiceNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width:
            (MediaQuery.of(context).size.height * 0.9) *
            (PdfPageFormat.a4.width / PdfPageFormat.a4.height),
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: InventoryDesignConfig.surfaceColor,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceAccent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(InventoryDesignConfig.radiusXL),
                  topRight: Radius.circular(InventoryDesignConfig.radiusXL),
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
                      PhosphorIcons.filePdf(),
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
                          'Invoice Preview',
                          style: InventoryDesignConfig.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Invoice #$invoiceNumber',
                          style: InventoryDesignConfig.bodyMedium.copyWith(
                            color: InventoryDesignConfig.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                    child: InkWell(
                      onTap:
                          () => Printing.sharePdf(
                            bytes: pdfBytes,
                            filename: 'invoice_$invoiceNumber.pdf',
                          ),
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(
                          InventoryDesignConfig.spacingS,
                        ),
                        child: Icon(
                          PhosphorIcons.share(),
                          size: 18,
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                    child: InkWell(
                      onTap:
                          () => Printing.layoutPdf(
                            onLayout: (format) => pdfBytes,
                          ),
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(
                          InventoryDesignConfig.spacingS,
                        ),
                        child: Icon(
                          PhosphorIcons.printer(),
                          size: 18,
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(
                          InventoryDesignConfig.spacingS,
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
            // PDF Preview
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(InventoryDesignConfig.radiusXL),
                  bottomRight: Radius.circular(InventoryDesignConfig.radiusXL),
                ),
                child: PdfPreview(
                  build: (format) => pdfBytes,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  pdfFileName: 'invoice_$invoiceNumber.pdf',
                  // Make the preview page fit the available width
                  maxPageWidth:
                      (MediaQuery.of(context).size.height * 0.9) *
                      (PdfPageFormat.a4.width / PdfPageFormat.a4.height),
                  // Remove extra decorations to make the PDF the main view
                  previewPageMargin: const EdgeInsets.all(0),
                  scrollViewDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            // Footer with action buttons
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
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
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: InventoryDesignConfig.spacingL,
                          vertical: InventoryDesignConfig.spacingM,
                        ),
                        decoration:
                            InventoryDesignConfig.buttonSecondaryDecoration,
                        child: Text(
                          'Close',
                          style: InventoryDesignConfig.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    child: InkWell(
                      onTap:
                          () => Printing.sharePdf(
                            bytes: pdfBytes,
                            filename: 'invoice_$invoiceNumber.pdf',
                          ),
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: InventoryDesignConfig.spacingL,
                          vertical: InventoryDesignConfig.spacingM,
                        ),
                        decoration: BoxDecoration(
                          color: InventoryDesignConfig.successColor,
                          borderRadius: BorderRadius.circular(
                            InventoryDesignConfig.radiusM,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.share(),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(
                              width: InventoryDesignConfig.spacingS,
                            ),
                            Text(
                              'Share PDF',
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
                  const SizedBox(width: InventoryDesignConfig.spacingM),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    child: InkWell(
                      onTap:
                          () => Printing.layoutPdf(
                            onLayout: (format) => pdfBytes,
                          ),
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: InventoryDesignConfig.spacingL,
                          vertical: InventoryDesignConfig.spacingM,
                        ),
                        decoration:
                            InventoryDesignConfig.buttonPrimaryDecoration,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.printer(),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(
                              width: InventoryDesignConfig.spacingS,
                            ),
                            Text(
                              'Print PDF',
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
            ),
          ],
        ),
      ),
    );
  }
}
