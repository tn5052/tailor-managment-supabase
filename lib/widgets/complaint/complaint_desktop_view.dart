import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/complaint_filter.dart';
import '../../models/new_complaint_model.dart';
import '../../services/new_complaint_service.dart';
import '../../theme/inventory_design_config.dart';
import 'desktop/complaint_filters_dialog.dart';
import 'desktop/complaint_detail_dialog_desktop.dart';
import 'desktop/customer_selector_for_complaint_dialog.dart';
import 'new_complaint_dialog.dart';

class ComplaintDesktopView extends StatefulWidget {
  const ComplaintDesktopView({super.key});

  @override
  State<ComplaintDesktopView> createState() => _ComplaintDesktopViewState();
}

class _ComplaintDesktopViewState extends State<ComplaintDesktopView> {
  final _supabase = Supabase.instance.client;
  late final NewComplaintService _complaintService;
  String _sortColumn = 'created_at';
  bool _sortAscending = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<NewComplaint> _complaints = [];
  ComplaintFilter _filter = ComplaintFilter();

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

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('new_complaints')
          .select('*, customers(name), invoices(invoice_number)');

      if (_searchQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%$_searchQuery%,description.ilike.%$_searchQuery%,customers.name.ilike.%$_searchQuery%',
        );
      }

      if (_filter.statuses.isNotEmpty) {
        query = query.filter('status', 'in', _filter.statuses.map((e) => e.name).toList());
      }
      if (_filter.priorities.isNotEmpty) {
        query = query.filter('priority', 'in', _filter.priorities.map((e) => e.name).toList());
      }
      if (_filter.startDate != null) {
        query = query.gte('created_at', _filter.startDate!.toIso8601String());
      }
      if (_filter.endDate != null) {
        query = query.lte('created_at', _filter.endDate!.toIso8601String());
      }

      final response = await query.order(_sortColumn, ascending: _sortAscending);

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

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
    _loadComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.backgroundColor,
      ),
      child: Column(
        children: [
          // Compact header section with title and controls
          Container(
            decoration: const BoxDecoration(
              color: InventoryDesignConfig.backgroundColor,
            ),
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
            child: Column(
              children: [
                // Main header row - compact design
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: InventoryDesignConfig.warningColor
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            PhosphorIcons.warning(),
                            size: 22,
                            color: InventoryDesignConfig.warningColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complaint Management',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: InventoryDesignConfig.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Track and resolve customer issues',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: InventoryDesignConfig.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Right side controls - in a single row
                    Row(
                      children: [
                        _buildSearchField(),
                        const SizedBox(width: 12),
                        _buildFilterButton(),
                        const SizedBox(width: 12),
                        _buildModernPrimaryButton(
                          icon: PhosphorIcons.plus(),
                          label: 'Add Complaint',
                          onPressed: _addComplaint,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats row - more compact
                _buildModernStatsRow(),
              ],
            ),
          ),

          // Table container with matching background
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: InventoryDesignConfig.backgroundColor,
              ),
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Container(
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceColor,
                  border: Border.all(
                    color: InventoryDesignConfig.borderPrimary,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    _isLoading ? _buildLoadingState() : _buildComplaintsTable(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchField() {
    return Container(
      width: 280,
      height: 40, // Match button height
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: InventoryDesignConfig.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search complaints...',
          hintStyle: GoogleFonts.inter(
            color: InventoryDesignConfig.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              PhosphorIcons.magnifyingGlass(),
              size: 16,
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      PhosphorIcons.x(),
                      size: 14,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadComplaints();
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _loadComplaints();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: InventoryDesignConfig.primaryAccent));
  }

  Widget _buildComplaintsTable() {
    if (_complaints.isEmpty) {
      return _buildEmptyState();
    }

    final columns = [
      _buildDataColumn('Customer', 'customer_id'),
      _buildDataColumn('Title', 'title'),
      _buildDataColumn('Status', 'status'),
      _buildDataColumn('Priority', 'priority'),
      _buildDataColumn('Invoice', 'invoice_id'),
      _buildDataColumn('Date', 'created_at'),
      const DataColumn(label: Text('')),
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(InventoryDesignConfig.surfaceAccent),
          dataRowColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.hovered)) {
              return InventoryDesignConfig.surfaceLight;
            }
            return InventoryDesignConfig.surfaceColor;
          }),
          headingTextStyle: InventoryDesignConfig.labelLarge,
          dataTextStyle: InventoryDesignConfig.bodyLarge,
        ),
      ),
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            columnSpacing: InventoryDesignConfig.spacingXXXL,
            horizontalMargin: InventoryDesignConfig.spacingXXL,
            headingRowHeight: 52,
            dataRowMaxHeight: 60,
            showCheckboxColumn: false,
            dividerThickness: 1,
            border: TableBorder(horizontalInside: BorderSide(color: InventoryDesignConfig.borderSecondary)),
            columns: columns,
            rows: _complaints.map((complaint) => _buildComplaintRow(complaint)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatsRow() {
    final totalComplaints = _complaints.length;
    final pendingComplaints = _complaints.where((c) => c.status == ComplaintStatus.pending).length;
    final highPriority = _complaints.where((c) => c.priority == ComplaintPriority.high).length;

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Row(
        children: [
          _buildModernStatCard(
            title: 'Total Complaints',
            value: totalComplaints.toString(),
            icon: PhosphorIcons.warningCircle(),
            color: InventoryDesignConfig.primaryAccent,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Pending',
            value: pendingComplaints.toString(),
            icon: PhosphorIcons.clock(),
            color: InventoryDesignConfig.infoColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'High Priority',
            value: highPriority.toString(),
            icon: PhosphorIcons.fire(),
            color: InventoryDesignConfig.errorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: InventoryDesignConfig.headlineMedium),
            Text(title, style: InventoryDesignConfig.bodySmall),
          ],
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            ),
            child: Icon(PhosphorIcons.warning(), size: 48, color: InventoryDesignConfig.textTertiary),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          Text('No complaints found', style: InventoryDesignConfig.headlineMedium),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            'No customer complaints have been registered yet.',
            style: InventoryDesignConfig.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildModernPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          height: 40, // Match other elements height
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: InventoryDesignConfig.buttonPrimaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Badge(
      isLabelVisible: _filter.isActive,
      child: OutlinedButton.icon(
        onPressed: _openFilterDialog,
        icon: Icon(PhosphorIcons.funnel(), size: 16),
        label: const Text('Filter'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _openFilterDialog() async {
    final result = await ComplaintFiltersDialog.show(
      context,
      initialFilter: _filter,
    );
    if (result != null) {
      setState(() {
        _filter = result;
      });
      _loadComplaints();
    }
  }

  DataColumn _buildDataColumn(String label, String column) {
    final isSorted = _sortColumn == column;
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase()),
          if (isSorted) ...[
            const SizedBox(width: InventoryDesignConfig.spacingXS),
            Icon(
              _sortAscending ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(),
              size: 12,
              color: InventoryDesignConfig.primaryAccent,
            ),
          ],
        ],
      ),
      onSort: (_, __) => _onSort(column),
    );
  }

  DataRow _buildComplaintRow(NewComplaint complaint) {
    return DataRow(
      cells: [
        DataCell(Text(complaint.customerName ?? 'N/A', style: InventoryDesignConfig.titleMedium)),
        DataCell(Text(complaint.title, maxLines: 2, overflow: TextOverflow.ellipsis)),
        DataCell(_buildStatusChip(complaint.status.displayName, complaint.status.color)),
        DataCell(_buildStatusChip(complaint.priority.displayName, complaint.priority.color)),
        DataCell(Text(complaint.invoiceNumber != null ? '#${complaint.invoiceNumber}' : 'N/A')),
        DataCell(Text(DateFormat.yMMMd().format(complaint.createdAt))),
        DataCell(_buildActionsCell(complaint)),
      ],
      onSelectChanged: (selected) {
        if (selected == true) {
          _handleViewItem(complaint);
        }
      },
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      ),
      child: Text(
        label,
        style: InventoryDesignConfig.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionsCell(NewComplaint complaint) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(PhosphorIcons.eye(), size: 18, color: InventoryDesignConfig.primaryAccent),
          onPressed: () => _handleViewItem(complaint),
          tooltip: 'View Details',
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(PhosphorIcons.pencilSimple(), size: 18, color: InventoryDesignConfig.infoColor),
          onPressed: () => _handleEditItem(complaint),
          tooltip: 'Edit Complaint',
        ),
      ],
    );
  }

  Future<void> _handleEditItem(NewComplaint complaint) async {
    await NewComplaintDialog.show(
      context,
      customerId: complaint.customerId,
      customerName: complaint.customerName ?? 'Unknown',
      complaint: complaint,
      onComplaintUpdated: _loadComplaints,
    );
  }

  Future<void> _handleViewItem(NewComplaint complaint) async {
    await ComplaintDetailDialogDesktop.show(
      context,
      complaint: complaint,
      onComplaintUpdated: _loadComplaints,
    );
  }

  Future<void> _addComplaint() async {
    final customer = await CustomerSelectorForComplaintDialog.show(context);
    if (customer != null) {
      await NewComplaintDialog.show(
        context,
        customerId: customer.id,
        customerName: customer.name,
        onComplaintUpdated: _loadComplaints,
      );
    }
  }
}
