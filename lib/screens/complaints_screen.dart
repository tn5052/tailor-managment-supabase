import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../widgets/complaint_card.dart';
import '../widgets/complaint_dialog.dart';
import '../widgets/complaint_detail_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final ComplaintService _complaintService = ComplaintService(Supabase.instance.client);
  bool _isGridView = false;
  String _searchQuery = '';
  ComplaintStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints Management'),
        actions: [
          IconButton(
            icon: PhosphorIcon(
              _isGridView ? PhosphorIcons.list() : PhosphorIcons.gridFour(),
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(theme),
          _buildStatistics(theme),
          Expanded(
            child: _buildComplaintsList(theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddComplaintDialog,
        icon: PhosphorIcon(PhosphorIcons.plus()),
        label: const Text('New Complaint'),
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search complaints...',
                prefixIcon: PhosphorIcon(PhosphorIcons.magnifyingGlass()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<ComplaintStatus>(
            value: _filterStatus,
            hint: const Text('Status'),
            items: ComplaintStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.toString().split('.').last),
              );
            }).toList(),
            onChanged: (value) => setState(() => _filterStatus = value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(ThemeData theme) {
    return FutureBuilder<Map<String, int>>(
      future: _complaintService.getComplaintStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final stats = snapshot.data!;
        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: stats.entries.map((entry) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        entry.value.toString(),
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        entry.key.split('.').last,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildComplaintsList(ThemeData theme) {
    return FutureBuilder<List<Complaint>>(
      future: _searchQuery.isEmpty
          ? _complaintService.getAllComplaints()
          : _complaintService.searchComplaints(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No complaints found',
              style: theme.textTheme.titleMedium,
            ),
          );
        }

        final complaints = snapshot.data!;
        if (_filterStatus != null) {
          complaints.removeWhere((c) => c.status != _filterStatus);
        }

        if (_isGridView) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              return ComplaintCard(
                complaint: complaints[index],
                onTap: () => _showComplaintDetails(complaints[index]),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ComplaintCard(
                complaint: complaints[index],
                onTap: () => _showComplaintDetails(complaints[index]),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddComplaintDialog() {
    showDialog(
      context: context,
      builder: (context) => const ComplaintDialog(),
    ).then((value) {
      if (value == true) setState(() {});
    });
  }

  void _showComplaintDetails(Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => ComplaintDetailDialog(complaint: complaint),
    ).then((value) {
      if (value == true) setState(() {});
    });
  }
}
