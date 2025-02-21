import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../widgets/complaint/complaint_card.dart';
import '../widgets/complaint/complaint_dialog.dart';
import '../widgets/complaint/complaint_detail_dialog.dart';
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
  ComplaintPriority? _filterPriority;
  DateTimeRange? _dateRange;
  String? _assigneeFilter;
  bool _showResolved = true;

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
        // Remove the layout toggle from app bar since it's not needed anymore
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 12.0, // Added top padding
        bottom: 8.0, // Adjusted bottom padding
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(  // Wrapped TextField in Container for shadow
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: isDesktop 
                      ? 'Search complaints by title, customer, or bill #'
                      : 'Search complaints...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showFilterDialog(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: _hasActiveFilters() 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          if (_hasActiveFilters())
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Filters',
                          style: TextStyle(
                            color: _hasActiveFilters() 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper method to check for active filters
  bool _hasActiveFilters() {
    return _filterStatus != null ||
           _filterPriority != null ||
           _dateRange != null ||
           _assigneeFilter != null ||
           !_showResolved;
  }

  void _showFilterDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset All'),
                  ),
                ],
              ),
            ),
            // Quick Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _QuickFilterChip(
                    label: 'Today',
                    icon: Icons.today,
                    onTap: () => _setQuickDateRange(0),
                    isSelected: _isToday(),
                  ),
                  _QuickFilterChip(
                    label: 'This Week',
                    icon: Icons.calendar_view_week,
                    onTap: () => _setQuickDateRange(7),
                    isSelected: _isThisWeek(),
                  ),
                  _QuickFilterChip(
                    label: 'Unresolved',
                    icon: Icons.pending_actions,
                    onTap: () => setState(() => _showResolved = !_showResolved),
                    isSelected: !_showResolved,
                  ),
                  _QuickFilterChip(
                    label: 'My Complaints',
                    icon: Icons.person_outline,
                    onTap: () => _toggleAssigneeFilter(),
                    isSelected: _assigneeFilter != null,
                  ),
                ],
              ),
            ),
            // Filter Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Status Section
                  _buildFilterSection(
                    theme,
                    'Status',
                    Icons.flag_circle_outlined,
                    theme.colorScheme.primary,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ComplaintStatus.values.map((status) {
                        return _FilterChip(
                          label: status.toString().split('.').last,
                          icon: _getStatusIcon(status),
                          selected: _filterStatus == status,
                          onSelected: (selected) => setState(() {
                            _filterStatus = selected ? status : null;
                          }),
                          color: _getStatusColor(status, theme),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Priority Section
                  _buildFilterSection(
                    theme,
                    'Priority',
                    Icons.priority_high_outlined,
                    theme.colorScheme.secondary,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ComplaintPriority.values.map((priority) {
                        return _FilterChip(
                          label: priority.toString().split('.').last,
                          selected: _filterPriority == priority,
                          onSelected: (selected) => setState(() {
                            _filterPriority = selected ? priority : null;
                          }),
                          color: _getPriorityColor(priority),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Date Range Section
                  _buildFilterSection(
                    theme,
                    'Date Range',
                    Icons.calendar_today_outlined,
                    theme.colorScheme.tertiary,
                    child: Row(
                      children: [
                        Expanded(
                          child: _DateButton(
                            label: 'From',
                            date: _dateRange?.start,
                            onTap: () => _selectDate(true),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward, size: 20),
                        ),
                        Expanded(
                          child: _DateButton(
                            label: 'To',
                            date: _dateRange?.end,
                            onTap: () => _selectDate(false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Apply Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add these new helper methods
  void _resetFilters() {
    setState(() {
      _filterStatus = null;
      _filterPriority = null;
      _dateRange = null;
      _assigneeFilter = null;
      _showResolved = true;
    });
  }

  void _setQuickDateRange(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    setState(() => _dateRange = DateTimeRange(start: start, end: end));
  }

  bool _isToday() {
    if (_dateRange == null) return false;
    final now = DateTime.now();
    return _dateRange!.start.year == now.year &&
           _dateRange!.start.month == now.month &&
           _dateRange!.start.day == now.day;
  }

  bool _isThisWeek() {
    if (_dateRange == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _dateRange!.start.isAtSameMomentAs(weekStart);
  }

  void _toggleAssigneeFilter() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    setState(() {
      _assigneeFilter = _assigneeFilter == null ? currentUser?.id : null;
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = _dateRange?.start ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _dateRange = DateTimeRange(
            start: date,
            end: _dateRange?.end ?? date.add(const Duration(days: 7)),
          );
        } else {
          _dateRange = DateTimeRange(
            start: _dateRange?.start ?? date.subtract(const Duration(days: 7)),
            end: date,
          );
        }
      });
    }
  }

  void _applyFilters() {
    // Update complaints list based on filters
    setState(() {});
  }

  Widget _buildFilterSection(
    ThemeData theme,
    String title,
    IconData icon,
    Color color, {
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
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

  Color _getPriorityColor(ComplaintPriority priority) {
    switch (priority) {
      case ComplaintPriority.low:
        return Colors.green;
      case ComplaintPriority.medium:
        return Colors.orange;
      case ComplaintPriority.high:
        return Colors.red;
      case ComplaintPriority.urgent:
        return Colors.purple;
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
        if (_filterPriority != null) {
          complaints.removeWhere((c) => c.priority != _filterPriority);
        }
        if (_dateRange != null) {
          complaints.removeWhere((c) => 
            !c.createdAt.isAfter(_dateRange!.start) || 
            !c.createdAt.isBefore(_dateRange!.end));
        }
        if (_assigneeFilter != null) {
          complaints.removeWhere((c) => c.assignedTo != _assigneeFilter);
        }
        if (!_showResolved) {
          complaints.removeWhere((c) => c.status == ComplaintStatus.resolved);
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

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        selectedColor: theme.colorScheme.primaryContainer,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: selected ? theme.colorScheme.onSecondaryContainer : chipColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
      onPressed: () => onSelected(!selected),
      backgroundColor: selected ? chipColor.withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest,
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? DateFormat('MMM dd, yyyy').format(date!)
                  : 'Select Date',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: date != null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
