// Update imports at the top
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/measurement.dart';
import '../../models/customer.dart';
import '../../services/measurement_service.dart';
import '../../services/customer_service.dart';
import '../../utils/fraction_helper.dart';
import '../customer/desktop/customer_selector_dialog.dart';  // Make sure this path is correct
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddMeasurementDialog extends StatefulWidget {
  final Measurement? measurement;
  final int? index;
  final bool isEditing;
  final Customer? customer; // Add this field

  const AddMeasurementDialog({
    super.key,
    this.measurement,
    this.index,
    this.isEditing = false,
    this.customer, // Add this parameter
  });

  // Update the show method to include customer parameter
  static Future<void> show(
    BuildContext context, {
    Measurement? measurement,
    int? index,
    bool isEditing = false,
    Customer? customer, // Add this parameter
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: false, // Prevent closing on outside tap
        builder:
            (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 800,
                constraints: BoxConstraints(
                  maxWidth: 800,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: AddMeasurementDialog(
                  measurement: measurement,
                  index: index,
                  isEditing: isEditing,
                  customer: customer, // Pass the customer parameter
                ),
              ),
            ),
      );
    }

    // Full screen for mobile
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (context) => AddMeasurementDialog(
              measurement: measurement,
              index: index,
              isEditing: isEditing,
              customer: customer, // Pass the customer parameter
            ),
      ),
    );
  }

  @override
  State<AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<AddMeasurementDialog> {
  final MeasurementService _measurementService = MeasurementService();
  final SupabaseService _supabaseService =
      SupabaseService(); // Add SupabaseService
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  String? _selectedCustomerId;
  String _billNumber = '';
  final _styleController = TextEditingController();
  final _lengthArabiController = TextEditingController();
  final _lengthKuwaitiController = TextEditingController();
  final _chestController = TextEditingController();
  final _widthController = TextEditingController();
  final _sleeveController = TextEditingController();
  final _collarController = TextEditingController();
  final _underController = TextEditingController();
  final _backLengthController = TextEditingController();
  final _neckController = TextEditingController();
  final _shoulderController = TextEditingController();
  final _seamController = TextEditingController();
  final _adhesiveController = TextEditingController();
  final _underKanduraController = TextEditingController();
  final _tarbooshController = TextEditingController();
  final _openSleeveController = TextEditingController();
  final _stitchingController = TextEditingController();
  final _pleatController = TextEditingController();
  final _buttonController = TextEditingController();
  final _cuffController = TextEditingController();
  final _embroideryController = TextEditingController();
  final _neckStyleController = TextEditingController();
  final _notesController = TextEditingController();
  final _fabricNameController = TextEditingController(); // Add this

  String _selectedDesignType = 'Aadi';
  String _selectedTarbooshType = 'Fixed';

  final _designOptions = ['Aadi', 'Baat'];
  final _tarbooshOptions = ['Fixed', 'Separate'];

  final _styleOptions = [
    'Emirati',
    'Kuwaiti',
    'Saudi',
    'Omani',
    'Qatari',
  ];
  String? _selectedStyle;

  final String _draftKey = "add_measurement_dialog_draft";

  // Add this helper to save draft state
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftData = {
      "billNumber": _billNumber,
      "style": _styleController.text,
      "lengthArabi": _lengthArabiController.text,
      "lengthKuwaiti": _lengthKuwaitiController.text,
      "chest": _chestController.text,
      "width": _widthController.text,
      "sleeve": _sleeveController.text,
      "collar": _collarController.text,
      "under": _underController.text,
      "backLength": _backLengthController.text,
      "neck": _neckController.text,
      "shoulder": _shoulderController.text,
      "seam": _seamController.text,
      "adhesive": _adhesiveController.text,
      "underKandura": _underKanduraController.text,
      "tarboosh": _tarbooshController.text,
      "openSleeve": _openSleeveController.text,
      "stitching": _stitchingController.text,
      "pleat": _pleatController.text,
      "button": _buttonController.text,
      "cuff": _cuffController.text,
      "embroidery": _embroideryController.text,
      "neckStyle": _neckStyleController.text,
      "notes": _notesController.text,
      "fabricName": _fabricNameController.text,
      "selectedDesignType": _selectedDesignType,
      "selectedTarbooshType": _selectedTarbooshType,
      "selectedStyle": _selectedStyle,
    };
    prefs.setString(_draftKey, jsonEncode(draftData));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_draftKey)) {
      final draftData = jsonDecode(prefs.getString(_draftKey)!);
      setState(() {
        _billNumber = draftData["billNumber"] ?? "";
        _styleController.text = draftData["style"] ?? "";
        _lengthArabiController.text = draftData["lengthArabi"] ?? "";
        _lengthKuwaitiController.text = draftData["lengthKuwaiti"] ?? "";
        _chestController.text = draftData["chest"] ?? "";
        _widthController.text = draftData["width"] ?? "";
        _sleeveController.text = draftData["sleeve"] ?? "";
        _collarController.text = draftData["collar"] ?? "";
        _underController.text = draftData["under"] ?? "";
        _backLengthController.text = draftData["backLength"] ?? "";
        _neckController.text = draftData["neck"] ?? "";
        _shoulderController.text = draftData["shoulder"] ?? "";
        _seamController.text = draftData["seam"] ?? "";
        _adhesiveController.text = draftData["adhesive"] ?? "";
        _underKanduraController.text = draftData["underKandura"] ?? "";
        _tarbooshController.text = draftData["tarboosh"] ?? "";
        _openSleeveController.text = draftData["openSleeve"] ?? "";
        _stitchingController.text = draftData["stitching"] ?? "";
        _pleatController.text = draftData["pleat"] ?? "";
        _buttonController.text = draftData["button"] ?? "";
        _cuffController.text = draftData["cuff"] ?? "";
        _embroideryController.text = draftData["embroidery"] ?? "";
        _neckStyleController.text = draftData["neckStyle"] ?? "";
        _notesController.text = draftData["notes"] ?? "";
        _fabricNameController.text = draftData["fabricName"] ?? "";
        _selectedDesignType = draftData["selectedDesignType"] ?? "Aadi";
        _selectedTarbooshType = draftData["selectedTarbooshType"] ?? "Fixed";
        _selectedStyle = draftData["selectedStyle"] ?? _styleOptions[0];
      });
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_draftKey);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _styleController.dispose();
    _lengthArabiController.dispose();
    _lengthKuwaitiController.dispose();
    _chestController.dispose();
    _widthController.dispose();
    _sleeveController.dispose();
    _collarController.dispose();
    _underController.dispose();
    _backLengthController.dispose();
    _neckController.dispose();
    _shoulderController.dispose();
    _seamController.dispose();
    _adhesiveController.dispose();
    _underKanduraController.dispose();
    _tarbooshController.dispose();
    _openSleeveController.dispose();
    _stitchingController.dispose();
    _pleatController.dispose();
    _buttonController.dispose();
    _cuffController.dispose();
    _embroideryController.dispose();
    _neckStyleController.dispose();
    _notesController.dispose();
    _fabricNameController.dispose(); // Add this
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize with provided customer if available
    if (widget.customer != null) {
      _selectedCustomerId = widget.customer!.id;
      _billNumber = widget.customer!.billNumber;
    }
    if (widget.isEditing && widget.measurement != null) {
      _selectedCustomerId = widget.measurement!.customerId;
      _billNumber = widget.measurement!.billNumber;
      _selectedStyle = widget.measurement!.style;
      _styleController.text = widget.measurement!.style;
      _lengthArabiController.text = widget.measurement!.lengthArabi.toString();
      _lengthKuwaitiController.text = widget.measurement!.lengthKuwaiti.toString();
      _chestController.text = widget.measurement!.chest.toString();
      _widthController.text = widget.measurement!.width.toString();
      _sleeveController.text = widget.measurement!.sleeve.toString();
      _collarController.text = widget.measurement!.collar.toString();
      _underController.text = widget.measurement!.under.toString();
      _backLengthController.text = widget.measurement!.backLength.toString();
      _neckController.text = widget.measurement!.neck.toString();
      _shoulderController.text = widget.measurement!.shoulder.toString();
      _seamController.text = widget.measurement!.seam;
      _adhesiveController.text = widget.measurement!.adhesive;
      _underKanduraController.text = widget.measurement!.underKandura;
      _tarbooshController.text = widget.measurement!.tarboosh;
      _openSleeveController.text = widget.measurement!.openSleeve;
      _stitchingController.text = widget.measurement!.stitching;
      _pleatController.text = widget.measurement!.pleat;
      _buttonController.text = widget.measurement!.button;
      _cuffController.text = widget.measurement!.cuff;
      _embroideryController.text = widget.measurement!.embroidery;
      _neckStyleController.text = widget.measurement!.neckStyle;
      _notesController.text = widget.measurement!.notes;
      _fabricNameController.text = widget.measurement!.fabricName; // Add this
      _selectedDesignType = widget.measurement!.designType;
      _selectedTarbooshType = widget.measurement!.tarbooshType;
      _tarbooshController.text = _selectedTarbooshType; // Ensure sync on init
    } else {
      // Set default values for new measurements
      _selectedStyle = _styleOptions[0]; // Select first style by default
      _styleController.text = _styleOptions[0]; // Set the controller text as well
    }
    _loadDraft();

    // Attach listeners to auto-save changes
    final controllers = [
      _styleController,
      _lengthArabiController,
      _lengthKuwaitiController,
      _chestController,
      _widthController,
      _sleeveController,
      _collarController,
      _underController,
      _backLengthController,
      _neckController,
      _shoulderController,
      _seamController,
      _adhesiveController,
      _underKanduraController,
      _tarbooshController,
      _openSleeveController,
      _stitchingController,
      _pleatController,
      _buttonController,
      _cuffController,
      _embroideryController,
      _neckStyleController,
      _notesController,
      _fabricNameController,
    ];
    for (var controller in controllers) {
      controller.addListener(_saveDraft);
    }
  }

  Future<void> _addMeasurement() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Ensure tarboosh field matches tarbooshType before saving
        _tarbooshController.text = _selectedTarbooshType;
        
        final measurement = Measurement(
          id: widget.isEditing ? widget.measurement!.id : const Uuid().v4(),
          customerId: _selectedCustomerId!,
          billNumber: _billNumber,
          style: _styleController.text,
          lengthArabi: FractionHelper.parseFraction(_lengthArabiController.text),
          lengthKuwaiti: FractionHelper.parseFraction(_lengthKuwaitiController.text),
          chest: FractionHelper.parseFraction(_chestController.text),
          width: FractionHelper.parseFraction(_widthController.text),
          sleeve: FractionHelper.parseFraction(_sleeveController.text),
          collar: FractionHelper.parseFraction(_collarController.text),
          under: FractionHelper.parseFraction(_underController.text),
          backLength: FractionHelper.parseFraction(_backLengthController.text),
          neck: FractionHelper.parseFraction(_neckController.text),
          shoulder: FractionHelper.parseFraction(_shoulderController.text),
          seam: _seamController.text,
          adhesive: _adhesiveController.text,
          underKandura: _underKanduraController.text,
          tarboosh: _selectedTarbooshType, // Use selectedTarbooshType directly
          openSleeve: _openSleeveController.text,
          stitching: _stitchingController.text,
          pleat: _pleatController.text,
          button: _buttonController.text,
          cuff: _cuffController.text,
          embroidery: _embroideryController.text,
          neckStyle: _neckStyleController.text,
          notes: _notesController.text,
          fabricName: _fabricNameController.text, // Add this
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

        await _clearDraft();

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Measurement updated successfully'
                  : 'Measurement added successfully',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: const Text('Are you sure you want to discard changes?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FilledButton(
              child: const Text('Discard'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _handleClose() async {
    if (_hasUnsavedChanges()) {
      final shouldClose = await _showConfirmationDialog();
      if (shouldClose && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  bool _hasUnsavedChanges() {
    return _selectedCustomerId != null ||
        _billNumber.isNotEmpty ||
        _styleController.text.isNotEmpty ||
        _lengthArabiController.text.isNotEmpty ||
        _lengthKuwaitiController.text.isNotEmpty ||
        _chestController.text.isNotEmpty ||
        _widthController.text.isNotEmpty ||
        _sleeveController.text.isNotEmpty ||
        _collarController.text.isNotEmpty ||
        _underController.text.isNotEmpty ||
        _backLengthController.text.isNotEmpty ||
        _neckController.text.isNotEmpty ||
        _shoulderController.text.isNotEmpty ||
        _seamController.text.isNotEmpty ||
        _adhesiveController.text.isNotEmpty ||
        _underKanduraController.text.isNotEmpty ||
        _tarbooshController.text.isNotEmpty ||
        _openSleeveController.text.isNotEmpty ||
        _stitchingController.text.isNotEmpty ||
        _pleatController.text.isNotEmpty ||
        _buttonController.text.isNotEmpty ||
        _cuffController.text.isNotEmpty ||
        _embroideryController.text.isNotEmpty ||
        _neckStyleController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _fabricNameController.text.isNotEmpty;
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges()) {
      return await _showConfirmationDialog();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final theme = Theme.of(context);

    Widget content = isDesktop
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: theme.colorScheme.surface,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Add header with actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.isEditing ? 'Edit Measurement' : 'New Measurement',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _addMeasurement,
                        icon: const Icon(Icons.save),
                        label: const Text('SAVE'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _handleClose, // Updated here
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _buildContent(theme, isDesktop),
                ),
              ],
            ),
          )
        : Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.colorScheme.primaryContainer,
            title: Text(
              widget.isEditing ? 'Edit Measurement' : 'New Measurement',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              FilledButton.icon(
                onPressed: _addMeasurement,
                icon: const Icon(Icons.save),
                label: const Text('SAVE'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 16), // Increased spacing
            ],
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _handleClose,
            ),
          ),
          body: _buildContent(theme, isDesktop),
        );

    // Wrap with WillPopScope to handle back button and keyboard escape
    return WillPopScope(
      onWillPop: _onWillPop,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            _handleClose();
          },
        },
        child: Focus(
          autofocus: true,
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDesktop) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24.0 : 16.0,
          vertical: 24.0,
        ),
        children: [
          _buildSectionCard(
            title: 'Customer Details',
            icon: Icons.person_outline,
            children: [
              _buildCustomerField(),
              if (_billNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoField('Bill Number', _billNumber),
              ],
            ],
          ),
          const SizedBox(height: 16),

          _buildStyleAndFabricSection(),
          const SizedBox(height: 16),

          _buildSectionCard(
            title: 'Measurements',
            icon: Icons.straighten,
            color: Theme.of(context).colorScheme.primary,
            children: [
              _buildMeasurementFields(
                isDesktop: isDesktop,
                fields: [
                  // Conditional length field based on style
                  if (_styleController.text == 'Emirati')
                    MeasurementField(
                      controller: _lengthArabiController,
                      label: 'Arabic Length',
                      required: true,
                    )
                  else
                    MeasurementField(
                      controller: _lengthKuwaitiController,
                      label: 'Kuwaiti Length',
                      required: true,
                    ),
                  // Common measurement fields
                  MeasurementField(controller: _chestController, label: 'Chest'),
                  MeasurementField(controller: _widthController, label: 'Width'),
                  MeasurementField(controller: _sleeveController, label: 'Sleeve'),
                  MeasurementField(controller: _collarController, label: 'Collar'),
                  MeasurementField(controller: _underController, label: 'Under'),
                  MeasurementField(controller: _backLengthController, label: 'Back Length'),
                  MeasurementField(controller: _neckController, label: 'Neck'),
                  MeasurementField(controller: _shoulderController, label: 'Shoulder'),
                  MeasurementField(controller: _seamController, label: 'Seam', isTextField: true),
                  MeasurementField(controller: _adhesiveController, label: 'Adhesive', isTextField: true),
                  MeasurementField(controller: _underKanduraController, label: 'Under Kandura', isTextField: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSectionCard(
            title: 'Style Details',
            icon: Icons.design_services_outlined,
            color: Theme.of(context).colorScheme.tertiary,
            children: [
              _buildStyleDetailsFields(
                isDesktop: isDesktop,
                fields: [
                  StyleDetailField(
                    controller: _tarbooshController,
                    label: 'Cap Style',
                  ),
                  StyleDetailField(
                    controller: _openSleeveController,
                    label: 'Sleeve Style',
                  ),
                  StyleDetailField(
                    controller: _stitchingController,
                    label: 'Stitching',
                  ),
                  StyleDetailField(
                    controller: _pleatController,
                    label: 'Pleats',
                  ),
                  StyleDetailField(
                    controller: _buttonController,
                    label: 'Side Pocket',
                  ),
                  StyleDetailField(
                    controller: _cuffController,
                    label: 'Cuff Style',
                  ),
                  StyleDetailField(
                    controller: _embroideryController,
                    label: 'Embroidery',
                  ),
                  StyleDetailField(
                    controller: _neckStyleController,
                    label: 'Neck Style',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSectionCard(
            title: 'Additional Notes',
            icon: Icons.notes_outlined,
            children: [
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: _inputDecoration(
                  'Enter any additional notes here...',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    return Card(
      elevation: 0,
      color: color?.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color?.withOpacity(0.15) ?? Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMeasurementFields({
    required bool isDesktop,
    required List<MeasurementField> fields,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 3 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: isDesktop ? 3 : 6,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children:
              fields.map((field) {
                return field.isTextField
                    ? _buildTextField(
                      field.controller,
                      field.label,
                      required: field.required,
                    )
                    : _buildNumberField(
                      field.controller,
                      field.label,
                      field.required,
                    );
              }).toList(),
        );
      },
    );
  }

  Widget _buildStyleDetailsFields({
    required bool isDesktop,
    required List<StyleDetailField> fields,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 3 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: isDesktop ? 3 : 6,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: fields.map((field) {
            // Special handling for Tarboosh/Cap Style
            if (field.controller == _tarbooshController) {
              return _buildTarbooshTypeField(readOnly: true);
            }
            return _buildTextField(field.controller, field.label);
          }).toList(),
        );
      },
    );
  }

  Widget _buildCustomerField() {
    return StreamBuilder<List<Customer>>(
      stream: _supabaseService.getCustomersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final customers = snapshot.data ?? [];
        final selectedCustomer = customers.firstWhere(
          (c) => c.id == _selectedCustomerId,
          orElse: () => Customer(
            id: '',
            billNumber: '',
            name: '',
            phone: '',
            address: '',
            gender: Gender.male,
          ),
        );

        return InkWell(
          onTap: () async {
            final customer = await CustomerSelectorDialog.show(context, customers);
            if (customer != null) {
              setState(() {
                _selectedCustomerId = customer.id;
                _billNumber = customer.billNumber;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: _selectedCustomerId == null || _selectedCustomerId!.isEmpty
                  ? Border.all(color: Colors.red)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectedCustomerId == null || _selectedCustomerId!.isEmpty
                      ? Text(
                          'Select Customer',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedCustomer.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedCustomer.phone,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyleField() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Style').copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      value: _selectedStyle,
      items: _styleOptions.map((String style) {
        return DropdownMenuItem<String>(
          value: style,
          child: Text(
            style,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width >= 1024 ? null : 14,
            ),
          ),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a style';
        }
        return null;
      },
      onChanged: (String? newValue) {
        setState(() {
          _selectedStyle = newValue;
          _styleController.text = newValue!;
        });
      },
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label,
    bool required,
  ) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, suffixText: '"'),
      keyboardType: TextInputType.text, // Changed to text to allow fractions
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Please enter a value';
        }
        if (value != null && value.isNotEmpty && !FractionHelper.isValidFraction(value)) {
          return 'Please enter a valid measurement (e.g., 32, 32 1/2)';
        }
        return null;
      },
      onChanged: (value) {
        // Remove any double quotes the user might type
        if (value.contains('"')) {
          controller.text = value.replaceAll('"', '');
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int? maxLines,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      maxLines: maxLines,
      validator:
          required
              ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
              : null,
    );
  }

  InputDecoration _inputDecoration(String label, {String? suffixText}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.grey.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  Widget _buildStyleAndFabricSection() {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    return _buildSectionCard(
      title: 'Style & Fabric',
      icon: Icons.style_outlined,
      color: Theme.of(context).colorScheme.primary,
      children: [
        if (isDesktop)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildStyleField(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDesignTypeField(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTarbooshTypeField(readOnly: false),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStyleField(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDesignTypeField(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTarbooshTypeField(readOnly: false),
                  ),
                ],
              ),
            ],
          ),
        const SizedBox(height: 16),
        // Fabric name field
        TextFormField(
          controller: _fabricNameController,
          decoration: _inputDecoration('Fabric Name').copyWith(
            prefixIcon: Icon(
              Icons.format_color_fill,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesignTypeField() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Design Type').copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      value: _selectedDesignType,
      items: _designOptions.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width >= 1024 ? null : 14,
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedDesignType = newValue!;
        });
      },
    );
  }

  Widget _buildTarbooshTypeField({bool readOnly = false}) {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Tarboosh Style').copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      value: _selectedTarbooshType,
      items: _tarbooshOptions.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width >= 1024 ? null : 14,
            ),
          ),
        );
      }).toList(),
      onChanged: readOnly ? null : (String? newValue) {
        setState(() {
          _selectedTarbooshType = newValue!;
          _tarbooshController.text = newValue;
        });
      },
    );
  }

}

class MeasurementField {
  final TextEditingController controller;
  final String label;
  final bool required;
  final bool isTextField;

  MeasurementField({
    required this.controller,
    required this.label,
    this.required = false,
    this.isTextField = false,
  });
}

class StyleDetailField {
  final TextEditingController controller;
  final String label;

  StyleDetailField({required this.controller, required this.label});
}
