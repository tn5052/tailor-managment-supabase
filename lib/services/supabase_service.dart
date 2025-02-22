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
      'created_at': DateTime.now().toIso8601String(),  // Add creation timestamp
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

  // Get all customers stream: using realtime when possible, falling back to polling if needed.
  Stream<List<Customer>> getCustomersStream() {
    try {
      final realtimeStream = _client
          .from('customers')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((maps) => maps.map((map) => Customer.fromMap(map)).toList());
      // Listen for errors and switch to polling if required.
      return realtimeStream.handleError((error) {
        debugPrint('Realtime stream error: $error');
      });
    } catch (e) {
      debugPrint('Realtime subscription failed; switching to polling: $e');
      // Fallback polling stream polling every 5 seconds.
      return (() async* {
        while (true) {
          try {
            final data = await _client
                .from('customers')
                .select()
                .order('created_at', ascending: false);
            yield (data as List).map((map) => Customer.fromMap(map)).toList();
          } catch (err) {
            debugPrint('Polling error: $err');
            yield <Customer>[];
          }
          await Future.delayed(const Duration(seconds: 5));
        }
      })();
    }
  }

  // Get last bill number
  Future<int> getLastBillNumber() async {
    try {
      final response = await _client
          .from('customers')
          .select('bill_number')
          .order('bill_number', ascending: false)
          .limit(50);  // Get more numbers to analyze

      if (response.isEmpty) return 0;

      // Find the highest number by checking all recent entries
      int highest = 0;
      for (var item in response) {
        final String billStr = item['bill_number']?.toString() ?? '0';
        final int? number = int.tryParse(billStr);
        if (number != null && number > highest) {
          highest = number;
        }
      }
      return highest;
    } catch (e) {
      debugPrint('Error fetching last bill number: $e');
      return 0;
    }
  }

  Future<String> generateUniqueBillNumber() async {
    int retries = 0;
    const maxRetries = 5;
    
    while (retries < maxRetries) {
      try {
        final lastNumber = await getLastBillNumber();
        final newNumber = (lastNumber + 1 + retries).toString();
        
        // Verify uniqueness
        final isUnique = await isBillNumberUnique(newNumber);
        if (isUnique) {
          return newNumber;
        }
      } catch (e) {
        debugPrint('Error in attempt $retries: $e');
      }
      retries++;
    }
    
    // If all retries failed, generate a timestamp-based number as fallback
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return (timestamp % 100000).toString();
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
