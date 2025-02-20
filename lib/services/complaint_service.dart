import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint.dart';

class ComplaintService {
  final SupabaseClient _supabase;
  
  ComplaintService(this._supabase);

  // Create a new complaint
  Future<Complaint> createComplaint(Complaint complaint) async {
    // Validate required fields
    if (complaint.customerId.isEmpty) {
      throw Exception('Customer ID is required');
    }
    
    if (complaint.assignedTo.isEmpty) {
      throw Exception('Assigned To is required');
    }

    final complaintMap = complaint.toMap();
    
    // Ensure updates and attachments are initialized as empty arrays if null
    complaintMap['updates'] = complaintMap['updates'] ?? [];
    complaintMap['attachments'] = complaintMap['attachments'] ?? [];

    final response = await _supabase
        .from('complaints')
        .insert(complaintMap)
        .select()
        .single();
    
    return Complaint.fromMap(response);
  }

  // Get all complaints
  Future<List<Complaint>> getAllComplaints({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  // Get complaints by customer
  Future<List<Complaint>> getCustomerComplaints(String customerId) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  // Get complaints by status
  Future<List<Complaint>> getComplaintsByStatus(ComplaintStatus status) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('status', status.toString())
        .order('created_at', ascending: false);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  // Update complaint status
  Future<void> updateComplaintStatus(
    String complaintId,
    ComplaintStatus status,
  ) async {
    await _supabase
        .from('complaints')
        .update({'status': status.toString()})
        .eq('id', complaintId);
  }

  // Add update to complaint
  Future<void> addComplaintUpdate(
    String complaintId,
    ComplaintUpdate update,
  ) async {
    final complaintData = await _supabase
        .from('complaints')
        .select('updates')
        .eq('id', complaintId)
        .single();

    List<dynamic> updates = [...complaintData['updates'], update.toMap()];

    await _supabase
        .from('complaints')
        .update({'updates': updates})
        .eq('id', complaintId);
  }

  // Search complaints
  Future<List<Complaint>> searchComplaints(String query) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('created_at', ascending: false);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  // Get complaint statistics
  Future<Map<String, int>> getComplaintStatistics() async {
    final response = await _supabase
        .from('complaints')
        .select('status');

    final Map<String, int> stats = {};
    for (ComplaintStatus status in ComplaintStatus.values) {
      stats[status.toString()] = response
          .where((complaint) => complaint['status'] == status.toString())
          .length;
    }
    
    return stats;
  }

  // Add attachment to complaint
  Future<void> addAttachment(String complaintId, String attachmentUrl) async {
    final complaintData = await _supabase
        .from('complaints')
        .select('attachments')
        .eq('id', complaintId)
        .single();

    List<String> attachments = [...List<String>.from(complaintData['attachments']), attachmentUrl];

    await _supabase
        .from('complaints')
        .update({'attachments': attachments})
        .eq('id', complaintId);
  }

  // Delete attachment from complaint
  Future<void> removeAttachment(String complaintId, String attachmentUrl) async {
    final complaintData = await _supabase
        .from('complaints')
        .select('attachments')
        .eq('id', complaintId)
        .single();

    List<String> attachments = List<String>.from(complaintData['attachments'])
      ..remove(attachmentUrl);

    await _supabase
        .from('complaints')
        .update({'attachments': attachments})
        .eq('id', complaintId);
  }

  // Get complaint by ID
  Future<Complaint> getComplaintById(String id) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('id', id)
        .single();

    return Complaint.fromMap(response);
  }

  // Get urgent complaints
  Future<List<Complaint>> getUrgentComplaints() async {
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('priority', ComplaintPriority.urgent.toString())
        .eq('status', ComplaintStatus.pending.toString())
        .order('created_at', ascending: false);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  // Get complaints assigned to specific user
  Future<List<Complaint>> getAssignedComplaints(String userId) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('assigned_to', userId)
        .order('created_at', ascending: false);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }
}
