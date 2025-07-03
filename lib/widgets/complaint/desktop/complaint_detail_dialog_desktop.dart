import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/new_complaint_model.dart';
import '../../../services/new_complaint_service.dart';
import '../../../theme/inventory_design_config.dart';
import '../new_complaint_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintDetailDialogDesktop extends StatefulWidget {
  final NewComplaint complaint;
  final VoidCallback? onComplaintUpdated;

  const ComplaintDetailDialogDesktop({
    super.key,
    required this.complaint,
    this.onComplaintUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required NewComplaint complaint,
    VoidCallback? onComplaintUpdated,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ComplaintDetailDialogDesktop(
        complaint: complaint,
        onComplaintUpdated: onComplaintUpdated,
      ),
    );
  }

  @override
  State<ComplaintDetailDialogDesktop> createState() => _ComplaintDetailDialogDesktopState();
}

class _ComplaintDetailDialogDesktopState extends State<ComplaintDetailDialogDesktop> {
  final _supabase = Supabase.instance.client;
  late final NewComplaintService _complaintService;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _complaintService = NewComplaintService(_supabase);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 900, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: InventoryDesignConfig.spacingXXL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          topRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(bottom: BorderSide(color: InventoryDesignConfig.borderSecondary)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.complaint.priority.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            ),
            child: Icon(
              PhosphorIcons.warning(),
              size: 18,
              color: widget.complaint.priority.color,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.complaint.title,
                  style: InventoryDesignConfig.headlineMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Complaint #${widget.complaint.id.substring(0, 8)}',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              child: Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                child: Icon(
                  PhosphorIcons.x(),
                  size: 18,
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildLeftSection()),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          Expanded(flex: 3, child: _buildRightSection()),
        ],
      ),
    );
  }

  Widget _buildLeftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('Status & Priority', PhosphorIcons.flag(), [
          _buildStatusAndPriorityInfo(),
        ]),
        const SizedBox(height: InventoryDesignConfig.spacingXL),
        _buildSection('Information', PhosphorIcons.info(), [
          _buildInfoGrid(),
        ]),
        const SizedBox(height: InventoryDesignConfig.spacingXL),
        _buildSection('Timeline', PhosphorIcons.clock(), [
          _buildTimelineInfo(),
        ]),
      ],
    );
  }

  Widget _buildRightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.complaint.description != null && widget.complaint.description!.isNotEmpty)
          _buildSection('Description', PhosphorIcons.notePencil(), [
            _buildDescriptionContent(),
          ]),
        if (widget.complaint.description != null && widget.complaint.description!.isNotEmpty)
          const SizedBox(height: InventoryDesignConfig.spacingXL),
        if (widget.complaint.resolutionDetails != null && widget.complaint.resolutionDetails!.isNotEmpty)
          _buildSection('Resolution Details', PhosphorIcons.checkCircle(), [
            _buildResolutionContent(),
          ]),
        if (widget.complaint.resolutionDetails == null || widget.complaint.resolutionDetails!.isEmpty)
          _buildSection('Resolution', PhosphorIcons.warning(), [
            _buildPendingResolution(),
          ]),
      ],
    );
  }

  // New section builder for consistent styling
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
              ),
              border: Border(bottom: BorderSide(color: InventoryDesignConfig.borderSecondary)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                  ),
                  child: Icon(icon, size: 16, color: InventoryDesignConfig.primaryColor),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  title,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndPriorityInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusChip(
            widget.complaint.status.displayName,
            widget.complaint.status.color,
            PhosphorIcons.trafficSignal(),
          ),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingL),
        Expanded(
          child: _buildStatusChip(
            widget.complaint.priority.displayName,
            widget.complaint.priority.color,
            PhosphorIcons.warning(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            label,
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        _buildInfoRow('Customer', widget.complaint.customerName ?? 'N/A', PhosphorIcons.user()),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildInfoRow('Invoice', widget.complaint.invoiceNumber != null ? '#${widget.complaint.invoiceNumber}' : 'N/A', PhosphorIcons.receipt()),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildInfoRow('Assigned To', widget.complaint.assignedTo ?? 'Unassigned', PhosphorIcons.userFocus()),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingXS),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          ),
          child: Icon(icon, size: 16, color: InventoryDesignConfig.primaryColor),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
              Text(
                value,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineInfo() {
    return Column(
      children: [
        _buildTimelineItem(
          'Created',
          DateFormat('MMM d, yyyy • h:mm a').format(widget.complaint.createdAt),
          PhosphorIcons.plus(),
          InventoryDesignConfig.primaryColor,
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildTimelineItem(
          'Last Updated',
          DateFormat('MMM d, yyyy • h:mm a').format(widget.complaint.updatedAt),
          PhosphorIcons.clockClockwise(),
          InventoryDesignConfig.infoColor,
        ),
        if (widget.complaint.resolvedAt != null) ...[
          const SizedBox(height: InventoryDesignConfig.spacingM),
          _buildTimelineItem(
            'Resolved',
            DateFormat('MMM d, yyyy • h:mm a').format(widget.complaint.resolvedAt!),
            PhosphorIcons.checkCircle(),
            InventoryDesignConfig.successColor,
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineItem(String label, String date, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingXS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
              Text(
                date,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Text(
        widget.complaint.description!,
        style: InventoryDesignConfig.bodyMedium.copyWith(height: 1.5),
      ),
    );
  }

  Widget _buildResolutionContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.successColor.withOpacity(0.2)),
      ),
      child: Text(
        widget.complaint.resolutionDetails!,
        style: InventoryDesignConfig.bodyMedium.copyWith(height: 1.5),
      ),
    );
  }

  Widget _buildPendingResolution() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.warningColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.clock(),
            size: 16,
            color: InventoryDesignConfig.warningColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Text(
              'This complaint is pending resolution. Please update the status and add resolution details when resolved.',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEdit() async {
    Navigator.of(context).pop(); // Close current dialog
    await NewComplaintDialog.show(
      context,
      customerId: widget.complaint.customerId,
      customerName: widget.complaint.customerName ?? 'Unknown',
      complaint: widget.complaint,
      onComplaintUpdated: widget.onComplaintUpdated,
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Complaint'),
        content: const Text(
          'Are you sure you want to delete this complaint? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: InventoryDesignConfig.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await _complaintService.deleteComplaint(widget.complaint.id);
        if (mounted) {
          Navigator.of(context).pop(); // Close detail dialog
          widget.onComplaintUpdated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Complaint deleted successfully'),
              backgroundColor: InventoryDesignConfig.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting complaint: ${e.toString()}'),
              backgroundColor: InventoryDesignConfig.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  Widget _buildFooter() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: InventoryDesignConfig.spacingXXL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          bottomRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(top: BorderSide(color: InventoryDesignConfig.borderSecondary)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _isDeleting ? null : _handleDelete,
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                  border: Border.all(color: InventoryDesignConfig.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isDeleting)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: InventoryDesignConfig.errorColor,
                        ),
                      )
                    else
                      Icon(PhosphorIcons.trash(), size: 16, color: InventoryDesignConfig.errorColor),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      _isDeleting ? 'Deleting...' : 'Delete',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: InventoryDesignConfig.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: _handleEdit,
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXXL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: InventoryDesignConfig.buttonPrimaryDecoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.pencilSimple(), size: 16, color: Colors.white),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      'Edit Complaint',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
