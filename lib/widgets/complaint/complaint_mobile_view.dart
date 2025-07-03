import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/complaint_filter.dart';
import '../../models/new_complaint_model.dart';
import '../../services/new_complaint_service.dart';
import '../../theme/inventory_design_config.dart';
import 'new_complaint_dialog.dart';

class ComplaintMobileView extends StatefulWidget {
  const ComplaintMobileView({super.key});

  @override
  State<ComplaintMobileView> createState() => _ComplaintMobileViewState();
}

class _ComplaintMobileViewState extends State<ComplaintMobileView> {
  final _supabase = Supabase.instance.client;
  late final NewComplaintService _complaintService;
  bool _isLoading = true;
  List<NewComplaint> _complaints = [];
  ComplaintFilter _filter = ComplaintFilter();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _complaintService = NewComplaintService(_supabase);
    _loadComplaints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      // Simplified query for mobile, can be expanded with filters
      final response = await _supabase
          .from('new_complaints')
          .select('*, customers(name), invoices(invoice_number)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _complaints = (response as List)
              .map((item) => NewComplaint.fromJson(item))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading complaints: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InventoryDesignConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Complaints'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.funnel()),
            onPressed: () {
              // TODO: Implement mobile filter sheet
            },
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent() {
    if (_complaints.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: () => _loadComplaints(showLoading: false),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _complaints.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final complaint = _complaints[index];
          return _buildComplaintCard(complaint);
        },
      ),
    );
  }

  Widget _buildComplaintCard(NewComplaint complaint) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          NewComplaintDialog.show(
            context,
            customerId: complaint.customerId,
            customerName: complaint.customerName ?? 'N/A',
            complaint: complaint,
            onComplaintUpdated: _loadComplaints,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(complaint.status.displayName, complaint.status.color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Customer: ${complaint.customerName ?? 'N/A'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Reported: ${DateFormat.yMMMd().format(complaint.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(complaint.priority.displayName, complaint.priority.color),
                  if (complaint.invoiceNumber != null)
                    Text(
                      'Invoice #${complaint.invoiceNumber}',
                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                    )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.fileMagnifyingGlass(), size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No Complaints Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('This view is clean... for now.', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
