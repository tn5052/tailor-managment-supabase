import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../models/complaint.dart';
import '../theme/app_theme.dart';

class ComplaintCard extends StatefulWidget {
  final Complaint complaint;
  final VoidCallback onTap;
  final bool isGridView;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
    this.isGridView = false,
  });

  @override
  State<ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<ComplaintCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return widget.isGridView ? _buildGridCard(context) : _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceVariant.withOpacity(isHovered ? 0.2 : 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildPriorityDot(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.complaint.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildCustomerInfo(theme),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatus(theme),
                      Text(
                        DateFormat('MMM d').format(widget.complaint.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceVariant.withOpacity(isHovered ? 0.2 : 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildPriorityDot(),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.complaint.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildCustomerInfo(theme),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildStatus(theme),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('MMM d').format(widget.complaint.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            if (widget.complaint.invoiceId != null)
                              Text(
                                'INV-${widget.complaint.invoiceId}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getPriorityColor(widget.complaint.priority),
      ),
    );
  }

  Widget _buildStatus(ThemeData theme) {
    final color = _getStatusColor(widget.complaint.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.complaint.status.toString().split('.').last,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.person_outline,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.complaint.customerId,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(ComplaintPriority priority) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (priority) {
      case ComplaintPriority.low:
        return isDark ? Colors.green : AppTheme.successColor;
      case ComplaintPriority.medium:
        return isDark ? Colors.orange : AppTheme.warningColor;
      case ComplaintPriority.high:
        return isDark ? Colors.red : AppTheme.errorColor;
      case ComplaintPriority.urgent:
        return isDark ? Colors.purple : AppTheme.tertiaryColor;
    }
  }

  Color _getStatusColor(ComplaintStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case ComplaintStatus.pending:
        return isDark ? Colors.orange : AppTheme.warningColor;
      case ComplaintStatus.inProgress:
        return isDark ? Colors.blue : AppTheme.primaryColor;
      case ComplaintStatus.resolved:
        return isDark ? Colors.green : AppTheme.successColor;
      case ComplaintStatus.closed:
        return isDark ? Colors.grey : AppTheme.neutralColor;
      case ComplaintStatus.rejected:
        return isDark ? Colors.red : AppTheme.errorColor;
    }
  }
}
