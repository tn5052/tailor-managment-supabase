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
      'created_at': DateTime.now().toIso8601String(), // Add creation timestamp
      'referred_by': customer.referredBy, // Save the referredBy value
      'family_id': customer.familyId,
      'family_relation': customer.familyRelation?.name,
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
          'referred_by': customer.referredBy, // Update the referredBy value
          'family_id': customer.familyId,
          'family_relation': customer.familyRelation?.name,
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
          .limit(50); // Get more numbers to analyze

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
      final response =
          await _client
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
      final response =
          await _client
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

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final response = await _client.from('customers').select();
    return (response as List).map((map) => Customer.fromMap(map)).toList();
  }

  // Add this new method
  Future<Customer?> getCustomerById(String id) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('id', id)
          .single();
      return Customer.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching customer by ID: $e');
      return null;
    }
  }

  // Fix the getReferralCount method
  Future<int> getReferralCount(String customerId) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('referred_by', customerId);
      
      // Count the number of records in the response
      return (response as List).length;
    } catch (e) {
      debugPrint('Error fetching referral count: $e');
      return 0;
    }
  }

  Future<List<Customer>> getReferredCustomers(String customerId) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('referred_by', customerId)
          .order('created_at', ascending: false);
      
      return (response as List).map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching referred customers: $e');
      return [];
    }
  }

  Future<List<Customer>> getFamilyMembers(String familyId) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .or('id.eq.${familyId},family_id.eq.${familyId}')
          .order('family_relation', ascending: true)
          .order('created_at', ascending: false);
      
      return (response as List).map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching family members: $e');
      return [];
    }
  }

  Future<bool> addFamilyMember(String customerId, String familyMemberId, FamilyRelation relation) async {
    try {
      await _client.rpc('add_family_member', params: {
        'customer_id': customerId,
        'family_member_id': familyMemberId,
        'relation': relation.name,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding family member: $e');
      return false;
    }
  }

  Future<bool> removeFamilyMember(String customerId) async {
    try {
      await _client
          .from('customers')
          .update({
            'family_id': null,
            'family_relation': null,
          })
          .eq('id', customerId);
      return true;
    } catch (e) {
      debugPrint('Error removing family member: $e');
      return false;
    }
  }

  // Add this method to get all related family groups
  Future<List<List<Customer>>> getCustomerFamilyGroups() async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .not('family_id', 'is', null)
          .order('family_id', ascending: true)
          .order('family_relation', ascending: true);

      // Group customers by family_id
      final Map<String, List<Customer>> familyGroups = {};
      for (var map in response) {
        final customer = Customer.fromMap(map);
        final familyId = customer.familyId!;
        familyGroups.putIfAbsent(familyId, () => []);
        familyGroups[familyId]!.add(customer);
      }

      return familyGroups.values.toList();
    } catch (e) {
      debugPrint('Error fetching family groups: $e');
      return [];
    }
  }
}