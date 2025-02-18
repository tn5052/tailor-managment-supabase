// Update imports at the top
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/measurement.dart';
import '../../models/customer.dart';
import '../../services/measurement_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/fraction_helper.dart';
import '../customer/customer_selector_dialog.dart';  // Make sure this path is correct

class AddMeasurementDialog extends StatefulWidget {
  final Measurement? measurement;
  final int? index;
  final bool isEditing;

  const AddMeasurementDialog({
    super.key,
    this.measurement,
    this.index,
    this.isEditing = false,
  });

  // Add static show method
  static Future<void> show(
    BuildContext context, {
    Measurement? measurement,
    int? index,
    bool isEditing = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return showDialog(
        context: context,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final theme = Theme.of(context);

    return isDesktop
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
                        onPressed: () => Navigator.pop(context),
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
          backgroundColor: theme.colorScheme.background,
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
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _buildContent(theme, isDesktop),
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
      decoration: _inputDecoration('Style'),
      value: _selectedStyle,
      items:
          _styleOptions.map((String style) {
            return DropdownMenuItem<String>(value: style, child: Text(style));
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
    return _buildSectionCard(
      title: 'Style & Fabric',
      icon: Icons.style_outlined,
      color: Theme.of(context).colorScheme.primary,
      children: [
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
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fabricNameController,
          // ...existing fabric name field code...
        ),
      ],
    );
  }

  Widget _buildDesignTypeField() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Design Type'),
      value: _selectedDesignType,
      items: _designOptions.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
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
      decoration: _inputDecoration('Tarboosh Style'),
      value: _selectedTarbooshType,
      items: _tarbooshOptions.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: readOnly ? null : (String? newValue) {
        setState(() {
          _selectedTarbooshType = newValue!;
          _tarbooshController.text = newValue; // Always keep tarboosh field in sync
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
