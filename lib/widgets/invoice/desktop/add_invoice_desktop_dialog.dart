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
  final VoidCallback? onInvoiceAdded;

  const AddInvoiceDesktopDialog({super.key, this.onInvoiceAdded});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onInvoiceAdded,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AddInvoiceDesktopDialog(onInvoiceAdded: onInvoiceAdded),
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

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  Measurement? _selectedMeasurement;
  final List<InvoiceProduct> _selectedProducts = [];
  bool _showAdvancedOptions = false;

  // Controllers
  final _invoiceNumberController = TextEditingController();
  final _detailsController = TextEditingController();
  final _vatController = TextEditingController(text: '5');
  final _advanceController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _additionalFeesController = TextEditingController(text: '0');

  // Dates
  DateTime _invoiceDate = DateTime.now();
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));

  // Statuses
  String _deliveryStatus = 'pending';
  String _paymentStatus = 'unpaid';

  // Calculated Totals
  double _subtotal = 0;
  double _vatAmount = 0;
  double _netTotal = 0;
  double _balance = 0;
  double _discount = 0;
  double _additionalFees = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _vatController.addListener(_calculateTotals);
    _advanceController.addListener(_calculateTotals);
    _discountController.addListener(_calculateTotals);
    _additionalFeesController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _detailsController.dispose();
    _vatController.dispose();
    _advanceController.dispose();
    _discountController.dispose();
    _additionalFeesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _customerService.getAllCustomers(),
        _invoiceService.generateInvoiceNumber(),
      ]);

      if (mounted) {
        setState(() {
          _customers = results[0] as List<Customer>;
          _invoiceNumberController.text = results[1] as String;
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

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: InventoryDesignConfig.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      _showErrorSnackbar('Please select a customer');
      return;
    }
    if (_selectedProducts.isEmpty) {
      _showErrorSnackbar('Please add at least one product');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Convert InvoiceProduct to Product objects
      final products =
          _selectedProducts
              .map(
                (invoiceProduct) => Product(
                  name: invoiceProduct.name,
                  price: invoiceProduct.unitPrice,
                ),
              )
              .toList();

      final invoice = Invoice(
        id: const Uuid().v4(),
        invoiceNumber: _invoiceNumberController.text,
        date: _invoiceDate,
        deliveryDate: _deliveryDate,
        amount: _subtotal,
        vat: _vatAmount,
        amountIncludingVat: _netTotal,
        netTotal: _netTotal,
        advance: double.tryParse(_advanceController.text) ?? 0,
        balance: _balance,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        customerPhone: _selectedCustomer!.phone,
        details: _detailsController.text,
        customerBillNumber: _selectedCustomer!.billNumber,
        measurementId: _selectedMeasurement?.id,
        measurementName: _selectedMeasurement?.style,
        // Convert string to enum by finding matching enum value
        deliveryStatus: InvoiceStatus.values.firstWhere(
          (status) => status.name == _deliveryStatus,
          orElse: () => InvoiceStatus.pending, // Default fallback
        ),
        paymentStatus: PaymentStatus.values.firstWhere(
          (status) => status.name == _paymentStatus,
          orElse: () => PaymentStatus.unpaid, // Default fallback
        ),
        products: products, // Pass as List<Product>
      );

      await _invoiceService.addInvoice(invoice);

      if (mounted) {
        widget.onInvoiceAdded?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invoice created successfully'),
            backgroundColor: InventoryDesignConfig.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error creating invoice: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.85; // Reduced from 0.9
    final maxWidth = screenSize.width * 0.75; // Reduced from wider

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth > 1000 ? 1000 : maxWidth, // Reduced from 1400
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child:
              _isLoading
                  ? _buildLoadingState()
                  : Column(
                    children: [
                      _buildCompactHeader(),
                      Expanded(child: _buildCompactTwoPanelLayout()),
                      _buildCompactFooter(),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: InventoryDesignConfig.primaryColor,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Text(
              'Loading invoice data...',
              style: InventoryDesignConfig.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      height: 56, // Reduced from 64
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXL, // Reduced from XXL
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
            width: 32, // Reduced from 36
            height: 32,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8), // Reduced radius
            ),
            child: Icon(
              PhosphorIcons.receipt(),
              size: 16, // Reduced from 18
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(
            width: InventoryDesignConfig.spacingM,
          ), // Reduced spacing
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Invoice',
                  style: InventoryDesignConfig.titleLarge.copyWith(
                    // Reduced from headlineMedium
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Generate invoice with products and services',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    // Reduced from bodyMedium
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6), // Reduced radius
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6), // Reduced padding
                child: Icon(
                  PhosphorIcons.x(),
                  size: 16,
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTwoPanelLayout() {
    return Row(
      children: [
        // Left Panel - Form (55% instead of 60%)
        Expanded(flex: 55, child: _buildCompactLeftPanel()),

        // Divider
        Container(width: 1, color: InventoryDesignConfig.borderSecondary),

        // Right Panel - Products (45% instead of 40%)
        Expanded(flex: 45, child: _buildCompactRightPanel()),
      ],
    );
  }

  Widget _buildCompactLeftPanel() {
    return Container(
      color: InventoryDesignConfig.surfaceColor,
      child: Column(
        children: [
          // Compact Panel Header
          Container(
            height: 40, // Reduced from 50
            padding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL, // Reduced padding
            ),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(
                  color: InventoryDesignConfig.borderSecondary,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.user(),
                  size: 14, // Reduced size
                  color: InventoryDesignConfig.primaryColor,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingS),
                Text(
                  'Invoice Details & Customer',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content with reduced padding
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(
                InventoryDesignConfig.spacingL,
              ), // Reduced from XXL
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Selection - more compact
                    _buildCompactCustomerSection(),

                    const SizedBox(
                      height: InventoryDesignConfig.spacingL,
                    ), // Reduced spacing
                    // Invoice Information
                    _buildCompactInvoiceDetailsSection(),

                    const SizedBox(height: InventoryDesignConfig.spacingL),

                    // Status Configuration
                    _buildCompactStatusSection(),

                    const SizedBox(height: InventoryDesignConfig.spacingL),

                    // Financial Settings
                    _buildCompactFinancialSection(),

                    const SizedBox(height: InventoryDesignConfig.spacingL),

                    // Additional Information
                    _buildCompactAdditionalInfoSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRightPanel() {
    return Container(
      color: InventoryDesignConfig.surfaceLight,
      child: Column(
        children: [
          // Compact Panel Header
          Container(
            height: 40, // Reduced from 50
            padding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingM, // Reduced padding
            ),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(
                  color: InventoryDesignConfig.borderSecondary,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.package(),
                  size: 14,
                  color: InventoryDesignConfig.primaryColor,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingS),
                Text(
                  'Products',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, // Reduced padding
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4), // Reduced radius
                  ),
                  child: Text(
                    '${_selectedProducts.length}',
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10, // Smaller font
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Compact Product Actions
          Container(
            padding: const EdgeInsets.all(
              InventoryDesignConfig.spacingM,
            ), // Reduced padding
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: InventoryDesignConfig.borderSecondary,
                ),
              ),
            ),
            child: _buildCompactProductActions(),
          ),

          // Products List
          Expanded(
            child:
                _selectedProducts.isEmpty
                    ? _buildCompactEmptyProductsState()
                    : _buildCompactProductsList(),
          ),

          // Financial Summary
          _buildCompactFinancialSummary(),
        ],
      ),
    );
  }

  Widget _buildCompactCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact section header
        Row(
          children: [
            Icon(
              PhosphorIcons.user(),
              size: 14,
              color: InventoryDesignConfig.primaryColor,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Text(
              'Customer Information',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildCustomerSelector(),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildMeasurementSelector(),
      ],
    );
  }

  Widget _buildCompactInvoiceDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact section header
        Row(
          children: [
            Icon(
              PhosphorIcons.receipt(),
              size: 14,
              color: InventoryDesignConfig.primaryColor,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Text(
              'Invoice Details',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        // Compact row layout
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _invoiceNumberController,
                label: 'Invoice Number',
                hint: 'INV-001',
                icon: PhosphorIcons.hash(),
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Invoice number is required'
                            : null,
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildCompactDateField(
                label: 'Invoice Date',
                date: _invoiceDate,
                onDateSelected: (date) => setState(() => _invoiceDate = date),
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildCompactDateField(
          label: 'Delivery Date',
          date: _deliveryDate,
          onDateSelected: (date) => setState(() => _deliveryDate = date),
        ),
      ],
    );
  }

  Widget _buildCompactStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIcons.gear(),
              size: 14,
              color: InventoryDesignConfig.primaryColor,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Text(
              'Status',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildCompactStatusDropdown(
                label: 'Delivery',
                value: _deliveryStatus,
                items: const ['pending', 'in_progress', 'delivered'],
                onChanged: (val) => setState(() => _deliveryStatus = val!),
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildCompactStatusDropdown(
                label: 'Payment',
                value: _paymentStatus,
                items: const ['unpaid', 'partial', 'paid'],
                onChanged: (val) => setState(() => _paymentStatus = val!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactFinancialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIcons.currencyDollar(),
              size: 14,
              color: InventoryDesignConfig.primaryColor,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Text(
              'Financial',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Compact toggle
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    () => setState(
                      () => _showAdvancedOptions = !_showAdvancedOptions,
                    ),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 6.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showAdvancedOptions
                            ? PhosphorIcons.caretUp()
                            : PhosphorIcons.caretDown(),
                        size: 12,
                        color: InventoryDesignConfig.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showAdvancedOptions ? "Less" : "More",
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _vatController,
                label: 'VAT (%)',
                hint: '5',
                icon: PhosphorIcons.percent(),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'VAT required';
                  final vat = double.tryParse(value);
                  if (vat == null || vat < 0 || vat > 100) return 'Valid VAT %';
                  return null;
                },
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildCompactTextField(
                controller: _advanceController,
                label: 'Advance',
                hint: '0.00',
                icon: PhosphorIcons.wallet(),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Advance required';
                  final advance = double.tryParse(value);
                  if (advance == null || advance < 0) return 'Valid amount';
                  return null;
                },
              ),
            ),
          ],
        ),
        if (_showAdvancedOptions) ...[
          const SizedBox(height: InventoryDesignConfig.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildCompactTextField(
                  controller: _discountController,
                  label: 'Discount',
                  hint: '0.00',
                  icon: PhosphorIcons.tag(),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: _buildCompactTextField(
                  controller: _additionalFeesController,
                  label: 'Fees',
                  hint: '0.00',
                  icon: PhosphorIcons.plus(),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCompactAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIcons.notepad(),
              size: 14,
              color: InventoryDesignConfig.primaryColor,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Text(
              'Notes',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildCompactTextField(
          controller: _detailsController,
          label: 'Additional Details',
          hint: 'Enter notes...',
          maxLines: 2, // Reduced from 3
          icon: PhosphorIcons.note(),
        ),
      ],
    );
  }

  Widget _buildCompactProductActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactActionButton(
                icon: PhosphorIcons.scissors(),
                label: 'Fabric',
                color: InventoryDesignConfig.infoColor,
                onPressed: () => _addFromInventory('fabric'),
              ),
            ),
            const SizedBox(width: 6), // Reduced spacing
            Expanded(
              child: _buildCompactActionButton(
                icon: PhosphorIcons.package(),
                label: 'Access.',
                color: InventoryDesignConfig.successColor,
                onPressed: () => _addFromInventory('accessory'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: _buildCompactActionButton(
            icon: PhosphorIcons.plus(),
            label: 'Custom',
            color: InventoryDesignConfig.warningColor,
            onPressed: _addCustomProduct,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6), // Reduced radius
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8, // Reduced padding
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color), // Reduced icon size
              const SizedBox(width: 4), // Reduced spacing
              Text(
                label,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  // Smaller text
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactEmptyProductsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16), // Reduced padding
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(12), // Reduced radius
            ),
            child: Icon(
              PhosphorIcons.package(),
              size: 24, // Reduced size
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: 12), // Reduced spacing
          Text(
            'No products',
            style: InventoryDesignConfig.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add products to continue',
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProductsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(
        InventoryDesignConfig.spacingM,
      ), // Reduced padding
      itemCount: _selectedProducts.length,
      separatorBuilder:
          (context, index) => const SizedBox(
            height: InventoryDesignConfig.spacingS,
          ), // Reduced spacing
      itemBuilder:
          (context, index) =>
              _buildCompactProductCard(_selectedProducts[index], index),
    );
  }

  Widget _buildCompactProductCard(InvoiceProduct product, int index) {
    return Container(
      padding: const EdgeInsets.all(10), // Reduced padding
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(8), // Reduced radius
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header
          Row(
            children: [
              Container(
                width: 24, // Reduced size
                height: 24,
                decoration: BoxDecoration(
                  color:
                      (product.inventoryType ?? 'custom') == 'fabric'
                          ? InventoryDesignConfig.infoColor.withOpacity(0.1)
                          : InventoryDesignConfig.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4), // Reduced radius
                  border: Border.all(
                    color:
                        (product.inventoryType ?? 'custom') == 'fabric'
                            ? InventoryDesignConfig.infoColor.withOpacity(0.3)
                            : InventoryDesignConfig.successColor.withOpacity(
                              0.3,
                            ),
                  ),
                ),
                child: Icon(
                  (product.inventoryType ?? 'custom') == 'fabric'
                      ? PhosphorIcons.scissors()
                      : PhosphorIcons.package(),
                  size: 12, // Reduced size
                  color:
                      (product.inventoryType ?? 'custom') == 'fabric'
                          ? InventoryDesignConfig.infoColor
                          : InventoryDesignConfig.successColor,
                ),
              ),
              const SizedBox(width: 8), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13, // Smaller font
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.description.isNotEmpty) ...[
                      Text(
                        product.description,
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                          fontSize: 10, // Smaller font
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeProduct(index),
                icon: Icon(
                  PhosphorIcons.trash(),
                  size: 12, // Reduced size
                  color: InventoryDesignConfig.errorColor,
                ),
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ), // Smaller button
                padding: const EdgeInsets.all(2),
              ),
            ],
          ),

          const SizedBox(height: 8), // Reduced spacing
          // Compact quantity and price row
          Row(
            children: [
              // Compact quantity controls
              Container(
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceAccent,
                  borderRadius: BorderRadius.circular(4), // Reduced radius
                  border: Border.all(
                    color: InventoryDesignConfig.borderPrimary,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap:
                          product.quantity > 0.5
                              ? () => _updateProductQuantity(
                                index,
                                product.quantity -
                                    ((product.inventoryType == 'fabric')
                                        ? 0.5
                                        : 1.0),
                              )
                              : null,
                      child: Container(
                        padding: const EdgeInsets.all(4), // Reduced padding
                        child: Icon(
                          PhosphorIcons.minus(),
                          size: 10, // Reduced size
                          color:
                              product.quantity > 0.5
                                  ? InventoryDesignConfig.textSecondary
                                  : InventoryDesignConfig.textTertiary,
                        ),
                      ),
                    ),
                    Container(
                      width: 32, // Reduced width
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        product.quantity % 1 == 0
                            ? product.quantity.toInt().toString()
                            : product.quantity.toStringAsFixed(1),
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    InkWell(
                      onTap:
                          () => _updateProductQuantity(
                            index,
                            product.quantity +
                                ((product.inventoryType == 'fabric')
                                    ? 0.5
                                    : 1.0),
                          ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          PhosphorIcons.plus(),
                          size: 10,
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8), // Reduced spacing
              // Compact price info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat.currency(symbol: 'AED ').format(product.unitPrice)}/${product.unit}',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        symbol: 'AED ',
                      ).format(product.totalPrice),
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: InventoryDesignConfig.successColor,
                        fontSize: 12,
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

  Widget _buildCompactFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(
        InventoryDesignConfig.spacingM,
      ), // Reduced padding
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
                PhosphorIcons.calculator(),
                size: 14,
                color: InventoryDesignConfig.primaryColor,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Summary',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          _buildCompactSummaryRow('Subtotal', _subtotal),
          if (_discount > 0)
            _buildCompactSummaryRow('Discount', _discount, isNegative: true),
          if (_additionalFees > 0)
            _buildCompactSummaryRow('Fees', _additionalFees),
          _buildCompactSummaryRow('VAT (${_vatController.text}%)', _vatAmount),
          const Divider(
            color: InventoryDesignConfig.borderSecondary,
            height: 16,
          ),
          _buildCompactSummaryRow('Total', _netTotal, isTotal: true),
          _buildCompactSummaryRow(
            'Advance',
            double.tryParse(_advanceController.text) ?? 0,
          ),
          _buildCompactSummaryRow('Balance', _balance, isBalance: true),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isBalance = false,
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2), // Reduced padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: InventoryDesignConfig.bodySmall.copyWith(
              // Smaller text
              fontWeight:
                  isTotal || isBalance ? FontWeight.w700 : FontWeight.w500,
              color:
                  isBalance
                      ? InventoryDesignConfig.warningColor
                      : InventoryDesignConfig.textPrimary,
              fontSize: 11,
            ),
          ),
          Text(
            NumberFormat.currency(
              symbol: 'AED ',
            ).format(isNegative ? -amount : amount),
            style: InventoryDesignConfig.bodySmall.copyWith(
              fontWeight:
                  isTotal || isBalance ? FontWeight.w700 : FontWeight.w500,
              color:
                  isBalance
                      ? InventoryDesignConfig.warningColor
                      : isTotal
                      ? InventoryDesignConfig.primaryColor
                      : isNegative
                      ? InventoryDesignConfig.errorColor
                      : InventoryDesignConfig.textPrimary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFooter() {
    return Container(
      height: 60, // Reduced from 72
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXL, // Reduced padding
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
            borderRadius: BorderRadius.circular(6), // Reduced radius
            child: InkWell(
              onTap: _isSaving ? null : () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingL, // Reduced padding
                  vertical: 10, // Reduced padding
                ),
                decoration: InventoryDesignConfig.buttonSecondaryDecoration,
                child: Text(
                  'Cancel',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13, // Smaller font
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: _isSaving ? null : _saveInvoice,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingL,
                  vertical: 10,
                ),
                decoration: InventoryDesignConfig.buttonPrimaryDecoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving)
                      const SizedBox(
                        width: 14, // Reduced size
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        PhosphorIcons.receipt(),
                        size: 14,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 6), // Reduced spacing
                    Text(
                      _isSaving ? 'Creating...' : 'Create Invoice',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
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

  // Compact text field component
  Widget _buildCompactTextField({
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
          style: InventoryDesignConfig.bodySmall.copyWith(
            // Smaller label
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4), // Reduced spacing
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: InventoryDesignConfig.bodyMedium.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontSize: 13, // Smaller font
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: InventoryDesignConfig.bodySmall.copyWith(
              color: InventoryDesignConfig.textTertiary,
              fontSize: 12,
            ),
            prefixIcon: Icon(
              icon,
              size: 16, // Reduced icon size
              color: InventoryDesignConfig.textSecondary,
            ),
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6), // Reduced radius
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: InventoryDesignConfig.errorColor,
                width: 2.0,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10, // Reduced padding
              vertical: maxLines > 1 ? 10 : 8,
            ),
            isDense: true, // More compact
          ),
        ),
      ],
    );
  }

  // Compact date field
  Widget _buildCompactDateField({
    required String label,
    required DateTime date,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: () async {
              final newDate = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (newDate != null) onDateSelected(newDate);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ), // Reduced padding
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.calendar(),
                    size: 16,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Compact status dropdown
  Widget _buildCompactStatusDropdown({
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
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          style: InventoryDesignConfig.bodyMedium.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontSize: 13,
          ),
          dropdownColor: InventoryDesignConfig.surfaceColor,
          decoration: InputDecoration(
            filled: true,
            fillColor: InventoryDesignConfig.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: InventoryDesignConfig.primaryColor,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            isDense: true,
          ),
          items:
              items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.replaceAll('_', ' ').toUpperCase(),
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      fontSize: 13,
                    ),
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
                color:
                    isEnabled
                        ? InventoryDesignConfig.surfaceLight
                        : InventoryDesignConfig.surfaceAccent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                border: Border.all(
                  color:
                      value != null && isEnabled
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
                    color:
                        isEnabled
                            ? InventoryDesignConfig.textSecondary
                            : InventoryDesignConfig.textTertiary,
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
                                color:
                                    isEnabled
                                        ? InventoryDesignConfig.textTertiary
                                        : InventoryDesignConfig.textTertiary
                                            .withOpacity(0.5),
                              ),
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretDown(),
                    size: 16,
                    color:
                        isEnabled
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

  // Action methods
  void _calculateTotals() {
    _subtotal = _selectedProducts.fold(
      0.0,
      (sum, product) => sum + product.totalPrice,
    );

    _discount = double.tryParse(_discountController.text) ?? 0;
    _additionalFees = double.tryParse(_additionalFeesController.text) ?? 0;

    final discountedSubtotal = _subtotal - _discount + _additionalFees;

    final vatRate = double.tryParse(_vatController.text) ?? 0;
    _vatAmount = discountedSubtotal * (vatRate / 100);
    _netTotal = discountedSubtotal + _vatAmount;

    final advance = double.tryParse(_advanceController.text) ?? 0;
    _balance = _netTotal - advance;

    setState(() {});
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
      builder:
          (context) => AlertDialog(
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
                      labelText: 'Unit Price (AED)',
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
                      'quantity':
                          double.tryParse(quantityController.text) ?? 1.0,
                      'unit':
                          unitController.text.isNotEmpty
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
