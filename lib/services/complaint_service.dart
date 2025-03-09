import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint.dart';
import '../utils/tenant_manager.dart';
import '../services/invoice_service.dart';

class ComplaintService {
  final SupabaseClient _supabase;

  ComplaintService(this._supabase);

  // Create a new complaint
  Future<Complaint> createComplaint(Complaint complaint) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
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
    complaintMap['tenant_id'] = tenantId;

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
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  // Get complaints by customer
  Future<List<Complaint>> getCustomerComplaints(String customerId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('customer_id', customerId)
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  // Get complaints by status
  Future<List<Complaint>> getComplaintsByStatus(ComplaintStatus status) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('status', status.toString())
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  // Update complaint status
  Future<void> updateComplaintStatus(
    String complaintId,
    ComplaintStatus status,
  ) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    await _supabase
        .from('complaints')
        .update({'status': status.toString()})
        .eq('id', complaintId)
        .eq('tenant_id', tenantId);
  }

  // Add update to complaint
  Future<void> addComplaintUpdate(
    String complaintId,
    ComplaintUpdate update,
  ) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final complaintData = await _supabase
        .from('complaints')
        .select('updates')
        .eq('id', complaintId)
        .eq('tenant_id', tenantId)
        .single();

    List<dynamic> updates = [...complaintData['updates'], update.toMap()];

    await _supabase
        .from('complaints')
        .update({'updates': updates})
        .eq('id', complaintId)
        .eq('tenant_id', tenantId);
    
    // Also add to complaint_updates table for better querying
    await _supabase.from('complaint_updates').insert({
      'id': update.id,
      'complaint_id': complaintId,
      'comment': update.comment,
      'timestamp': update.timestamp.toIso8601String(),
      'updated_by': update.updatedBy,
      'tenant_id': tenantId,
    });
  }

  // Remove update from complaint
  Future<void> removeComplaintUpdate(String complaintId, String updateId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final complaintData = await _supabase
        .from('complaints')
        .select('updates')
        .eq('id', complaintId)
        .eq('tenant_id', tenantId)
        .single();

    List<dynamic> updates = List<dynamic>.from(complaintData['updates'])
      ..removeWhere((update) => update['id'] == updateId);

    await _supabase
        .from('complaints')
        .update({'updates': updates})
        .eq('id', complaintId)
        .eq('tenant_id', tenantId);
    
    // Also remove from complaint_updates
    await _supabase
        .from('complaint_updates')
        .delete()
        .eq('id', updateId)
        .eq('tenant_id', tenantId);
  }

  // Search complaints
  Future<List<Complaint>> searchComplaints(String query) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('tenant_id', tenantId)
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('created_at', ascending: false);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  // Get complaint statistics
  Future<Map<String, int>> getComplaintStatistics() async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final response = await _supabase
        .from('complaints')
        .select('status')
        .eq('tenant_id', tenantId);

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
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final complaintData = await _supabase
        .from('complaints')
        .select('attachments')
        .eq('id', complaintId)
        .eq('tenant_id', tenantId)
        .single();

    List<String> attachments = [...List<String>.from(complaintData['attachments']), attachmentUrl];

    await _supabase
        .from('complaints')
        .update({'attachments': attachments})
        .eq('id', complaintId)
        .eq('tenant_id', tenantId);
  }

  // Delete attachment from complaint
  Future<void> removeAttachment(String complaintId, String attachmentUrl) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final complaintData = await _supabase
        .from('complaints')
        .select('attachments')
        .eq('id', complaintId)
        .eq('tenant_id', tenantId)
        .single();

    List<String> attachments = List<String>.from(complaintData['attachments'])
      ..remove(attachmentUrl);

    await _supabase
        .from('complaints')
        .update({'attachments': attachments})
        .eq('id', complaintId)
        .eq('tenant_id', tenantId);
  }

  // Get complaint by ID
  Future<Complaint> getComplaintById(String id) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('id', id)
        .eq('tenant_id', tenantId)
        .single();

    return Complaint.fromMap(response);
  }

  // Get urgent complaints
  Future<List<Complaint>> getUrgentComplaints() async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('priority', ComplaintPriority.urgent.toString())
        .eq('status', ComplaintStatus.pending.toString())
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  // Get complaints assigned to specific user
  Future<List<Complaint>> getAssignedComplaints(String userId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('assigned_to', userId)
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }

  Future<Map<String, dynamic>> getComplaintDetails(String complaintId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
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
        .eq('tenant_id', tenantId)
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
    final String tenantId = TenantManager.getCurrentTenantId();
    
    await _supabase
        .from('complaints')
        .update({'priority': priority.toString()})
        .eq('id', complaintId)
        .eq('tenant_id', tenantId);
  }

  Future<void> reassignComplaint(String complaintId, String assignedTo) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    await _supabase
        .from('complaints')
        .update({
          'assigned_to': assignedTo,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', complaintId)
        .eq('tenant_id', tenantId);
  }

  Future<void> requestRefund(
    String complaintId, 
    double amount, 
    String reason,
    String invoiceId,
  ) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    await _supabase.from('complaints').update({
      'refund_status': RefundStatus.pending.toString(),
      'refund_amount': amount,
      'refund_requested_at': DateTime.now().toIso8601String(),
      'refund_reason': reason,
    })
    .eq('id', complaintId)
    .eq('tenant_id', tenantId);
  }

  Future<void> processRefund(
    String complaintId, 
    RefundStatus status,
    String invoiceId,
  ) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
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
        })
        .eq('id', complaintId)
        .eq('tenant_id', tenantId);
      } else {
        // Just update the status if rejected
        await _supabase.from('complaints').update({
          'refund_status': status.toString(),
        })
        .eq('id', complaintId)
        .eq('tenant_id', tenantId);
      }
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  Stream<List<Complaint>> getComplaintsStream() {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    return _supabase
        .from('complaints')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('created_at')
        .map((data) => data.map((json) => Complaint.fromMap(json)).toList());
  }

  Future<List<Complaint>> getComplaintsByCustomerId(String customerId) async {
    final String tenantId = TenantManager.getCurrentTenantId();
    
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('customer_id', customerId)
        .eq('tenant_id', tenantId);

    return response.map((data) => Complaint.fromMap(data)).toList();
  }
}
