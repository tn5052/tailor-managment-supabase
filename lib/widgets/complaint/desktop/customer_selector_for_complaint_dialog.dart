import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/customer.dart';
import '../../../services/customer_service.dart';
import '../../../theme/inventory_design_config.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerSelectorForComplaintDialog extends StatefulWidget {
  final Function(Customer customer) onCustomerSelected;

  const CustomerSelectorForComplaintDialog({super.key, required this.onCustomerSelected});

  static Future<Customer?> show(BuildContext context) {
    return showDialog<Customer>(
      context: context,
      builder: (context) => CustomerSelectorForComplaintDialog(
        onCustomerSelected: (customer) {
          Navigator.of(context).pop(customer);
        },
      ),
    );
  }

  @override
  State<CustomerSelectorForComplaintDialog> createState() => _CustomerSelectorForComplaintDialogState();
}

class _CustomerSelectorForComplaintDialogState extends State<CustomerSelectorForComplaintDialog> {
  final SupabaseService _customerService = SupabaseService();
  final _searchController = TextEditingController();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final response = await Supabase.instance.client.from('customers').select();
    final customers = (response as List).map((e) => Customer.fromJson(e)).toList();
    setState(() {
      _customers = customers;
      _filteredCustomers = customers;
      _isLoading = false;
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      _filteredCustomers = _customers
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.phone.contains(query) ||
              c.billNumber.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select a Customer', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: _filterCustomers,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or bill number...',
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return ListTile(
                            title: Text(customer.name),
                            subtitle: Text(customer.phone),
                            onTap: () => widget.onCustomerSelected(customer),
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
}
