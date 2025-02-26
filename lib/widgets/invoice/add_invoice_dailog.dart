import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../models/measurement.dart';
import '../../services/measurement_service.dart';
import '../../services/invoice_service.dart';
import '../../services/customer_service.dart';

class InvoiceScreen extends StatefulWidget {
  final Customer? customer;
  final Invoice? invoiceToEdit; // Add this

  const InvoiceScreen({
    super.key, 
    this.customer,
    this.invoiceToEdit, // Add this
  });

  static Future<void> show(BuildContext context, {Customer? customer, Invoice? invoice}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: screenWidth * 0.60,
            height: MediaQuery.of(context).size.height * 0.9,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: InvoiceScreen(
              customer: customer,
              invoiceToEdit: invoice,
            ),
          ),
        ),
      );
    }

    // Full screen for mobile
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => InvoiceScreen(
          customer: customer,
          invoiceToEdit: invoice,
        ),
      ),
    );
  }

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _deliveryDateController = TextEditingController();
  final _amountController = TextEditingController();
  final _advanceController = TextEditingController();
  final _detailsController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();

  double _amount = 0;
  double _advance = 0;
  DateTime? _date;
  DateTime? _deliveryDate;
  Customer? _selectedCustomer;
  Measurement? _selectedMeasurement;

  late AnimationController _animationController;
  late Animation<double> _animation;

  // Add services
  final SupabaseService _supabaseService = SupabaseService();
  final MeasurementService _measurementService = MeasurementService();
  final InvoiceService _invoiceService = InvoiceService();

  List<Product> _products = [];

  final String _draftKey = "add_invoice_dialog_draft";

  // Save draft state
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftData = {
      "date": _dateController.text,
      "deliveryDate": _deliveryDateController.text,
      "amount": _amountController.text,
      "advance": _advanceController.text,
      "details": _detailsController.text,
      "customerName": _customerNameController.text,
      "customerPhone": _customerPhoneController.text,
    };
    prefs.setString(_draftKey, jsonEncode(draftData));
  }

  // Load draft state
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_draftKey)) {
      final draftData = jsonDecode(prefs.getString(_draftKey)!);
      setState(() {
        _dateController.text = draftData["date"] ?? "";
        _deliveryDateController.text = draftData["deliveryDate"] ?? "";
        _amountController.text = draftData["amount"] ?? "";
        _advanceController.text = draftData["advance"] ?? "";
        _detailsController.text = draftData["details"] ?? "";
        _customerNameController.text = draftData["customerName"] ?? "";
        _customerPhoneController.text = draftData["customerPhone"] ?? "";
      });
    }
  }

  // Clear draft state
  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_draftKey);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _selectedCustomer = widget.customer;
    if (_selectedCustomer != null) {
      _customerNameController.text = _selectedCustomer!.name;
      _customerPhoneController.text = _selectedCustomer!.phone;
    }
    _date = DateTime.now();
    _deliveryDate = _date?.add(const Duration(days: 7));
    _dateController.text = DateFormat('dd/MM/yyyy').format(_date!);
    _deliveryDateController.text = DateFormat(
      'dd/MM/yyyy',
    ).format(_deliveryDate!);

    if (widget.invoiceToEdit != null) {
      // Populate fields with existing invoice data
      _selectedCustomer = Customer(
        id: widget.invoiceToEdit!.customerId,
        name: widget.invoiceToEdit!.customerName,
        phone: widget.invoiceToEdit!.customerPhone,
        billNumber: widget.invoiceToEdit!.customerBillNumber,
        address: '', // Add required address parameter
        gender: Gender.male, // Add required gender parameter, adjust as needed
      );
      _customerNameController.text = widget.invoiceToEdit!.customerName;
      _customerPhoneController.text = widget.invoiceToEdit!.customerPhone;
      _date = widget.invoiceToEdit!.date;
      _deliveryDate = widget.invoiceToEdit!.deliveryDate;
      _dateController.text = DateFormat('dd/MM/yyyy').format(_date!);
      _deliveryDateController.text = DateFormat('dd/MM/yyyy').format(_deliveryDate!);
      _amount = widget.invoiceToEdit!.amount;
      _amountController.text = _amount.toString();
      _advance = widget.invoiceToEdit!.advance;
      _advanceController.text = _advance.toString();
      _detailsController.text = widget.invoiceToEdit!.details;
      _products = widget.invoiceToEdit!.products;
      
      if (widget.invoiceToEdit!.measurementId != null) {
        // Load measurement if exists
        _loadExistingMeasurement();
      }
    }
    _loadDraft();
    // Attach listeners to auto-save changes
    final controllers = [
      _dateController,
      _deliveryDateController,
      _amountController,
      _advanceController,
      _detailsController,
      _customerNameController,
      _customerPhoneController,
    ];
    for (var controller in controllers) {
      controller.addListener(_saveDraft);
    }
  }

  Future<void> _loadExistingMeasurement() async {
    if (widget.invoiceToEdit?.measurementId != null) {
      final measurement = await _measurementService.getMeasurement(
        widget.invoiceToEdit!.measurementId!
      );
      if (measurement != null) {
        setState(() {
          _selectedMeasurement = measurement;
          _measurementName = _getMeasurementTitle(measurement);
          _measurementSubtitle = _getMeasurementSubtitle(measurement);
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dateController.dispose();
    _deliveryDateController.dispose();
    _amountController.dispose();
    _advanceController.dispose();
    _detailsController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomer() async {
    final result = await showDialog<Customer>(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: 600,
              height: 600,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Select Customer',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<Customer>>(
                      stream: _supabaseService.getCustomersStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final customers = snapshot.data ?? [];
                        return ListView.builder(
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            return ListTile(
                              title: Text(customer.name),
                              subtitle: Text(
                                'Bill #${customer.billNumber} • ${customer.phone}',
                              ),
                              onTap: () => Navigator.pop(context, customer),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (result != null) {
      setState(() {
        _selectedCustomer = result; // This is fine as we get a complete Customer object from the dialog
        _customerNameController.text = result.name;
        _customerPhoneController.text = result.phone;
      });
    }
  }

  String _getMeasurementTitle(Measurement measurement) {
    return measurement.style;
  }

  String _getMeasurementSubtitle(Measurement measurement) {
    final date = DateFormat('MMM dd').format(measurement.date);
    return 'Bill #${measurement.billNumber} • ${measurement.style} • $date';
  }

  Future<void> _selectMeasurement() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
      return;
    }

    final result = await showDialog<Measurement>(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: 600,
              height: 600,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Select Measurement',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<Measurement>>(
                      stream: _measurementService.getMeasurementsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final measurements = snapshot.data ?? [];
                        final customerMeasurements =
                            measurements
                                .where(
                                  (m) => m.customerId == _selectedCustomer!.id,
                                )
                                .toList();

                        if (customerMeasurements.isEmpty) {
                          return const Center(
                            child: Text(
                              'No measurements found for this customer',
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: customerMeasurements.length,
                          itemBuilder: (context, index) {
                            final measurement = customerMeasurements[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(measurement.style[0].toUpperCase()),
                              ),
                              title: Text(_getMeasurementTitle(measurement)),
                              subtitle: Text(
                                _getMeasurementSubtitle(measurement),
                              ),
                              onTap: () => Navigator.pop(context, measurement),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (result != null) {
      setState(() {
        _selectedMeasurement = result;
        _measurementName = _getMeasurementTitle(result);
        _measurementSubtitle = _getMeasurementSubtitle(result);
      });
    }
  }

  String _measurementName = '';
  String _measurementSubtitle = '';

  Future<void> _saveInvoice() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      try {
        final invoice = widget.invoiceToEdit?.id != null
            ? _updateExistingInvoice()
            : await _createNewInvoice();

        // Clear draft after successful save
        await _clearDraft();

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.invoiceToEdit != null
                  ? 'Invoice #${invoice.invoiceNumber} has been updated'
                  : 'Invoice #${invoice.invoiceNumber} has been created'
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<Invoice> _createNewInvoice() async {
    final invoiceNumber = await _invoiceService.generateInvoiceNumber();
    
    // Only include measurement details if a measurement is selected
    String? measurementId;
    String? measurementName;
    
    if (_selectedMeasurement != null) {
      measurementId = _selectedMeasurement!.id;
      measurementName = _getMeasurementSubtitle(_selectedMeasurement!);
    }

    final invoice = Invoice.create(
      invoiceNumber: invoiceNumber,
      date: _date!,
      deliveryDate: _deliveryDate!,
      amount: _amount,
      advance: _advance,
      customer: _selectedCustomer!,
      details: _detailsController.text,
      measurementId: measurementId,  // This will be null if no measurement is selected
      measurementName: measurementName,
      products: _products,
    );

    await _invoiceService.addInvoice(invoice);
    return invoice;
  }

  Invoice _updateExistingInvoice() {
    // Only include measurement details if a measurement is selected
    String? measurementId = _selectedMeasurement?.id;
    String? measurementName = _selectedMeasurement != null 
        ? _getMeasurementSubtitle(_selectedMeasurement!)
        : null;

    final updatedInvoice = Invoice(
      id: widget.invoiceToEdit!.id,
      invoiceNumber: widget.invoiceToEdit!.invoiceNumber,
      date: _date!,
      deliveryDate: _deliveryDate!,
      amount: _amount,
      vat: _amount * Invoice.vatRate,
      amountIncludingVat: _amount + (_amount * Invoice.vatRate),
      netTotal: _amount,
      advance: _advance,
      balance: (_amount + (_amount * Invoice.vatRate)) - _advance,
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      customerPhone: _selectedCustomer!.phone,
      details: _detailsController.text,
      customerBillNumber: _selectedCustomer!.billNumber,
      measurementId: measurementId,  // This will be null if no measurement is selected
      measurementName: measurementName,
      deliveryStatus: widget.invoiceToEdit!.deliveryStatus,
      paymentStatus: widget.invoiceToEdit!.paymentStatus,
      deliveredAt: widget.invoiceToEdit!.deliveredAt,
      paidAt: widget.invoiceToEdit!.paidAt,
      notes: widget.invoiceToEdit!.notes,
      payments: widget.invoiceToEdit!.payments,
      products: _products,
    );

    _invoiceService.updateInvoice(updatedInvoice);
    return updatedInvoice;
  }

  double get _vat => _amount * Invoice.vatRate;
  double get _amountIncludingVat => _amount + _vat;
  double get _balance => _amountIncludingVat - _advance;

  void _updateCalculations() {
    final productsTotal = _products.fold(0.0, (sum, product) => sum + product.price);
    setState(() {
      // Only update amount if it's zero or less than products total
      if (_amount == 0 || _amount < productsTotal) {
        _amount = productsTotal;
        _amountController.text = _amount.toString();
      }
    });
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to discard changes?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDesktop ? Colors.transparent : theme.colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.colorScheme.primaryContainer,
          shape: isDesktop 
            ? const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              )
            : null,
          automaticallyImplyLeading: false, // Disable default back button
          leading: isDesktop 
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  if (await _onWillPop()) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
          title: Text(
            widget.invoiceToEdit != null ? 'Edit Invoice' : 'Create Invoice',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (!isDesktop)
              TextButton.icon(
                onPressed: () async {
                  if (await _onWillPop()) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              )
            else
              FilledButton.icon(
                onPressed: _saveInvoice,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Generate'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            const SizedBox(width: 16),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: isDesktop 
              ? const BorderRadius.vertical(bottom: Radius.circular(28))
              : null,
          ),
          child: ClipRRect(
            borderRadius: isDesktop 
              ? const BorderRadius.vertical(bottom: Radius.circular(28))
              : BorderRadius.zero,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tax Invoice',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TRN: ${Invoice.trn}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date Section
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerField(
                              controller: _dateController,
                              label: 'Date',
                              initialDate: _date,
                              onDateSelected: (date) {
                                setState(() => _date = date);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DatePickerField(
                              controller: _deliveryDateController,
                              label: 'Delivery Date',
                              initialDate: _deliveryDate,
                              onDateSelected: (date) {
                                setState(() => _deliveryDate = date);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Amount Section
                      _buildAmountSection(),
                      const SizedBox(height: 24),

                      // Calculations Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCalculationRow('Amount:', _amount),
                            _buildCalculationRow(
                              'VAT (${(Invoice.vatRate * 100).toInt()}%):',
                              _vat,
                            ),
                            _buildCalculationRow(
                              'Amount Incl. VAT:',
                              _amountIncludingVat,
                            ),
                            _buildCalculationRow('Advance:', _advance),
                            const Divider(),
                            _buildCalculationRow(
                              'Balance:',
                              _balance,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Customer and Measurement Section
                      if (isDesktop)
                        Row(
                          children: [
                            Expanded(child: _buildCustomerSection()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildMeasurementSection()),
                          ],
                        )
                      else ...[
                        _buildCustomerSection(),
                        const SizedBox(height: 24),
                        _buildMeasurementSection(),
                      ],

                      const SizedBox(height: 24),

                      // Product Section
                      _buildProductsSection(theme),

                      const SizedBox(height: 24),

                      // Details Section
                      SizeTransition(
                        sizeFactor: _animation,
                        axisAlignment: -1.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: TextFormField(
                            controller: _detailsController,
                            decoration: InputDecoration(
                              labelText: 'Details',
                              labelStyle: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              prefixIcon: Icon(
                                Icons.description_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              filled: true,
                              fillColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            maxLines: 3,
                            style: TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ),

                      // ...existing submit button...
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom, // Add safe area padding
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: isDesktop 
              ? const BorderRadius.vertical(bottom: Radius.circular(28))
              : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: FilledButton.icon(
              onPressed: _saveInvoice,
              icon: const Icon(Icons.receipt_long),
              label: Text(isDesktop ? 'Generate Invoice' : 'Save'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _selectCustomer,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Customer',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedCustomer == null)
                    Icon(
                      Icons.add_circle_outline,
                      color: theme.colorScheme.primary,
                    )
                  else
                    Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                ],
              ),
              if (_selectedCustomer != null) ...[
                const SizedBox(height: 16),
                Text(
                  _selectedCustomer!.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bill #${_selectedCustomer!.billNumber} • ${_selectedCustomer!.phone}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  'Select a customer',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementSection() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _selectMeasurement,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.straighten,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Measurement',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedMeasurement == null)
                    Icon(
                      Icons.add_circle_outline,
                      color: theme.colorScheme.secondary,
                    )
                  else
                    Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.secondary,
                    ),
                ],
              ),
              if (_selectedMeasurement != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.secondary.withOpacity(
                        0.2,
                      ),
                      child: Text(
                        _selectedMeasurement!.style[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _measurementName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _measurementSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  _selectedCustomer == null
                      ? 'Select a customer first'
                      : 'Select measurement',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer.withOpacity(
                      0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Products',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                'Total: ${NumberFormat.currency(symbol: 'AED ').format(_products.fold(0.0, (sum, p) => sum + p.price))}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_products.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No products added yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ..._products.map((product) => _buildProductRow(theme, product)),
          const SizedBox(height: 8),
          Center(
            child: FilledButton.tonalIcon(
              onPressed: () {
                setState(() {
                  _products.add(Product(name: '', price: 0));
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(ThemeData theme, Product product) {
    final index = _products.indexOf(product);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: product.name,
              decoration: InputDecoration(
                hintText: 'Product Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _products[index] = _products[index].copyWith(name: value);
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              initialValue: product.price > 0 ? product.price.toString() : '',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Price',
                prefixText: 'AED ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _products[index] = _products[index].copyWith(
                    price: double.tryParse(value) ?? 0
                  );
                  _updateCalculations();
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _products.removeAt(index);
                _updateCalculations();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    double amount, {
    bool isBold = false,
  }) {
    final style =
        isBold
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(NumberFormat.currency(symbol: '').format(amount), style: style),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixIcon: const Icon(Icons.attach_money),
              enabled: _products.isEmpty,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (value) {
              setState(() {
                _amount = double.tryParse(value) ?? 0;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _NumberField(
            controller: _advanceController,
            label: 'Advance',
            onChanged: (value) {
              setState(() {
                _advance = double.tryParse(value) ?? 0;
              });
            },
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerField({
    required this.controller,
    required this.label,
    required this.initialDate,
    required this.onDateSelected,
  });

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 340,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Select Date',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _QuickDateButton(
                          label: 'Today',
                          onTap: () => Navigator.pop(context, DateTime.now()),
                        ),
                        _QuickDateButton(
                          label: 'Tomorrow',
                          onTap:
                              () => Navigator.pop(
                                context,
                                DateTime.now().add(const Duration(days: 1)),
                              ),
                        ),
                        _QuickDateButton(
                          label: 'Next Week',
                          onTap:
                              () => Navigator.pop(
                                context,
                                DateTime.now().add(const Duration(days: 7)),
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Calendar
                  SizedBox(
                    height: 360,
                    child: CalendarDatePicker(
                      initialDate: initialDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      onDateChanged: (date) => Navigator.pop(context, date),
                    ),
                  ),
                  // Bottom Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed:
                              () => Navigator.pop(context, DateTime.now()),
                          child: const Text('TODAY'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      readOnly: true,
      onTap: () => _selectDate(context),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a date';
        }
        return null;
      },
    );
  }
}

class _QuickDateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.attach_money),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }
}
