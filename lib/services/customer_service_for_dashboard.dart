import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

class CustomerService {
  final SupabaseClient _supabase;
  
  CustomerService(this._supabase);

  Future<List<Customer>> getAllCustomers() async {
    final response = await _supabase
        .from('customers')
        .select()
        .order('name');
    
    return response.map((json) => Customer.fromMap(json)).toList();
  }

  Future<Customer> getCustomerById(String id) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('id', id)
        .single();
    
    return Customer.fromMap(response);
  }
}
