import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            _buildDetails(theme),
            const SizedBox(height: 24),
            _buildUpdates(theme),
            if (widget.complaint.status != ComplaintStatus.closed)
              _buildActionBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.complaint.title,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Created on ${_formatDate(widget.complaint.createdAt)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          icon: PhosphorIcon(PhosphorIcons.x()),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(widget.complaint.description),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildDetailChip(
              theme,
              'Status',
              widget.complaint.status.toString().split('.').last,
            ),
            const SizedBox(width: 16),
            _buildDetailChip(
              theme,
              'Priority',
              widget.complaint.priority.toString().split('.').last,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailChip(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdates(ThemeData theme) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Updates',
            style: theme.textTheme.titleMedium,
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
                  '${update.updatedBy} - ${_formatDate(update.timestamp)}',
                ),
                leading: const CircleAvatar(
                  child: Icon(Icons.person_outline),
                ),
              );
            },
          ),
        ],
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
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
