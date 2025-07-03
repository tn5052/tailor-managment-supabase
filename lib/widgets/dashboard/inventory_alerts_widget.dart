import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme/inventory_design_config.dart';
import '../../services/dashboard_service.dart';

class InventoryAlertsWidget extends StatefulWidget {
  const InventoryAlertsWidget({super.key});

  @override
  State<InventoryAlertsWidget> createState() => _InventoryAlertsWidgetState();
}

class _InventoryAlertsWidgetState extends State<InventoryAlertsWidget> {
  final DashboardService _dashboardService = DashboardService();
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _dashboardService.getInventoryAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: InventoryDesignConfig.borderSecondary,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.warning(),
                    size: 18,
                    color: InventoryDesignConfig.warningColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alerts & Issues',
                        style: InventoryDesignConfig.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Recent complaints & overdue orders',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_alerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _getCriticalCount() > 0
                              ? InventoryDesignConfig.errorColor.withOpacity(
                                0.1,
                              )
                              : InventoryDesignConfig.warningColor.withOpacity(
                                0.1,
                              ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_alerts.length}',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color:
                            _getCriticalCount() > 0
                                ? InventoryDesignConfig.errorColor
                                : InventoryDesignConfig.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Alerts List
          Expanded(
            child:
                _isLoading
                    ? _buildLoadingState()
                    : _alerts.isEmpty
                    ? _buildEmptyState()
                    : _buildAlertsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: InventoryDesignConfig.primaryColor,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.checkCircle(),
              size: 32,
              color: InventoryDesignConfig.successColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All Clear!',
            style: InventoryDesignConfig.titleMedium.copyWith(
              color: InventoryDesignConfig.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'No alerts or issues',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final alertType = alert['type'] as String;
    final alertName = alert['name'] as String;
    final description = alert['description'] as String? ?? '';
    final severity = alert['severity'] as String;
    final date = alert['date'] as String?;

    Color alertColor;
    IconData alertIcon;

    if (severity == 'critical') {
      alertColor = InventoryDesignConfig.errorColor;
      alertIcon = PhosphorIcons.warning();
    } else if (alertType == 'complaint') {
      alertColor = InventoryDesignConfig.warningColor;
      alertIcon = PhosphorIcons.chatCircle();
    } else {
      alertColor = InventoryDesignConfig.infoColor;
      alertIcon = PhosphorIcons.info();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Alert Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(alertIcon, size: 16, color: alertColor),
          ),
          const SizedBox(width: 12),

          // Alert Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertName,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(date),
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: alertColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Severity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              severity.toUpperCase(),
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: alertColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  int _getCriticalCount() {
    return _alerts.where((alert) => alert['severity'] == 'critical').length;
  }
}
