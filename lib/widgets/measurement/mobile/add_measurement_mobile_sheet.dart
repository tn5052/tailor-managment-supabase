import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../models/measurement.dart';
import '../../../models/customer.dart';
import '../../../services/measurement_service.dart';
import '../../../services/customer_service.dart';
import '../../../theme/inventory_design_config.dart';
import '../../customer/desktop/customer_selector_dialog.dart'; // Using desktop for now

class AddMeasurementMobileSheet extends StatefulWidget {
  final Measurement? measurement;
  final bool isEditing;
  final Customer? customer;
  final VoidCallback? onMeasurementAdded;

  const AddMeasurementMobileSheet({
    super.key,
    this.measurement,
    this.isEditing = false,
    this.customer,
    this.onMeasurementAdded,
  });

  static Future<void> show(
    BuildContext context, {
    Measurement? measurement,
    bool isEditing = false,
    Customer? customer,
    VoidCallback? onMeasurementAdded,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AddMeasurementMobileSheet(
              measurement: measurement,
              isEditing: isEditing,
              customer: customer,
              onMeasurementAdded: onMeasurementAdded,
            ),
          ),
    );
  }

  @override
  State<AddMeasurementMobileSheet> createState() =>
      _AddMeasurementMobileSheetState();
}

class _AddMeasurementMobileSheetState extends State<AddMeasurementMobileSheet> {
  final MeasurementService _measurementService = MeasurementService();
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Customer? _selectedCustomer;

  // Controllers
  late final TextEditingController _lengthArabiController;
  late final TextEditingController _lengthKuwaitiController;
  late final TextEditingController _chestController;
  late final TextEditingController _widthController;
  late final TextEditingController _sleeveController;
  late final TextEditingController _collarStartController;
  late final TextEditingController _collarCenterController;
  late final TextEditingController _collarEndController;
  late final TextEditingController _underController;
  late final TextEditingController _backLengthController;
  late final TextEditingController _neckController;
  late final TextEditingController _shoulderController;
  late final TextEditingController _seamController;
  late final TextEditingController _adhesiveController;
  late final TextEditingController _underKanduraController;
  late final TextEditingController _openSleeveController;
  late final TextEditingController _stitchingController;
  late final TextEditingController _pleatController;
  late final TextEditingController _buttonController;
  late final TextEditingController _cuffController;
  late final TextEditingController _embroideryController;
  late final TextEditingController _neckStyleController;
  late final TextEditingController _notesController;

  String? _selectedStyle;
  String _selectedDesignType = 'Aadi';
  String _selectedTarbooshType = 'Fixed';

  final List<String> _styleOptions = [
    'Emirati',
    'Kuwaiti',
    'Saudi',
    'Omani',
    'Qatari',
  ];
  final List<String> _designOptions = ['Aadi', 'Baat'];
  final List<String> _tarbooshOptions = ['Fixed', 'Separate'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
  }

