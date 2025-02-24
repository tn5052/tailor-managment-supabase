import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/complaint.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../services/complaint_service.dart';
import '../../services/customer_service.dart';
import '../../services/invoice_service.dart';
import '../customer/customer_selector_dialog.dart';
import '../invoice/invoice_selector_dialog.dart';

class ComplaintDialog extends StatefulWidget {
  final Complaint? complaint;
  final String? customerId;  // Optional: Pre-select customer

  const ComplaintDialog({
    super.key, 
    this.complaint,
    this.customerId,
  });

  // Added static show method
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ComplaintDialog(),
    );
  }

  @override
  State<ComplaintDialog> createState() => _ComplaintDialogState();
}

class _ComplaintDialogState extends State<ComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final InputDecoration inputDecoration = InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
  );
  ComplaintPriority _priority = ComplaintPriority.medium;
  Customer? _selectedCustomer;
  Invoice? _selectedInvoice;
  List<Invoice>? _customerInvoices;
  bool _isLoading = false;
  String? _errorMessage;

  final _complaintService = ComplaintService(Supabase.instance.client);
  final _customerService = CustomerService(Supabase.instance.client);
  final _invoiceService = InvoiceService();

  @override
  void initState() {
    super.initState();
    if (widget.complaint != null) {
      _titleController.text = widget.complaint!.title;
      _descriptionController.text = widget.complaint!.description;
      _priority = widget.complaint!.priority;
    }
    if (widget.customerId != null) {
      _loadCustomer(widget.customerId!);
    }
  }

  Future<void> _loadCustomer(String customerId) async {
    try {
      final customer = await _customerService.getCustomerById(customerId);
      setState(() => _selectedCustomer = customer);
      _loadCustomerInvoices(customerId);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadCustomerInvoices(String customerId) async {
    try {
      final invoices = await _invoiceService.getCustomerInvoices(customerId);
      setState(() => _customerInvoices = invoices);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _selectCustomer() async {
    final customers = await _customerService.getAllCustomers();
    if (!mounted) return;

    final selected = await CustomerSelectorDialog.show(context, customers);
    if (selected != null) {
      setState(() {
        _selectedCustomer = selected;
        _selectedInvoice = null;
        _customerInvoices = null;
      });
      _loadCustomerInvoices(selected.id);
    }
  }

  Future<void> _selectInvoice() async {
    if (_selectedCustomer == null || _customerInvoices == null) return;

    final selected = await InvoiceSelectorDialog.show(
      context,
      _customerInvoices!,
      selectedInvoice: _selectedInvoice,
    );

    if (selected != null) {
      setState(() => _selectedInvoice = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isDark = theme.brightness == Brightness.dark;

    if (isDesktop) {
      // Return existing desktop dialog
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surface,
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.complaint == null ? 'New Complaint' : 'Edit Complaint',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Customer Selection
                if (_selectedCustomer == null)
                  OutlinedButton.icon(
                    onPressed: _selectCustomer,
                    icon: PhosphorIcon(PhosphorIcons.userPlus()),
                    label: const Text('Select Customer'),
                  )
                else
                  Card(
                    child: ListTile(
                      title: Text(_selectedCustomer!.name),
                      subtitle: Text(_selectedCustomer!.billNumber),
                      leading: CircleAvatar(
                        child: Text(_selectedCustomer!.name[0]),
                      ),
                      trailing: IconButton(
                        icon: PhosphorIcon(PhosphorIcons.x()),
                        onPressed: () => setState(() {
                          _selectedCustomer = null;
                          _selectedInvoice = null;
                          _customerInvoices = null;
                        }),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Invoice Selection
                if (_selectedCustomer != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Related Invoice (Optional)',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (_customerInvoices == null)
                        const Center(child: CircularProgressIndicator())
                      else if (_customerInvoices!.isEmpty)
                        Text(
                          'No invoices found for this customer',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        )
                      else
                        Card(
                          child: InkWell(
                            onTap: _selectInvoice,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  if (_selectedInvoice != null) ...[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Invoice #${_selectedInvoice!.invoiceNumber}',
                                            style: theme.textTheme.titleMedium,
                                          ),
                                          Text(
                                            DateFormat('MMM dd, yyyy')
                                                .format(_selectedInvoice!.date),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: PhosphorIcon(PhosphorIcons.x()),
                                      onPressed: () => setState(
                                        () => _selectedInvoice = null,
                                      ),
                                    ),
                                  ] else ...[
                                    PhosphorIcon(PhosphorIcons.receipt()),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Select Invoice',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    const Spacer(),
                                    PhosphorIcon(
                                      PhosphorIcons.caretRight(),
                                      color: theme.colorScheme.outline,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Title',
                    hintText: 'Enter complaint title',
                    prefixIcon: PhosphorIcon(
                      PhosphorIcons.textT(),
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Description',
                    hintText: 'Enter complaint description',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 64),
                      child: PhosphorIcon(
                        PhosphorIcons.textAlignLeft(),
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ComplaintPriority>(
                  value: _priority,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Priority',
                    prefixIcon: PhosphorIcon(
                      PhosphorIcons.flag(),
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  dropdownColor: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.surfaceContainerHighest,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                  items: ComplaintPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(
                        priority.toString().split('.').last,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.complaint == null ? 'Create' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile full-screen version
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.complaint == null ? 'New Complaint' : 'Edit Complaint',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            TextButton(
              onPressed: _submitForm,
              child: const Text('SAVE'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileCustomerSection(theme),
                  const SizedBox(height: 24),
                  _buildMobileInvoiceSection(theme),
                  const SizedBox(height: 24),
                  _buildMobileComplaintFields(theme),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Card(
                        color: theme.colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCustomerSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedCustomer == null)
          Card(
            child: InkWell(
              onTap: _selectCustomer,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Select Customer',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          _selectedCustomer!.name[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCustomer!.name,
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              'Bill #${_selectedCustomer!.billNumber}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _selectCustomer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileInvoiceSection(ThemeData theme) {
    if (_selectedCustomer == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Invoice',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_customerInvoices == null)
          const Center(child: CircularProgressIndicator())
        else if (_customerInvoices!.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No invoices found',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          )
        else
          Card(
            child: ListTile(
              onTap: _selectInvoice,
              leading: Icon(
                Icons.receipt_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                _selectedInvoice != null
                    ? 'Invoice #${_selectedInvoice!.invoiceNumber}'
                    : 'Select Invoice',
              ),
              subtitle: _selectedInvoice != null
                  ? Text(
                      DateFormat('MMM dd, yyyy').format(_selectedInvoice!.date))
                  : null,
              trailing: _selectedInvoice != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => _selectedInvoice = null),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
      ],
    );
  }

  Color _getPriorityColor(ComplaintPriority priority) {
    switch (priority) {
      case ComplaintPriority.low:
        return Colors.green;
      case ComplaintPriority.medium:
        return Colors.orange;
      case ComplaintPriority.high:
        return Colors.red;
      case ComplaintPriority.urgent:
        return Colors.deepPurple;
    }
  }

  Widget _buildMobileComplaintFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complaint Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Title',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Title is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Description is required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ComplaintPriority>(
          value: _priority,
          decoration: InputDecoration(
            labelText: 'Priority',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: ComplaintPriority.values.map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(priority.toString().split('.').last),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _priority = value);
          },
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      setState(() => _errorMessage = 'Please select a customer');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final assignedTo = currentUser?.id ?? 'default_admin';

      final complaint = Complaint.create(
        customerId: _selectedCustomer!.id,
        invoiceId: _selectedInvoice?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _priority,
        assignedTo: assignedTo,
      );

      await _complaintService.createComplaint(complaint);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create complaint: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
