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
  final ComplaintService _complaintService = ComplaintService(
    Supabase.instance.client,
  );
  bool _isGridView = true; // Changed to true for default grid view
  String _searchQuery = '';
  ComplaintStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complaints',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: !isDesktop,
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatistics(theme),
                  // Make complaints list scrollable within available space
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 300,
                    ),
                    child: _buildComplaintsList(theme),
                  ),
                ],
              ),
            ),
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
            items:
                ComplaintStatus.values.map((status) {
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return FutureBuilder<Map<String, int>>(
      future: _complaintService.getComplaintStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data!;
        final totalComplaints = stats.values.fold(
          0,
          (sum, count) => sum + count,
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: isMobile ? 12 : 16,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: isMobile ? size.width / 3 - 24 : 220,
                  child: _buildTotalCard(theme, totalComplaints),
                ),
                ...ComplaintStatus.values.map((status) {
                  return Container(
                    width: isMobile ? size.width / 3 - 24 : 200,
                    margin: EdgeInsets.only(left: isMobile ? 12 : 16),
                    child: _buildStatusCard(
                      theme,
                      status,
                      stats[status.toString()] ?? 0,
                      totalComplaints,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalCard(ThemeData theme, int total) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.primary,
                    size: isMobile ? 16 : 20,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 16 : 20,
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                total.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                fontSize: isMobile ? 12 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    ComplaintStatus status,
    int count,
    int total,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    final color = _getStatusColor(status, theme);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: color,
                    size: isMobile ? 16 : 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percentage%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 10 : 11,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                count.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status.toString().split('.').last,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isMobile ? 12 : null,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: total > 0 ? count / total : 0,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: isMobile ? 3 : 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ComplaintStatus status, ThemeData theme) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return theme.colorScheme.primary;
      case ComplaintStatus.resolved:
        return theme.colorScheme.tertiary;
      case ComplaintStatus.closed:
        return theme.colorScheme.outline;
      case ComplaintStatus.rejected:
        return theme.colorScheme.error;
    }
  }

  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Icons.pending_outlined;
      case ComplaintStatus.inProgress:
        return Icons.running_with_errors_outlined;
      case ComplaintStatus.resolved:
        return Icons.check_circle_outline;
      case ComplaintStatus.closed:
        return Icons.task_alt;
      case ComplaintStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  Widget _buildComplaintsList(ThemeData theme) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1200;
    final isMobile = size.width < 600;
    final itemWidth =
        isDesktop ? size.width / 4 : (isMobile ? size.width : size.width / 3);

    return FutureBuilder<List<Complaint>>(
      future:
          _searchQuery.isEmpty
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
            shrinkWrap: true, // Add this
            physics: const NeverScrollableScrollPhysics(), // Add this
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : (isMobile ? 1 : 3),
              childAspectRatio:
                  isMobile
                      ? (size.width / 140) // More compact for mobile
                      : (itemWidth / (itemWidth * 0.7)), // Desktop ratio
              crossAxisSpacing: isMobile ? 8 : 12,
              mainAxisSpacing: isMobile ? 8 : 12,
            ),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              return ComplaintCard(
                complaint: complaints[index],
                onTap: () => _showComplaintDetails(complaints[index]),
                isGridView: true,
              );
            },
          );
        }

        return ListView.separated(
          shrinkWrap: true, // Add this
          physics: const NeverScrollableScrollPhysics(), // Add this
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return ComplaintCard(
              complaint: complaints[index],
              onTap: () => _showComplaintDetails(complaints[index]),
              isGridView: false,
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
