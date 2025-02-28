import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import '../utils/tenant_manager.dart';

class CustomerService {
  final SupabaseClient _supabase;
  
  CustomerService(this._supabase);

  Future<List<Customer>> getAllCustomers() async {
    final String tenantId = TenantManager.getCurrentTenantId();
    final response = await _supabase
        .from('customers')
        .select()
        .eq('tenant_id', tenantId)
        .order('name');
    
    return response.map((json) => Customer.fromMap(json)).toList();
  }

  Future<Customer> getCustomerById(String id) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    final response = await _supabase
        .from('customers')
        .select()
        .eq('id', id)
        .eq('tenant_id', tenantId)
        .single();
    
    return Customer.fromMap(response);
  }
}
