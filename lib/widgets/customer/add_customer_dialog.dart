import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/customer.dart';
import '../../services/supabase_service.dart';
import 'customer_selector_dialog.dart'; // Import CustomerSelectorDialog
import 'family_selector_section.dart'; // Import FamilySelectorSection

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

  // Add these fields
  Customer? _familyMember;
  FamilyRelation? _familyRelation;

  List<Customer> _referredCustomers = [];
  List<Customer> _familyMembers = [];

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

      if (widget.customer!.familyId != null) {
        _loadFamilyMember(widget.customer!.familyId!);
      }

      _loadReferredCustomers(widget.customer!.id);
      _loadFamilyMembers(widget.customer!.id);
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

  Future<void> _loadFamilyMember(String familyId) async {
    try {
      final member = await _supabaseService.getCustomerById(familyId);
      if (member != null) {
        setState(() {
          _familyMember = member;
          _familyRelation = widget.customer!.familyRelation;
        });
      }
    } catch (e) {
      debugPrint('Error loading family member: $e');
    }
  }

  Future<void> _loadReferredCustomers(String customerId) async {
    try {
      final customers = await _supabaseService.getReferredCustomers(customerId);
      setState(() {
        _referredCustomers = customers;
      });
    } catch (e) {
      debugPrint('Error loading referred customers: $e');
    }
  }

  Future<void> _loadFamilyMembers(String customerId) async {
    try {
      final familyMembers = await _supabaseService.getFamilyMembers(customerId);
      setState(() {
        _familyMembers = familyMembers;
      });
    } catch (e) {
      debugPrint('Error loading family members: $e');
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
          familyId: _familyMember?.id,
          familyRelation: _familyRelation,
        );

        // If editing and family connection was removed, remove it from database
        if (widget.isEditing && 
            widget.customer?.familyId != null && 
            _familyMember == null) {
          await _supabaseService.removeFamilyMember(widget.customer!.id);
        }

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

  Future<void> _confirmRemoveReferral(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Referral'),
        content: Text(
          'Are you sure you want to remove ${_referredBy?.name} as the referring customer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _referredBy = null;
                _referralCount = 0;
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralSection(ThemeData theme) {
    final brightness = theme.brightness;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: brightness == Brightness.light
            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with remove option
          Row(
            children: [
              Icon(
                Icons.person_add_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Referral',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (_referredBy != null) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.link_off, size: 18),
                  tooltip: 'Remove referral',
                  onPressed: () => _confirmRemoveReferral(context),
                ),
              ],
            ],
          ),

          if (_referredBy != null) ...[
            const SizedBox(height: 8),
            // Selected referrer info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brightness == Brightness.light
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: Text(
                      _referredBy!.name[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _referredBy!.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '#${_referredBy!.billNumber} · ${_referredBy!.phone}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  IconButton.filledTonal(
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
                    icon: const Icon(Icons.edit, size: 16),
                  ),
                ],
              ),
            ),

            if (_referralCount > 0) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showReferralsList(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_referralCount ${_referralCount == 1 ? 'referral' : 'referrals'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 4),
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
                icon: const Icon(Icons.person_search, size: 18),
                label: const Text('SELECT REFERRING CUSTOMER'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
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

  Future<void> _showReferredCustomersDialog(BuildContext context) async {
    final theme = Theme.of(context);

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
                        widget.customer!.name[0].toUpperCase(),
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
                            'Referred Customers by ${widget.customer!.name}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_referredCustomers.length} ${_referredCustomers.length == 1 ? 'customer' : 'customers'}',
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
                  itemCount: _referredCustomers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = _referredCustomers[index];
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
                      subtitle: Text('#${customer.billNumber} · ${customer.phone}'),
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

  Future<void> _showFamilyMembersDialog(BuildContext context) async {
    final theme = Theme.of(context);

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
                        widget.customer!.name[0].toUpperCase(),
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
                            'Family Members of ${widget.customer!.name}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_familyMembers.length} ${_familyMembers.length == 1 ? 'member' : 'members'}',
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
                  itemCount: _familyMembers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = _familyMembers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(member.name),
                      subtitle: Text(member.familyRelationDisplay),
                      trailing: Text(
                        member.createdAt.toString().split(' ')[0],
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

  Widget _buildHeaderSection(ThemeData theme, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 24 : 16,
        horizontal: isDesktop ? 24 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isDesktop ? 28 : 0),
          topRight: Radius.circular(isDesktop ? 28 : 0),
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
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
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildInfoBadge(
                          theme,
                          'Bill #${widget.customer?.billNumber}',
                          Icons.receipt_outlined,
                          theme.colorScheme.primary,
                        ),
                        if (_referredCustomers.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildActionBadge(
                            theme,
                            '${_referredCustomers.length} Referred',
                            Icons.people_outline,
                            theme.colorScheme.secondary,
                            () => _showReferredCustomersDialog(context),
                          ),
                        ],
                        if (_familyMembers.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildActionBadge(
                            theme,
                            '${_familyMembers.length} Family',
                            Icons.family_restroom,
                            theme.colorScheme.tertiary,
                            () => _showFamilyMembersDialog(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(
    ThemeData theme,
    String text,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBadge(
    ThemeData theme,
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: color.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1024;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenSize.height * (isDesktop ? 0.9 : 0.95),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 28 : 0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(theme, isDesktop),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: isDesktop ? 24 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isEditing && _useCustomBillNumber) ...[
                    _buildSectionHeader(
                      theme,
                      'Bill Number',
                      Icons.receipt_outlined,
                    ),
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
                    const SizedBox(height: 24),
                  ],

                  _buildSectionHeader(
                    theme,
                    'Basic Information',
                    Icons.person_outline,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Basic info fields
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
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
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
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _whatsappController,
                                decoration: _buildInputDecoration(
                                  theme,
                                  label: 'WhatsApp (Optional)',
                                  icon: Icons.whatshot_outlined,
                                ),
                              ),
                            ),
                          ],
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
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        Row(
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    theme,
                    'Referral & Family',
                    Icons.people_outline,
                  ),
                  _buildReferralSection(theme),
                  FamilySelectorSection(
                    selectedFamilyMember: _familyMember,
                    selectedRelation: _familyRelation,
                    onFamilyMemberSelected: (customer) {
                      setState(() => _familyMember = customer);
                    },
                    onRelationChanged: (relation) {
                      setState(() => _familyRelation = relation);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Footer with actions
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
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
          ),
        ],
      ),
    );
  }
}
