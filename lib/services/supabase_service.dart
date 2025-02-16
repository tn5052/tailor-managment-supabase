import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Add a new customer
  Future<void> addCustomer(Customer customer) async {
    await _client.from('customers').insert({
      'id': customer.id,
      'bill_number': customer.billNumber,
      'name': customer.name,
      'phone': customer.phone,
      'whatsapp': customer.whatsapp,
      'address': customer.address,
      'gender': customer.gender.name,
    });
  }

  // Update an existing customer
  Future<void> updateCustomer(Customer customer) async {
    await _client
        .from('customers')
        .update({
          'bill_number': customer.billNumber,
          'name': customer.name,
          'phone': customer.phone,
          'whatsapp': customer.whatsapp,
          'address': customer.address,
          'gender': customer.gender.name,
        })
        .eq('id', customer.id);
  }

  // Delete a customer
  Future<void> deleteCustomer(String customerId) async {
    await _client.from('customers').delete().eq('id', customerId);
  }

  // Get all customers stream
  Stream<List<Customer>> getCustomersStream() {
    return _client
        .from('customers')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // Ensure ordering
        .map((maps) => maps.map((map) => Customer.fromMap(map)).toList());
  }

  // Get last bill number
  Future<int> getLastBillNumber() async {
    try {
      final response =
          await _client
              .from('customers')
              .select('bill_number')
              .order('created_at', ascending: false)
              .limit(1)
              .single();

      final data = response;

      final String lastBillNumber = data['bill_number'] ?? '';
      final RegExp regex = RegExp(r'TMS-(\d+)');
      final Match? match = regex.firstMatch(lastBillNumber);

      return match != null ? int.parse(match.group(1)!) : 0;
    } catch (e) {
      debugPrint('Error fetching last bill number: $e');
      return 0;
    }
  }
}
