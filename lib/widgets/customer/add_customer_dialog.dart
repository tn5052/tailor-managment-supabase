import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/customer.dart';
import '../../services/supabase_service.dart';
import 'customer_selector_dialog.dart'; // Import CustomerSelectorDialog

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
  Customer? _referredBy;
  int _referralCount = 0;

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
      
      // Load referring customer if exists
      if (widget.customer!.referredBy != null) {
        _loadReferringCustomer(widget.customer!.referredBy!);
      }
    } else {
      _selectedGender = Gender.male;
    }
  }

  Future<void> _loadReferringCustomer(String referredById) async {
    try {
      final customer = await _supabaseService.getCustomerById(referredById);
      if (customer != null) {
        final count = await _supabaseService.getReferralCount(referredById);
        setState(() {
          _referredBy = customer;
          _referralCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error loading referring customer: $e');
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
    return await _supabaseService.generateUniqueBillNumber();
  }

  String? _validateBillNumber(String? value) {
    if (widget.isEditing) return null;
    if (!_useCustomBillNumber) return null;
    if (value == null || value.isEmpty) {
      return 'Please enter a bill number';
    }
    // Only allow numeric values
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Please enter only numbers';
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
          if (_useCustomBillNumber) {
            billNumber = _billNumberController.text;
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
          } else {
            billNumber = await _generateBillNumber();
          }
        }

        // Show loading indicator
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving customer...'),
            duration: Duration(seconds: 1),
          ),
        );

        final customer = Customer(
          id: widget.isEditing ? widget.customer!.id : const Uuid().v4(),
          billNumber: billNumber,
          name: _nameController.text,
          phone: _phoneController.text,
          whatsapp: _whatsappController.text,
          address: _addressController.text,
          gender: _selectedGender,
          referredBy: _referredBy?.id, // Save the ID of the referred customer
        );

        // Retry logic for saving
        int retries = 0;
        while (retries < 3) {
          try {
            if (widget.isEditing) {
              await _supabaseService.updateCustomer(customer);
            } else {
              await _supabaseService.addCustomer(customer);
            }
            break; // Success, exit loop
          } catch (e) {
            retries++;
            if (retries == 3) throw e; // Throw on final retry
            await Future.delayed(Duration(milliseconds: 500 * retries));
          }
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
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildReferralSection(ThemeData theme) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Reduced from 24
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(12), // Reduced from 16
            minVerticalPadding: 0, // Add this to reduce vertical padding
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              radius: 20, // Reduced from 24
              child: _referredBy != null
                  ? Text(
                      _referredBy!.name[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(
                      Icons.person_add_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
            ),
            title: Text(
              'Customer Referral',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: _referredBy != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Text(
                          'Referred by ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _referredBy!.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Select the customer who referred this person (Optional)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
            trailing: _referredBy != null
                ? IconButton.filledTonal(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () async {
                      final customer = await CustomerSelectorDialog.show(
                        context,
                        await _supabaseService.getAllCustomers(),
                      );
                      if (customer != null) {
                        final count = await _supabaseService.getReferralCount(customer.id);
                        setState(() {
                          _referredBy = customer;
                          _referralCount = count;
                        });
                      }
                    },
                    tooltip: 'Change referral',
                  )
                : null,
          ),
          if (_referredBy != null) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), // Reduced padding
              child: isDesktop 
                ? Row(
                    children: _buildReferralBadges(theme),
                  )
                : Wrap(
                    spacing: 6, // Reduced from 8
                    runSpacing: 6, // Reduced from 8
                    children: _buildReferralBadges(theme),
                  ),
            ),
            if (_referralCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), // Reduced padding
                child: Container(
                  padding: const EdgeInsets.all(8), // Reduced from 12
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Trusted Referrer - Has referred $_referralCount ${_referralCount == 1 ? 'customer' : 'customers'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (_referredBy == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), // Reduced padding
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final customer = await CustomerSelectorDialog.show(
                    context,
                    await _supabaseService.getAllCustomers(),
                  );
                  if (customer != null) {
                    final count = await _supabaseService.getReferralCount(customer.id);
                    setState(() {
                      _referredBy = customer;
                      _referralCount = count;
                    });
                  }
                },
                icon: const Icon(Icons.person_search),
                label: const Text('SELECT REFERRING CUSTOMER'),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildReferralBadges(ThemeData theme) {
    return [
      _buildInfoBadge(
        theme,
        Icons.phone_outlined,
        _referredBy!.phone,
        theme.colorScheme.primary,
      ),
      const SizedBox(width: 12),
      _buildInfoBadge(
        theme,
        Icons.receipt_outlined,
        '#${_referredBy!.billNumber}',
        theme.colorScheme.secondary,
      ),
      const SizedBox(width: 12),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _referralCount > 0 ? () => _showReferralsList(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: _buildInfoBadge(
            theme,
            Icons.people_outline,
            '$_referralCount ${_referralCount == 1 ? 'referral' : 'referrals'}',
            theme.colorScheme.tertiary,
            showClickHint: _referralCount > 0,
          ),
        ),
      ),
    ];
  }

  Future<void> _showReferralsList(BuildContext context) async {
    if (_referredBy == null) return;

    final theme = Theme.of(context);
    final customers = await _supabaseService.getReferredCustomers(_referredBy!.id);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        _referredBy!.name[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Referrals by ${_referredBy!.name}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${customers.length} ${customers.length == 1 ? 'customer' : 'customers'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: customers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(customer.name),
                      subtitle: Text('#${customer.billNumber}'),
                      trailing: Text(
                        customer.createdAt.toString().split(' ')[0],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(
    ThemeData theme,
    IconData icon,
    String text,
    Color color, {
    bool showClickHint = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showClickHint) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: color.withOpacity(0.5),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(ThemeData theme, {
    required String label,
    required IconData icon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary.withOpacity(0.7)),
      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1024;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(isDesktop ? 28 : 0),
      ),
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced title section with bill number
          Row(
            children: [
              if (!isDesktop) 
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEditing ? 'Edit Customer' : 'Add New Customer',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: isDesktop ? null : 20,
                      ),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bill #${widget.customer?.billNumber}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 24 : 16),
          
          // Mobile layout adjustments for referral section
          if (!isDesktop) ...[
            Text(
              'Customer Referral',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          _buildReferralSection(theme),
          
          Divider(color: theme.colorScheme.outlineVariant),
          SizedBox(height: isDesktop ? 16 : 12),
          
          // Form section
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, // For better mobile layout
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
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(
                        theme,
                        label: 'Custom Bill Number',
                        icon: Icons.receipt_outlined,
                        helperText: 'Must be unique',
                      ),
                      validator: _validateBillNumber,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                    theme,
                    label: 'Name',
                    icon: Icons.person_outline,
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
                  decoration: _buildInputDecoration(
                    theme,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
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
                  decoration: _buildInputDecoration(
                    theme,
                    label: 'WhatsApp (Optional)',
                    icon: Icons.whatshot_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: _buildInputDecoration(
                    theme,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Theme(
                  data: theme.copyWith(
                    segmentedButtonTheme: SegmentedButtonThemeData(
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        ),
                        backgroundColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return theme.colorScheme.primary;
                          }
                          return theme.colorScheme.surfaceVariant;
                        }),
                        foregroundColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return theme.colorScheme.onPrimary;
                          }
                          return theme.colorScheme.onSurfaceVariant;
                        }),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Gender:',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
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
                ),
              ],
            ),
          ),
          SizedBox(height: isDesktop ? 24 : 16),
                
          // Adjusted button layout for mobile
          if (isDesktop)
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
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _saveCustomer,
                    icon: Icon(widget.isEditing ? Icons.save : Icons.add),
                    label: Text(widget.isEditing ? 'SAVE' : 'ADD'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
