import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/new_complaint_model.dart';
import '../../services/new_complaint_service.dart';
import '../../theme/inventory_design_config.dart';

class NewComplaintDialog extends StatefulWidget {
  final String customerId;
  final String customerName;
  final NewComplaint? complaint; // if not null, we are in edit mode
  final VoidCallback? onComplaintUpdated;

  const NewComplaintDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    this.complaint,
    this.onComplaintUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required String customerId,
    required String customerName,
    NewComplaint? complaint,
    VoidCallback? onComplaintUpdated,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NewComplaintDialog(
        customerId: customerId,
        customerName: customerName,
        complaint: complaint,
        onComplaintUpdated: onComplaintUpdated,
      ),
    );
  }

  @override
  State<NewComplaintDialog> createState() => _NewComplaintDialogState();
}

class _NewComplaintDialogState extends State<NewComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  late final NewComplaintService _complaintService;
  bool _isLoading = false;

  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _assignedToController;
  late final TextEditingController _resolutionController;

  // State variables
  ComplaintStatus _selectedStatus = ComplaintStatus.pending;
  ComplaintPriority _selectedPriority = ComplaintPriority.medium;
  String? _selectedInvoiceId;
  List<Map<String, dynamic>> _customerInvoices = [];

  bool get _isEditing => widget.complaint != null;

  @override
  void initState() {
    super.initState();
    _complaintService = NewComplaintService(_supabase);
    _initializeFields();
    _loadInvoices();
  }

  void _initializeFields() {
    if (_isEditing) {
      final complaint = widget.complaint!;
      _titleController = TextEditingController(text: complaint.title);
      _descriptionController = TextEditingController(text: complaint.description);
      _assignedToController = TextEditingController(text: complaint.assignedTo);
      _resolutionController = TextEditingController(text: complaint.resolutionDetails);
      _selectedStatus = complaint.status;
      _selectedPriority = complaint.priority;
      _selectedInvoiceId = complaint.invoiceId;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _assignedToController = TextEditingController();
      _resolutionController = TextEditingController();
    }
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      _customerInvoices = await _complaintService.getInvoicesForCustomer(widget.customerId);
      
      // Remove duplicates by ID
      final seenIds = <String>{};
      _customerInvoices = _customerInvoices.where((invoice) {
        final id = invoice['id']?.toString();
        if (id == null || seenIds.contains(id)) {
          return false;
        }
        seenIds.add(id);
        return true;
      }).toList();
      
      // Ensure the selected invoice ID is valid if in edit mode
      if (_isEditing && _selectedInvoiceId != null) {
        if (!_customerInvoices.any((inv) => inv['id']?.toString() == _selectedInvoiceId)) {
          _selectedInvoiceId = null;
        }
      }
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      _customerInvoices = [];
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  Future<void> _saveComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final updatedComplaint = widget.complaint!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _selectedStatus,
          priority: _selectedPriority,
          invoiceId: _selectedInvoiceId,
          assignedTo: _assignedToController.text.trim(),
          resolutionDetails: _resolutionController.text.trim(),
          resolvedAt: _selectedStatus == ComplaintStatus.resolved || _selectedStatus == ComplaintStatus.closed
              ? DateTime.now()
              : null,
        );
        await _complaintService.updateComplaint(updatedComplaint);
      } else {
        final newComplaint = NewComplaint(
          id: '', // Will be generated by DB
          customerId: widget.customerId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _selectedStatus,
          priority: _selectedPriority,
          invoiceId: (_selectedInvoiceId == null || _selectedInvoiceId!.isEmpty) ? null : _selectedInvoiceId,
          assignedTo: _assignedToController.text.trim(),
          resolutionDetails: _resolutionController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tenantId: _supabase.auth.currentUser!.id,
        );
        await _complaintService.addComplaint(newComplaint);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplaintUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complaint ${_isEditing ? 'updated' : 'added'} successfully'),
            backgroundColor: InventoryDesignConfig.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving complaint: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      padding: const EdgeInsets.symmetric(horizontal: InventoryDesignConfig.spacingXXL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          topRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(bottom: BorderSide(color: InventoryDesignConfig.borderSecondary)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            ),
            child: Icon(
              _isEditing ? PhosphorIcons.pencilSimple() : PhosphorIcons.plus(),
              size: 18,
              color: InventoryDesignConfig.warningColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Complaint' : 'New Complaint',
                  style: InventoryDesignConfig.headlineMedium,
                ),
                Text(
                  'For customer: ${widget.customerName}',
                  style: InventoryDesignConfig.bodyMedium.copyWith(color: InventoryDesignConfig.textSecondary),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              child: Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                child: Icon(PhosphorIcons.x(), size: 18, color: InventoryDesignConfig.textSecondary),
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
            _buildSection('Complaint Details', PhosphorIcons.info(), [
              _buildTextField(
                controller: _titleController,
                label: 'Complaint Title',
                hint: 'e.g., Stitching issue on left sleeve',
                icon: PhosphorIcons.textT(),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: InventoryDesignConfig.spacingL),
              _buildTextField(
                controller: _descriptionController,
                label: 'Full Description (Optional)',
                hint: 'Provide more details about the issue...',
                icon: PhosphorIcons.notePencil(),
                maxLines: 4,
              ),
            ]),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
            _buildSection('Status & Assignment', PhosphorIcons.chartLineUp(), [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDropdown<ComplaintStatus>(
                      value: _selectedStatus,
                      label: 'Status',
                      icon: PhosphorIcons.trafficSignal(),
                      items: ComplaintStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedStatus = value!),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingL),
                  Expanded(
                    child: _buildDropdown<ComplaintPriority>(
                      value: _selectedPriority,
                      label: 'Priority',
                      icon: PhosphorIcons.warning(),
                      items: ComplaintPriority.values.map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority.displayName),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedPriority = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: InventoryDesignConfig.spacingL),
              _buildTextField(
                controller: _assignedToController,
                label: 'Assigned To (Optional)',
                hint: 'e.g., Master Cutter Ahmed',
                icon: PhosphorIcons.user(),
              ),
            ]),
            const SizedBox(height: InventoryDesignConfig.spacingXXL),
            _buildSection('Related Invoice', PhosphorIcons.receipt(), [
              _buildDropdown<String?>(
                value: _selectedInvoiceId,
                label: 'Link to Invoice (Optional)',
                hint: 'Select an invoice',
                icon: PhosphorIcons.link(),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._customerInvoices
                      .where((invoice) => invoice['id'] != null)
                      .toSet() // Remove duplicates
                      .map((invoice) => DropdownMenuItem<String?>(
                        value: invoice['id'].toString(),
                        child: Text(
                          '#${invoice['invoice_number']} - ${DateFormat.yMMMd().format(DateTime.parse(invoice['date']))}',
                        ),
                      )),
                ],
                onChanged: (value) => setState(() => _selectedInvoiceId = value),
              ),
            ]),
            if (_selectedStatus == ComplaintStatus.resolved || _selectedStatus == ComplaintStatus.closed) ...[
              const SizedBox(height: InventoryDesignConfig.spacingXXL),
              _buildSection('Resolution', PhosphorIcons.checkCircle(), [
                _buildTextField(
                  controller: _resolutionController,
                  label: 'Resolution Details',
                  hint: 'Describe how the complaint was resolved...',
                  icon: PhosphorIcons.textAa(),
                  maxLines: 4,
                  validator: (value) {
                    if (_selectedStatus == ComplaintStatus.resolved && (value == null || value.trim().isEmpty)) {
                      return 'Please provide resolution details';
                    }
                    return null;
                  },
                ),
              ]),
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
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _isLoading ? null : _saveComplaint,
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
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(PhosphorIcons.floppyDisk(), size: 16, color: Colors.white),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      _isLoading ? 'Saving...' : 'Save Complaint',
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

  // Common Widgets (re-styled for consistency)

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
              border: Border(bottom: BorderSide(color: InventoryDesignConfig.borderSecondary)),
            ),
            child: Row(
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: InventoryDesignConfig.labelLarge),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: InventoryDesignConfig.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(color: InventoryDesignConfig.textTertiary),
            prefixIcon: Icon(icon, size: 18, color: InventoryDesignConfig.textSecondary),
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
              borderSide: BorderSide(color: InventoryDesignConfig.primaryColor, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              borderSide: BorderSide(color: InventoryDesignConfig.errorColor, width: 2.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              borderSide: BorderSide(color: InventoryDesignConfig.errorColor, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String label,
    String? hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    // Find the item that matches the current value
    final selectedItem = items.where((item) => item.value == value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: InventoryDesignConfig.labelLarge),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        DropdownButtonFormField<T>(
          value: selectedItem.length == 1 ? value : null,
          style: InventoryDesignConfig.bodyLarge,
          dropdownColor: InventoryDesignConfig.surfaceColor,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(color: InventoryDesignConfig.textTertiary),
            prefixIcon: Icon(icon, size: 18, color: InventoryDesignConfig.textSecondary),
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
              borderSide: BorderSide(color: InventoryDesignConfig.primaryColor, width: 2.0),
            ),
          ),
          items: items,
          onChanged: onChanged,
          icon: Icon(PhosphorIcons.caretDown(), size: 16, color: InventoryDesignConfig.textSecondary),
        ),
      ],
    );
  }
}
