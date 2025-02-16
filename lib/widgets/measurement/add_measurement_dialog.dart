import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/measurement.dart';
import '../../models/customer.dart';
import '../../services/measurement_service.dart';
import '../../services/supabase_service.dart'; // Import SupabaseService

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
  final _toolArabiController = TextEditingController();
  final _toolKuwaitiController = TextEditingController();
  final _sadurController = TextEditingController();
  final _kumController = TextEditingController();
  final _katfController = TextEditingController();
  final _toolKhalfiController = TextEditingController();
  final _ardController = TextEditingController();
  final _raqbaController = TextEditingController();
  final _fkmController = TextEditingController();
  final _tahtController = TextEditingController();
  final _tarbooshController = TextEditingController();
  final _kumSalaiController = TextEditingController();
  final _khayataController = TextEditingController();
  final _kisraController = TextEditingController();
  final _batiController = TextEditingController();
  final _kafController = TextEditingController();
  final _tatreezController = TextEditingController();
  final _jasbaController = TextEditingController();
  final _tahtKanduraController = TextEditingController();
  final _shaibController = TextEditingController();
  final _notesController = TextEditingController();
  final _hesbaController = TextEditingController();
  final _sheebController = TextEditingController();

  final _styleOptions = [
    'Arabic',
    'Kuwaiti',
    'Saudi',
    'Omani',
    'Qatari',
    'Emirati',
  ];
  String? _selectedStyle;

  @override
  void dispose() {
    _scrollController.dispose();
    _styleController.dispose();
    _toolArabiController.dispose();
    _toolKuwaitiController.dispose();
    _sadurController.dispose();
    _kumController.dispose();
    _katfController.dispose();
    _toolKhalfiController.dispose();
    _ardController.dispose();
    _raqbaController.dispose();
    _fkmController.dispose();
    _tahtController.dispose();
    _tarbooshController.dispose();
    _kumSalaiController.dispose();
    _khayataController.dispose();
    _kisraController.dispose();
    _batiController.dispose();
    _kafController.dispose();
    _tatreezController.dispose();
    _jasbaController.dispose();
    _tahtKanduraController.dispose();
    _shaibController.dispose();
    _notesController.dispose();
    _hesbaController.dispose();
    _sheebController.dispose();
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
      _toolArabiController.text = widget.measurement!.toolArabi.toString();
      _toolKuwaitiController.text = widget.measurement!.toolKuwaiti.toString();
      _sadurController.text = widget.measurement!.sadur.toString();
      _kumController.text = widget.measurement!.kum.toString();
      _katfController.text = widget.measurement!.katf.toString();
      _toolKhalfiController.text = widget.measurement!.toolKhalfi.toString();
      _ardController.text = widget.measurement!.ard.toString();
      _raqbaController.text = widget.measurement!.raqba.toString();
      _fkmController.text = widget.measurement!.fkm.toString();
      _tahtController.text = widget.measurement!.taht.toString();
      _tarbooshController.text = widget.measurement!.tarboosh;
      _kumSalaiController.text = widget.measurement!.kumSalai;
      _khayataController.text = widget.measurement!.khayata;
      _kisraController.text = widget.measurement!.kisra;
      _batiController.text = widget.measurement!.bati;
      _kafController.text = widget.measurement!.kaf;
      _tatreezController.text = widget.measurement!.tatreez;
      _jasbaController.text = widget.measurement!.jasba;
      _tahtKanduraController.text = widget.measurement!.tahtKandura;
      _shaibController.text = widget.measurement!.shaib;
      _notesController.text = widget.measurement!.notes;
      _hesbaController.text = widget.measurement!.hesba;
      _sheebController.text = widget.measurement!.sheeb;
    }
  }

  Future<void> _addMeasurement() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final measurement = Measurement(
          id: widget.isEditing ? widget.measurement!.id : const Uuid().v4(),
          customerId: _selectedCustomerId!,
          billNumber: _billNumber,
          style: _styleController.text,
          toolArabi: double.tryParse(_toolArabiController.text) ?? 0,
          toolKuwaiti: double.tryParse(_toolKuwaitiController.text) ?? 0,
          sadur: double.tryParse(_sadurController.text) ?? 0,
          kum: double.tryParse(_kumController.text) ?? 0,
          katf: double.tryParse(_katfController.text) ?? 0,
          toolKhalfi: double.tryParse(_toolKhalfiController.text) ?? 0,
          ard: double.tryParse(_ardController.text) ?? 0,
          raqba: double.tryParse(_raqbaController.text) ?? 0,
          fkm: double.tryParse(_fkmController.text) ?? 0,
          taht: double.tryParse(_tahtController.text) ?? 0,
          tarboosh: _tarbooshController.text,
          kumSalai: _kumSalaiController.text,
          khayata: _khayataController.text,
          kisra: _kisraController.text,
          bati: _batiController.text,
          kaf: _kafController.text,
          tatreez: _tatreezController.text,
          jasba: _jasbaController.text,
          tahtKandura: _tahtKanduraController.text,
          shaib: _shaibController.text,
          notes: _notesController.text,
          hesba: _hesbaController.text,
          sheeb: _sheebController.text,
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
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: theme.colorScheme.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            widget.isEditing ? 'Edit Measurement' : 'New Measurement',
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _addMeasurement,
                icon: const Icon(Icons.save),
                label: const Text('SAVE'),
              ),
            ),
          ],
        ),
        body: Form(
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

              _buildSectionCard(
                title: 'Style Selection',
                icon: Icons.style_outlined,
                children: [_buildStyleField()],
              ),
              const SizedBox(height: 16),

              if (_styleController.text == 'Arabic')
                _buildSectionCard(
                  title: 'Arabic Measurements',
                  icon: Icons.straighten,
                  color: Theme.of(context).colorScheme.primary,
                  children: [
                    _buildMeasurementFields(
                      isDesktop: isDesktop,
                      fields: [
                        MeasurementField(
                          controller: _toolArabiController,
                          label: 'Arabic Length',
                          required: true,
                        ),
                        MeasurementField(
                          controller: _sadurController,
                          label: 'Chest',
                        ),
                        MeasurementField(
                          controller: _ardController,
                          label: 'Width',
                        ),
                        MeasurementField(
                          controller: _tahtKanduraController,
                          label: 'Under Kandura',
                          isTextField: true,
                        ),
                      ],
                    ),
                  ],
                )
              else
                _buildSectionCard(
                  title: '${_styleController.text} Measurements',
                  icon: Icons.straighten,
                  color: Theme.of(context).colorScheme.primary,
                  children: [
                    _buildMeasurementFields(
                      isDesktop: isDesktop,
                      fields: [
                        MeasurementField(
                          controller: _toolKuwaitiController,
                          label: 'Kuwaiti Length',
                          required: true,
                        ),
                        MeasurementField(
                          controller: _katfController,
                          label: 'Shoulder',
                        ),
                        MeasurementField(
                          controller: _tahtController,
                          label: 'Under',
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: 'Common Measurements',
                icon: Icons.straighten,
                color: Theme.of(context).colorScheme.secondary,
                children: [
                  _buildMeasurementFields(
                    isDesktop: isDesktop,
                    fields: [
                      MeasurementField(
                        controller: _toolKhalfiController,
                        label: 'Back Length',
                      ),
                      MeasurementField(
                        controller: _kumController,
                        label: 'Sleeve',
                      ),
                      MeasurementField(
                        controller: _fkmController,
                        label: 'Cuff',
                      ),
                      MeasurementField(
                        controller: _raqbaController,
                        label: 'Neck',
                      ),
                      MeasurementField(
                        controller: _hesbaController,
                        label: 'Hesba',
                        isTextField: true,
                      ),
                      MeasurementField(
                        controller: _sheebController,
                        label: 'Sheeb',
                        isTextField: true,
                      ),
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
                        controller: _kumSalaiController,
                        label: 'Sleeve Style',
                      ),
                      StyleDetailField(
                        controller: _khayataController,
                        label: 'Stitching',
                      ),
                      StyleDetailField(
                        controller: _kisraController,
                        label: 'Pleats',
                      ),
                      StyleDetailField(
                        controller: _batiController,
                        label: 'Side Pocket',
                      ),
                      StyleDetailField(
                        controller: _kafController,
                        label: 'Cuff Style',
                      ),
                      StyleDetailField(
                        controller: _tatreezController,
                        label: 'Embroidery',
                      ),
                      StyleDetailField(
                        controller: _jasbaController,
                        label: 'Side Slit',
                      ),
                      StyleDetailField(
                        controller: _shaibController,
                        label: 'Shaib Style',
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
        ),
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
          children:
              fields.map((field) {
                return _buildTextField(field.controller, field.label);
              }).toList(),
        );
      },
    );
  }

  Widget _buildCustomerField() {
    return StreamBuilder<List<Customer>>(
      stream: _supabaseService.getCustomersStream(), // Use Supabase stream
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final customers = snapshot.data ?? [];

        return DropdownButtonFormField<String>(
          decoration: _inputDecoration('Customer'),
          value: _selectedCustomerId,
          items:
              customers.map((Customer customer) {
                return DropdownMenuItem<String>(
                  value: customer.id,
                  child: Text('${customer.name} (${customer.phone})'),
                );
              }).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a customer';
            }
            return null;
          },
          onChanged: (String? newValue) {
            if (newValue != null) {
              final selectedCustomer = customers.firstWhere(
                (customer) => customer.id == newValue,
              );
              setState(() {
                _selectedCustomerId = newValue;
                _billNumber = selectedCustomer.billNumber;
              });
            }
          },
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
      decoration: _inputDecoration(label, suffixText: 'cm'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator:
          required
              ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              }
              : null,
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
