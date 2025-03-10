import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import '../utils/tenant_manager.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Add a new customer
  Future<void> addCustomer(Customer customer) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    // First check if bill number is unique for this tenant
    final isUnique = await isBillNumberUnique(customer.billNumber);
    if (!isUnique) {
      throw Exception('Bill number already exists for this tenant. Please use a different bill number.');
    }
    
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
      'tenant_id': tenantId,
    });
  }

  // Update an existing customer
  Future<void> updateCustomer(Customer customer) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    // Check if the bill number is being changed
    final existingCustomer = await getCustomerById(customer.id);
    if (existingCustomer != null && existingCustomer.billNumber != customer.billNumber) {
      // If bill number changed, check if new bill number is unique
      final isUnique = await isBillNumberUnique(customer.billNumber);
      if (!isUnique) {
        throw Exception('Bill number already exists for this tenant. Please use a different bill number.');
      }
    }
    
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
        .eq('id', customer.id)
        .eq('tenant_id', tenantId);
  }

  // Delete a customer
  Future<void> deleteCustomer(String customerId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    await _client
        .from('customers')
        .delete()
        .eq('id', customerId)
        .eq('tenant_id', tenantId);
  }

  // Get all customers stream: using realtime when possible, falling back to polling if needed.
  Stream<List<Customer>> getCustomersStream() {
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final realtimeStream = _client
          .from('customers')
          .stream(primaryKey: ['id'])
          .eq('tenant_id', tenantId)
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
                .eq('tenant_id', tenantId)
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
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response = await _client
          .from('customers')
          .select('bill_number')
          .eq('tenant_id', tenantId)
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
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response =
          await _client
              .from('customers')
              .select('bill_number')
              .eq('bill_number', billNumber)
              .eq('tenant_id', tenantId)
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
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response =
          await _client
              .from('customers')
              .select('name')
              .eq('id', customerId)
              .eq('tenant_id', tenantId)
              .single();
      return response['name'] as String;
    } catch (e) {
      debugPrint('Error fetching customer name: $e');
      return 'Unknown Customer';
    }
  }

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final String tenantId = TenantManager.getCurrentTenantId();
    final response = await _client
        .from('customers')
        .select()
        .eq('tenant_id', tenantId);
    return (response as List).map((map) => Customer.fromMap(map)).toList();
  }

  // Add this new method
  Future<Customer?> getCustomerById(String id) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('id', id)
          .eq('tenant_id', tenantId)
          .single();
      return Customer.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching customer by ID: $e');
      return null;
    }
  }

  // Fix the getReferralCount method
  Future<int> getReferralCount(String customerId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('referred_by', customerId)
          .eq('tenant_id', tenantId);
      
      // Count the number of records in the response
      return (response as List).length;
    } catch (e) {
      debugPrint('Error fetching referral count: $e');
      return 0;
    }
  }

  Future<List<Customer>> getReferredCustomers(String customerId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('referred_by', customerId)
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);
      
      return (response as List).map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching referred customers: $e');
      return [];
    }
  }

  Future<List<Customer>> getFamilyMembers(String customerId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('tenant_id', tenantId)
          .or('id.eq.$customerId,family_id.eq.$customerId')
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
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('tenant_id', tenantId)
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

  Future<Customer?> getCustomerByBillNumberAndDetail(String billNumber, String phone, String name) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('bill_number', billNumber)
          .eq('phone', phone)
          .eq('name', name)
          .eq('tenant_id', tenantId)
          .maybeSingle();
      return response != null ? Customer.fromMap(response) : null;
    } catch (e) {
      debugPrint('Error in getCustomerByBillNumberAndDetail: $e');
      return null;
    }
  }

  Future<void> updateCustomerByBillNumber(String billNumber, Map<String, dynamic> data) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    await _client
        .from('customers')
        .update(data)
        .eq('bill_number', billNumber)
        .eq('tenant_id', tenantId);
  }

  Future<void> addCustomerWithoutId(Map<String, dynamic> data) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    // Check if bill number is unique
    final billNumber = data['bill_number'];
    if (billNumber != null) {
      final isUnique = await isBillNumberUnique(billNumber);
      if (!isUnique) {
        throw Exception('Bill number already exists for this tenant. Please use a different bill number.');
      }
    }
    
    // Ensure that 'id' is not provided so Supabase generates it
    final dataToInsert = Map<String, dynamic>.from(data)..remove('id');
    dataToInsert['tenant_id'] = tenantId;
    await _client.from('customers').insert(dataToInsert);
  }

  // Add this new method
  Future<Customer?> getCustomerByBillNumber(String billNumber) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('bill_number', billNumber)
          .eq('tenant_id', tenantId)
          .maybeSingle();
      return response != null ? Customer.fromMap(response) : null;
    } catch (e) {
      debugPrint('Error in getCustomerByBillNumber: $e');
      return null;
    }
  }
}

class CustomerService {
  final SupabaseClient _supabase;

  CustomerService(this._supabase);

  Future<Customer> getCustomerByBillNumber(String billNumber) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final response = await _supabase
        .from('customers')
        .select()
        .eq('bill_number', billNumber)
        .eq('tenant_id', tenantId)
        .single();

    return Customer.fromMap(response);
  }

  Future<List<Customer>> getReferrals(String customerId) async {
    try {
      final response = await _supabase
          .from('customers')
          .select()
          .eq('referred_by', customerId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => Customer.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching referrals: $e');
      return [];
    }
  }

  Future<List<Customer>> getFamilyMembers(String familyId) async {
    try {
      final response = await _supabase
          .from('customers')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => Customer.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching family members: $e');
      return [];
    }
  }

  Future<List<Customer>> searchCustomers(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return [];

    final String tenantId = TenantManager.getCurrentTenantId();
    final query = searchTerm.trim().toLowerCase();
    
    try {
      final response = await _supabase
          .from('customers')
          .select()
          .eq('tenant_id', tenantId)
          .or('name.ilike.%$query%,bill_number.ilike.%$query%')
          .order('name')
          .limit(20);
      
      // ignore: unnecessary_null_comparison
      if (response == null) return [];
      
      return (response as List)
          .map((data) => Customer.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error searching customers: $e');
      return [];
    }
  }
}