import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/new_complaint_model.dart';

class NewComplaintService {
  final SupabaseClient _supabase;

  NewComplaintService(this._supabase);

  // Fetch all complaints for a specific customer
  Future<List<NewComplaint>> getComplaintsByCustomerId(String customerId) async {
    try {
      final response = await _supabase
          .from('new_complaints')
          .select('*, customers(name), invoices(invoice_number)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => NewComplaint.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching complaints: $e');
      return [];
    }
  }

  // Add a new complaint
  Future<void> addComplaint(NewComplaint complaint) async {
    try {
      await _supabase.from('new_complaints').insert(complaint.toJson());
    } catch (e) {
      print('Error adding complaint: $e');
      rethrow;
    }
  }

  // Update an existing complaint
  Future<void> updateComplaint(NewComplaint complaint) async {
    try {
      await _supabase
          .from('new_complaints')
          .update(complaint.toJson())
          .eq('id', complaint.id);
    } catch (e) {
      print('Error updating complaint: $e');
      rethrow;
    }
  }
  
  // Delete a complaint (soft delete can be implemented via RLS or a flag)
  Future<void> deleteComplaint(String id) async {
    try {
      await _supabase.from('new_complaints').delete().eq('id', id);
    } catch (e) {
      print('Error deleting complaint: $e');
      rethrow;
    }
  }

  // Fetch all invoices for a customer to link to a complaint
  Future<List<Map<String, dynamic>>> getInvoicesForCustomer(String customerId) async {
    try {
      final response = await _supabase
          .from('invoices')
          .select('id, invoice_number, date')
          .eq('customer_id', customerId)
          .order('date', ascending: false);

      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching invoices for customer: $e');
      return [];
    }
  }
}