  void _initializeControllers() {
    _lengthArabiController = TextEditingController();
    _lengthKuwaitiController = TextEditingController();
    _chestController = TextEditingController();
    _widthController = TextEditingController();
    _sleeveController = TextEditingController();
    _collarStartController = TextEditingController();
    _collarCenterController = TextEditingController();
    _collarEndController = TextEditingController();
    _underController = TextEditingController();
    _backLengthController = TextEditingController();
    _neckController = TextEditingController();
    _shoulderController = TextEditingController();
    _seamController = TextEditingController();
    _adhesiveController = TextEditingController();
    _underKanduraController = TextEditingController();
    _openSleeveController = TextEditingController();
    _stitchingController = TextEditingController();
    _pleatController = TextEditingController();
    _buttonController = TextEditingController();
    _cuffController = TextEditingController();
    _embroideryController = TextEditingController();
    _neckStyleController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _initializeData() {
    if (widget.customer != null) {
      _selectedCustomer = widget.customer;
    }

    if (widget.isEditing && widget.measurement != null) {
      final measurement = widget.measurement!;
      _supabaseService.getCustomerById(measurement.customerId).then((customer) {
        if (customer != null) {
          setState(() {
            _selectedCustomer = customer;
          });
        }
      });

      _selectedStyle = measurement.style;
      _lengthArabiController.text = measurement.lengthArabi;
      _lengthKuwaitiController.text = measurement.lengthKuwaiti;
      _chestController.text = measurement.chest;
      _widthController.text = measurement.width;
      _sleeveController.text = measurement.sleeve;
      _collarStartController.text = measurement.collar['start'] ?? '';
      _collarCenterController.text = measurement.collar['center'] ?? '';
      _collarEndController.text = measurement.collar['end'] ?? '';
      _underController.text = measurement.under;
      _backLengthController.text = measurement.backLength;
      _neckController.text = measurement.neck;
      _shoulderController.text = measurement.shoulder;
      _seamController.text = measurement.seam;
      _adhesiveController.text = measurement.adhesive;
      _underKanduraController.text = measurement.underKandura;
      _openSleeveController.text = measurement.openSleeve;
      _stitchingController.text = measurement.stitching;
      _pleatController.text = measurement.pleat;
      _buttonController.text = measurement.button;
      _cuffController.text = measurement.cuff;
      _embroideryController.text = measurement.embroidery;
      _neckStyleController.text = measurement.neckStyle;
      _notesController.text = measurement.notes;
      _selectedDesignType = measurement.designType;
      _selectedTarbooshType = measurement.tarbooshType;
    } else {
      _selectedStyle = _styleOptions[0];
    }
  }

  @override
  void dispose() {
    _lengthArabiController.dispose();
    _lengthKuwaitiController.dispose();
    _chestController.dispose();
    _widthController.dispose();
    _sleeveController.dispose();
    _collarStartController.dispose();
    _collarCenterController.dispose();
    _collarEndController.dispose();
    _underController.dispose();
    _backLengthController.dispose();
    _neckController.dispose();
    _shoulderController.dispose();
    _seamController.dispose();
    _adhesiveController.dispose();
    _underKanduraController.dispose();
    _openSleeveController.dispose();
    _stitchingController.dispose();
    _pleatController.dispose();
    _buttonController.dispose();
    _cuffController.dispose();
    _embroideryController.dispose();
    _neckStyleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showError(String message) {
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

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      _showError('Please select a customer');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final measurement = Measurement(
        id: widget.isEditing ? widget.measurement!.id : const Uuid().v4(),
        customerId: _selectedCustomer!.id,
        billNumber: _selectedCustomer!.billNumber,
        style: _selectedStyle!,
        lengthArabi: _lengthArabiController.text,
        lengthKuwaiti: _lengthKuwaitiController.text,
        chest: _chestController.text,
        width: _widthController.text,
        sleeve: _sleeveController.text,
        collar: {
          'start': _collarStartController.text,
          'center': _collarCenterController.text,
          'end': _collarEndController.text,
        },
        under: _underController.text,
        backLength: _backLengthController.text,
        neck: _neckController.text,
        shoulder: _shoulderController.text,
        seam: _seamController.text,
        adhesive: _adhesiveController.text,
        underKandura: _underKanduraController.text,
        tarboosh: _selectedTarbooshType,
        openSleeve: _openSleeveController.text,
        stitching: _stitchingController.text,
        pleat: _pleatController.text,
        button: _buttonController.text,
        cuff: _cuffController.text,
        embroidery: _embroideryController.text,
        neckStyle: _neckStyleController.text,
        notes: _notesController.text,
        fabricName: '',
        designType: _selectedDesignType,
        tarbooshType: _selectedTarbooshType,
        date: widget.isEditing ? widget.measurement!.date : DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      if (widget.isEditing) {
        await _measurementService.updateMeasurement(measurement);
      } else {
        await _measurementService.addMeasurement(measurement);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onMeasurementAdded?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Measurement updated successfully'
                  : 'Measurement added successfully',
            ),
            backgroundColor: InventoryDesignConfig.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  Future<void> _openCustomerSelector() async {
    final customers = await _supabaseService.getCustomersStream().first;
    final customer = await CustomerSelectorDialog.show(context, customers);
    if (customer != null) {
      setState(() {
        _selectedCustomer = customer;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          topRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
                child: Column(
                  children: [
                    _buildCustomerSelector(),
                    const SizedBox(height: InventoryDesignConfig.spacingL),
                    _buildStyleAndDesignSection(),
                    const SizedBox(height: InventoryDesignConfig.spacingL),
                    _buildMainMeasurementsSection(),
                    const SizedBox(height: InventoryDesignConfig.spacingL),
                    _buildStyleDetailsSection(),
                    const SizedBox(height: InventoryDesignConfig.spacingL),
                    _buildNotesSection(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Row(
        children: [
          Icon(
            widget.isEditing
                ? PhosphorIcons.pencilSimple()
                : PhosphorIcons.ruler(),
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Text(
            widget.isEditing ? 'Edit Measurement' : 'Add Measurement',
            style: InventoryDesignConfig.headlineMedium,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(PhosphorIcons.x()),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveMeasurement,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(),
                )
                : Icon(widget.isEditing ? Icons.save : Icons.add),
        label: Text(
          _isLoading ? 'Saving...' : (widget.isEditing ? 'Update' : 'Save'),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return ListTile(
      leading: Icon(PhosphorIcons.user()),
      title: Text(_selectedCustomer?.name ?? 'Select Customer'),
      subtitle: Text(_selectedCustomer?.billNumber ?? ''),
      trailing: Icon(PhosphorIcons.caretDown()),
      onTap: _openCustomerSelector,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        side: BorderSide(color: InventoryDesignConfig.borderPrimary),
      ),
    );
  }

  Widget _buildStyleAndDesignSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Style & Design', style: InventoryDesignConfig.titleMedium),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        DropdownButtonFormField<String>(
          value: _selectedStyle,
          items:
              _styleOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
          onChanged: (value) => setState(() => _selectedStyle = value),
          decoration: const InputDecoration(labelText: 'Style'),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        DropdownButtonFormField<String>(
          value: _selectedDesignType,
          items:
              _designOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
          onChanged: (value) => setState(() => _selectedDesignType = value!),
          decoration: const InputDecoration(labelText: 'Design'),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        DropdownButtonFormField<String>(
          value: _selectedTarbooshType,
          items:
              _tarbooshOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
          onChanged: (value) => setState(() => _selectedTarbooshType = value!),
          decoration: const InputDecoration(labelText: 'Tarboosh Type'),
        ),
      ],
    );
  }

  Widget _buildMainMeasurementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Main Measurements', style: InventoryDesignConfig.titleMedium),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildTextField(
          _selectedStyle == 'Emirati'
              ? _lengthArabiController
              : _lengthKuwaitiController,
          _selectedStyle == 'Emirati' ? 'Length (Arabic)' : 'Length (Kuwaiti)',
          required: true,
        ),
        _buildTextField(_chestController, 'Chest'),
        _buildTextField(_widthController, 'Width'),
        _buildTextField(_backLengthController, 'Back Length'),
        _buildTextField(_neckController, 'Neck Size'),
        _buildTextField(_shoulderController, 'Shoulder'),
        _buildTextField(_sleeveController, 'Sleeve Length'),
        Text('Sleeve Fitting', style: InventoryDesignConfig.bodyMedium),
        Row(
          children: [
            Expanded(child: _buildTextField(_collarStartController, 'Start')),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField(_collarCenterController, 'Center')),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField(_collarEndController, 'End')),
          ],
        ),
        _buildTextField(_underController, 'Under Shoulder'),
        _buildTextField(_seamController, 'Shoulder Shaib'),
        _buildTextField(_adhesiveController, 'Bottom'),
        _buildTextField(_underKanduraController, 'Bottom Kandura'),
      ],
    );
  }

  Widget _buildStyleDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Style Details', style: InventoryDesignConfig.titleMedium),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildTextField(_openSleeveController, 'Sleeve Stich'),
        _buildTextField(_stitchingController, 'Stitching Style'),
        _buildTextField(_pleatController, 'Pleat Style'),
        _buildTextField(_buttonController, 'front Plate'),
        _buildTextField(_cuffController, 'Cuff Style'),
        _buildTextField(_embroideryController, 'Embroidery'),
        _buildTextField(_neckStyleController, 'Neck Style'),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _buildTextField(_notesController, 'Notes', maxLines: 3);
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }
}
