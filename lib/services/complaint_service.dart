import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint.dart';
import '../services/invoice_service.dart';

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

  // Remove update from complaint
  Future<void> removeComplaintUpdate(String complaintId, String updateId) async {
    final complaintData = await _supabase
        .from('complaints')
        .select('updates')
        .eq('id', complaintId)
        .single();

    List<dynamic> updates = List<dynamic>.from(complaintData['updates'])
      ..removeWhere((update) => update['id'] == updateId);

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

  Future<Map<String, dynamic>> getComplaintDetails(String complaintId) async {
    final response = await _supabase
        .from('complaints')
        .select('''
          *,
          customers!customer_id (
            name
          ),
          invoices!invoice_id (
            invoice_number
          )
        ''')
        .eq('id', complaintId)
        .single();
    
    return {
      'customerName': response['customers']['name'],
      'invoiceNumber': response['invoices']?['invoice_number'],
    };
  }

  Future<void> updateComplaintPriority(
    String complaintId,
    ComplaintPriority priority,
  ) async {
    await _supabase
        .from('complaints')
        .update({'priority': priority.toString()})
        .eq('id', complaintId);
  }

  Future<void> reassignComplaint(String complaintId, String assignedTo) async {
    await _supabase
        .from('complaints')
        .update({
          'assigned_to': assignedTo,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', complaintId);
  }

  Future<void> requestRefund(
    String complaintId, 
    double amount, 
    String reason,
    String invoiceId,
  ) async {
    await _supabase.from('complaints').update({
      'refund_status': RefundStatus.pending.toString(),
      'refund_amount': amount,
      'refund_requested_at': DateTime.now().toIso8601String(),
      'refund_reason': reason,
    }).eq('id', complaintId);
  }

  Future<void> processRefund(
    String complaintId, 
    RefundStatus status,
    String invoiceId,
  ) async {
    // Get invoice service instance
    final invoiceService = InvoiceService();
    
    try {
      if (status == RefundStatus.approved) {
        // First get the complaint details
        final complaint = await getComplaintById(complaintId);
        
        if (complaint.refundAmount == null || complaint.refundReason == null) {
          throw Exception('Invalid refund request');
        }

        // Process refund in invoice first
        await invoiceService.processRefund(
          invoiceId,
          complaint.refundAmount!,
          complaint.refundReason!,
        );

        // Update complaint status
        await _supabase.from('complaints').update({
          'refund_status': RefundStatus.completed.toString(),
          'refund_completed_at': DateTime.now().toIso8601String(),
        }).eq('id', complaintId);
      } else {
        // Just update the status if rejected
        await _supabase.from('complaints').update({
          'refund_status': status.toString(),
        }).eq('id', complaintId);
      }
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  Stream<List<Complaint>> getComplaintsStream() {
    return _supabase
        .from('complaints')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data.map((json) => Complaint.fromMap(json)).toList());
  }
}
