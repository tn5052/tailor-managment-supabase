import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';

class ComplaintDetailDialog extends StatefulWidget {
  final Complaint complaint;

  const ComplaintDetailDialog({
    super.key,
    required this.complaint,
  });

  @override
  State<ComplaintDetailDialog> createState() => _ComplaintDetailDialogState();
}

class _ComplaintDetailDialogState extends State<ComplaintDetailDialog> {
  final _complaintService = ComplaintService(Supabase.instance.client);
  final _commentController = TextEditingController();
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isDesktop ? 800 : MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainInfo(theme, dateFormat),
                    const SizedBox(height: 24),
                    _buildUpdatesSection(theme),
                    const SizedBox(height: 24),
                    _buildActionBar(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Icon(Icons.report_problem_outlined, color: theme.colorScheme.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.complaint.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Created on ${DateFormat('MMM dd, yyyy').format(widget.complaint.createdAt)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onPrimaryContainer),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.update, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Update Status'),
                  ],
                ),
              ),
              if (widget.complaint.status != ComplaintStatus.resolved)
                PopupMenuItem(
                  value: 'resolve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, 
                           size: 20, 
                           color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Mark as Resolved'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'assign',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Reassign'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Change Priority'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    Icon(Icons.close, size: 20, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Close Complaint',
                        style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'status':
        await _updateStatus();
        break;
      case 'resolve':
        await _resolveComplaint();
        break;
      case 'assign':
        await _reassignComplaint();
        break;
      case 'priority':
        await _updatePriority();
        break;
      case 'close':
        await _closeComplaint();
        break;
    }
  }

  Future<void> _updateStatus() async {
    final status = await showDialog<ComplaintStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ComplaintStatus.values
              .where((s) => s != widget.complaint.status)
              .map((s) => ListTile(
                    title: Text(s.toString().split('.').last),
                    leading: Icon(_getStatusIcon(s)),
                    onTap: () => Navigator.pop(context, s),
                  ))
              .toList(),
        ),
      ),
    );

    if (status != null && mounted) {
      setState(() => _isUpdating = true);
      try {
        await _complaintService.updateComplaintStatus(
          widget.complaint.id,
          status,
        );
        setState(() {
          widget.complaint.status = status;
          if (status == ComplaintStatus.resolved) {
            widget.complaint.resolvedAt = DateTime.now();
          }
        });
        _addSystemUpdate('Status updated to ${status.toString().split('.').last}');
      } finally {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _resolveComplaint() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Complaint'),
        content: const Text('Are you sure you want to mark this complaint as resolved?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESOLVE'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isUpdating = true);
      try {
        await _complaintService.updateComplaintStatus(
          widget.complaint.id,
          ComplaintStatus.resolved,
        );
        setState(() {
          widget.complaint.status = ComplaintStatus.resolved;
          widget.complaint.resolvedAt = DateTime.now();
        });
        _addSystemUpdate('Complaint marked as resolved');
      } finally {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updatePriority() async {
    final priority = await showDialog<ComplaintPriority>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ComplaintPriority.values.map((p) => ListTile(
                title: Text(p.toString().split('.').last),
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(p).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(p),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                onTap: () => Navigator.pop(context, p),
              )).toList(),
        ),
      ),
    );

    if (priority != null && mounted) {
      setState(() => _isUpdating = true);
      try {
        // Add method to ComplaintService to update priority
        await _complaintService.updateComplaintPriority(
          widget.complaint.id,
          priority,
        );
        setState(() => widget.complaint.priority = priority);
        _addSystemUpdate('Priority updated to ${priority.toString().split('.').last}');
      } finally {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _reassignComplaint() async {
    final controller = TextEditingController();
    final newAssignee = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Complaint'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Assignee ID',
            hintText: 'Enter user ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('ASSIGN'),
          ),
        ],
      ),
    );

    if (newAssignee != null && newAssignee.isNotEmpty && mounted) {
      setState(() => _isUpdating = true);
      try {
        // Add method to ComplaintService to reassign
        await _complaintService.reassignComplaint(
          widget.complaint.id,
          newAssignee,
        );
        setState(() => widget.complaint.assignedTo = newAssignee);
        _addSystemUpdate('Complaint reassigned to $newAssignee');
      } finally {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _closeComplaint() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Complaint'),
        content: const Text(
          'Are you sure you want to close this complaint? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isUpdating = true);
      try {
        await _complaintService.updateComplaintStatus(
          widget.complaint.id,
          ComplaintStatus.closed,
        );
        setState(() => widget.complaint.status = ComplaintStatus.closed);
        _addSystemUpdate('Complaint closed');
        Navigator.pop(context); // Close the dialog
      } finally {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _addSystemUpdate(String message) async {
    final update = ComplaintUpdate(
      id: const Uuid().v4(),
      comment: message,
      timestamp: DateTime.now(),
      updatedBy: 'System',
    );

    try {
      await _complaintService.addComplaintUpdate(
        widget.complaint.id,
        update,
      );
      setState(() => widget.complaint.updates.add(update));
    } catch (e) {
      // Handle error
    }
  }

  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Icons.pending_outlined;
      case ComplaintStatus.inProgress:
        return Icons.run_circle_outlined;
      case ComplaintStatus.resolved:
        return Icons.check_circle_outline;
      case ComplaintStatus.closed:
        return Icons.cancel_outlined;
      case ComplaintStatus.rejected:
        return Icons.block_outlined;
    }
  }

  Color _getPriorityColor(ComplaintPriority priority) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (priority) {
      case ComplaintPriority.low:
        return isDark ? Colors.green : Colors.green.shade600;
      case ComplaintPriority.medium:
        return isDark ? Colors.orange : Colors.orange.shade600;
      case ComplaintPriority.high:
        return isDark ? Colors.red : Colors.red.shade600;
      case ComplaintPriority.urgent:
        return isDark ? Colors.purple : Colors.purple.shade600;
    }
  }

  Widget _buildMainInfo(ThemeData theme, DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(widget.complaint.title),
                  subtitle: Text(
                    'Assigned to: ${widget.complaint.assignedTo}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(),
                _buildInfoRow(
                  'Status:',
                  widget.complaint.status.toString().split('.').last,
                  theme,
                ),
                _buildInfoRow(
                  'Priority:',
                  widget.complaint.priority.toString().split('.').last,
                  theme,
                ),
                _buildInfoRow(
                  'Created:',
                  dateFormat.format(widget.complaint.createdAt),
                  theme,
                ),
                if (widget.complaint.resolvedAt != null)
                  _buildInfoRow(
                    'Resolved:',
                    dateFormat.format(widget.complaint.resolvedAt!),
                    theme,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.complaint.description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdatesSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Updates',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              itemCount: widget.complaint.updates.length,
              itemBuilder: (context, index) {
                final update = widget.complaint.updates[index];
                return ListTile(
                  title: Text(update.comment),
                  subtitle: Text(
                    '${update.updatedBy} - ${DateFormat('MMM dd, yyyy').format(update.timestamp)}',
                  ),
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteUpdate(index),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _addUpdate,
              child: const Text('Add Update'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    Color? color,
  }) {
    final style = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: isBold ? FontWeight.bold : null,
      color: color,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }

  void _addUpdate() async {
    if (_commentController.text.isEmpty) return;

    final update = ComplaintUpdate(
      id: const Uuid().v4(),
      comment: _commentController.text,
      timestamp: DateTime.now(),
      updatedBy: 'current_user', // Replace with actual user
    );

    try {
      await _complaintService.addComplaintUpdate(
        widget.complaint.id,
        update,
      );
      setState(() {
        widget.complaint.updates.add(update);
        _commentController.clear();
      });
    } catch (e) {
      // Handle error
    }
  }

  void _deleteUpdate(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Update'),
        content: const Text('Are you sure you want to delete this update?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final update = widget.complaint.updates[index];
      try {
        await _complaintService.removeComplaintUpdate(widget.complaint.id, update.id);
        setState(() {
          widget.complaint.updates.removeAt(index);
        });
      } catch (e) {
        // Handle error
      }
    }
  }
}
