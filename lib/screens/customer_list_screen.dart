import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  // final FirebaseService _firebaseService = FirebaseService(); // REMOVE
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _filterCustomer(Customer customer, String query) {
    if (query.isEmpty) return true;

    final queryLower = query.toLowerCase();
    return customer.name.toLowerCase().contains(queryLower) ||
        customer.phone.toLowerCase().contains(queryLower) ||
        customer.billNumber.toLowerCase().contains(queryLower);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: theme.colorScheme.primaryContainer,
        title: Text(
          'Customers',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isDesktop) ...[
            FilledButton.icon(
              onPressed: () => _showAddCustomerDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Customer'),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0, // Keep only vertical padding
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // Add padding only to search bar
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or bill number',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16), // Increased spacing
            // Customer list with matching padding
            Expanded(
              child: StreamBuilder<List<Customer>>(
                // stream: _firebaseService.getCustomersStream(), // REMOVE
                stream: _supabaseService.getCustomersStream(),
                builder: (context, snapshot) {
                  // Add debug prints
                  debugPrint('Connection state: ${snapshot.connectionState}');
                  debugPrint('Has error: ${snapshot.hasError}');
                  if (snapshot.hasError) {
                    debugPrint('Error: ${snapshot.error}');
                  }
                  debugPrint('Data length: ${snapshot.data?.length}');

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customers = snapshot.data ?? [];
                  final filteredCustomers =
                      customers
                          .where(
                            (customer) =>
                                _filterCustomer(customer, _searchQuery),
                          )
                          .toList();

                  if (customers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No customers yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredCustomers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No results found for "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ), // Add padding to list
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 12,
                        ), // Adjusted spacing
                        child: _CustomerCard(
                          customer: customer,
                          onEdit:
                              () => _showEditCustomerDialog(
                                context,
                                customer,
                                index,
                              ),
                          onDelete:
                              () => _confirmDelete(context, () async {
                                // await _firebaseService.deleteCustomer(customer.id); // REMOVE
                                await _supabaseService.deleteCustomer(
                                  customer.id,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${customer.name} has been deleted',
                                    ),
                                  ),
                                );
                              }),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        label: const Text('Add Customer'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Customer'),
            content: const Text(
              'Are you sure you want to delete this customer? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('DELETE'),
              ),
            ],
          ),
    );
  }

  Future<void> _showAddCustomerDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: const Card(
                margin: EdgeInsets.zero,
                child: SingleChildScrollView(child: _AddCustomerForm()),
              ),
            ),
          ),
    );
  }

  Future<void> _showEditCustomerDialog(
    BuildContext context,
    Customer customer,
    int index,
  ) {
    return showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Card(
                margin: EdgeInsets.zero,
                child: SingleChildScrollView(
                  child: _AddCustomerForm(
                    customer: customer,
                    index: index,
                    isEditing: true,
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      color: theme.colorScheme.surface.withOpacity(0.8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(8), // Reduced from 16 to 8
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              flex: 2,
                              child: Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.receipt_outlined,
                                      size: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        '#${customer.billNumber}',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCustomerBadge(
                      context,
                      'Phone: ${customer.phone}',
                      theme.colorScheme.primary,
                    ),
                    if (customer.whatsapp.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildCustomerBadge(
                          context,
                          'WhatsApp: ${customer.whatsapp}',
                          theme.colorScheme.secondary,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildCustomerBadge(
                        context,
                        'Gender: ${customer.gender.name.toUpperCase()}',
                        theme.colorScheme.tertiary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildCustomerBadge(
                        context,
                        'Address: ${customer.address}',
                        theme.colorScheme.error,
                        maxWidth: 200,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerBadge(
    BuildContext context,
    String text,
    Color color, {
    double? maxWidth,
  }) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _AddCustomerForm extends StatefulWidget {
  final Customer? customer;
  final int? index;
  final bool isEditing;

  const _AddCustomerForm({this.customer, this.index, this.isEditing = false});

  @override
  State<_AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<_AddCustomerForm> {
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
    if (!_useCustomBillNumber || value == null || value.isEmpty) {
      return null;
    }
    return null;
  }

  Future<bool> _checkDuplicateBillNumber(String billNumber) async {
    final response = await Supabase.instance.client
        .from('customers')
        .select('bill_number')
        .eq('bill_number', billNumber);
    return (response as List<dynamic>).isEmpty;
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final billNumber =
            widget.isEditing
                ? widget.customer!.billNumber
                : await _generateBillNumber();

        if (_useCustomBillNumber && !widget.isEditing) {
          final isValid = await _checkDuplicateBillNumber(
            _billNumberController.text,
          );
          if (!isValid) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bill number already exists')),
            );
            return;
          }
        }

        final customer = Customer(
          id: widget.isEditing ? widget.customer!.id : const Uuid().v4(),
          billNumber:
              _useCustomBillNumber ? _billNumberController.text : billNumber,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
