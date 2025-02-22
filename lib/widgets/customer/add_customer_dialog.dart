import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/customer.dart';
import '../../services/supabase_service.dart';

class AddCustomerDialog extends StatefulWidget {
  final Customer? customer;
  final int? index;
  final bool isEditing;

  const AddCustomerDialog({
    super.key,
    this.customer,
    this.index,
    this.isEditing = false,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  final _billNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  late Gender _selectedGender;
  bool _useCustomBillNumber = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      _whatsappController.text = widget.customer!.whatsapp;
      _addressController.text = widget.customer!.address;
      _selectedGender = widget.customer!.gender;
      _billNumberController.text = widget.customer!.billNumber;
    } else {
      _selectedGender = Gender.male;
    }
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<String> _generateBillNumber() async {
    if (_useCustomBillNumber && _billNumberController.text.isNotEmpty) {
      return _billNumberController.text;
    }

    final lastNumber = await _supabaseService.getLastBillNumber();
    return 'TMS-${(lastNumber + 1).toString().padLeft(3, '0')}';
  }

  String? _validateBillNumber(String? value) {
    if (widget.isEditing) return null;
    if (!_useCustomBillNumber) return null;
    if (value == null || value.isEmpty) {
      return 'Please enter a bill number';
    }
    if (!value.startsWith('C-')) {
      return 'Bill number must start with TMS-';
    }
    final RegExp regex = RegExp(r'TMS-\d{3,}');
    if (!regex.hasMatch(value)) {
      return 'Format should be TMS-XXX (where X is a number)';
    }
    return null;
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        String billNumber;
        if (widget.isEditing) {
          billNumber = widget.customer!.billNumber;
        } else {
          billNumber = _useCustomBillNumber 
              ? _billNumberController.text
              : await _generateBillNumber();

          final isUnique = await _supabaseService.isBillNumberUnique(billNumber);
          if (!isUnique) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This bill number already exists. Please try another.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        final customer = Customer(
          id: widget.isEditing ? widget.customer!.id : const Uuid().v4(),
          billNumber: billNumber,
          name: _nameController.text,
          phone: _phoneController.text,
          whatsapp: _whatsappController.text,
          address: _addressController.text,
          gender: _selectedGender,
        );

        if (widget.isEditing) {
          await _supabaseService.updateCustomer(customer);
        } else {
          await _supabaseService.addCustomer(customer);
        }
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? '${customer.name} has been updated'
                  : '${customer.name} has been added',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.isEditing ? Icons.edit : Icons.person_add,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Text(
                widget.isEditing ? 'Edit Customer' : 'Add New Customer',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.isEditing) ...[
                  Row(
                    children: [
                      Checkbox(
                        value: _useCustomBillNumber,
                        onChanged: (value) {
                          setState(() {
                            _useCustomBillNumber = value ?? false;
                            if (!_useCustomBillNumber) {
                              _billNumberController.clear();
                            }
                          });
                        },
                      ),
                      const Text('Use Custom Bill Number'),
                    ],
                  ),
                  if (_useCustomBillNumber) ...[
                    TextFormField(
                      controller: _billNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Bill Number',
                        prefixIcon: Icon(Icons.receipt_outlined),
                        helperText: 'Must be unique',
                      ),
                      validator: _validateBillNumber,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _whatsappController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp (Optional)',
                    prefixIcon: Icon(Icons.whatshot_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Gender:'),
                    const SizedBox(width: 16),
                    SegmentedButton<Gender>(
                      segments: const [
                        ButtonSegment(
                          value: Gender.male,
                          label: Text('Male'),
                          icon: Icon(Icons.male),
                        ),
                        ButtonSegment(
                          value: Gender.female,
                          label: Text('Female'),
                          icon: Icon(Icons.female),
                        ),
                      ],
                      selected: {_selectedGender},
                      onSelectionChanged: (Set<Gender> selection) {
                        setState(() {
                          _selectedGender = selection.first;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _saveCustomer,
                icon: Icon(widget.isEditing ? Icons.save : Icons.add),
                label: Text(widget.isEditing ? 'SAVE' : 'ADD'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
