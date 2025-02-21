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
        // Remove the deleted condition since it doesn't exist
        .order(
          'bill_number',
          ascending: false,
        ) // Changed from created_at to bill_numberFT
        .map((maps) => maps.map((map) => Customer.fromMap(map)).toList())
        .handleError((error) {
          debugPrint('Error in customers stream: $error');
          return [];
        });
  }

  // Get last bill number
  Future<int> getLastBillNumber() async {
    try {
      final response = await _client
          .from('customers')
          .select('bill_number')
          .order('bill_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return 0;

      final String lastBillNumber = response['bill_number'] ?? '';
      final RegExp regex = RegExp(r'TMS-(\d+)');
      final Match? match = regex.firstMatch(lastBillNumber);

      return match != null ? int.parse(match.group(1)!) : 0;
    } catch (e) {
      debugPrint('Error fetching last bill number: $e');
      return 0;
    }
  }

  // Add this new method to check for duplicate bill numbers
  Future<bool> isBillNumberUnique(String billNumber) async {
    try {
      final response = await _client
          .from('customers')
          .select('bill_number')
          .eq('bill_number', billNumber)
          .limit(1)
          .maybeSingle();
      
      return response == null; // If no record found, the bill number is unique
    } catch (e) {
      debugPrint('Error checking bill number uniqueness: $e');
      return false;
    }
  }

  // Get customer name by ID
  Future<String> getCustomerName(String customerId) async {
    try {
      final response = await _client
          .from('customers')
          .select('name')
          .eq('id', customerId)
          .single();
      return response['name'] as String;
    } catch (e) {
      debugPrint('Error fetching customer name: $e');
      return 'Unknown Customer';
    }
  }
}
