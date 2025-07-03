import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../theme/inventory_design_config.dart';
import '../../services/dashboard_service.dart';

class PerformanceMetricsWidget extends StatefulWidget {
  final String timeRange;

  const PerformanceMetricsWidget({super.key, required this.timeRange});

  @override
  State<PerformanceMetricsWidget> createState() =>
      _PerformanceMetricsWidgetState();
}

class _PerformanceMetricsWidgetState extends State<PerformanceMetricsWidget> {
  final DashboardService _dashboardService = DashboardService();
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  @override
  void didUpdateWidget(PerformanceMetricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange) {
      _loadMetrics();
    }
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    try {
      final metrics = await _dashboardService.getPerformanceMetrics(
        widget.timeRange,
      );
      if (mounted) {
        setState(() {
          _metrics = metrics;
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
      height: 400,
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
                    PhosphorIcons.gauge(),
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
                        'Performance Metrics',
                        style: InventoryDesignConfig.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Key business indicators',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.timeRange,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Metrics Content
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildMetricsContent(),
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

  Widget _buildMetricsContent() {
    final fulfillmentRate = _metrics['fulfillmentRate'] ?? 0.0;
    final avgDeliveryTime = _metrics['avgDeliveryTime'] ?? 0.0;
    final customerSatisfaction = _metrics['customerSatisfaction'] ?? 0.0;
    final returnRate = _metrics['returnRate'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: _buildMetricCard(
              'Order Fulfillment Rate',
              '${fulfillmentRate.toStringAsFixed(1)}%',
              PhosphorIcons.checkCircle(),
              InventoryDesignConfig.successColor,
              _getPerformanceText(fulfillmentRate, 80),
              fulfillmentRate >= 80,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildMetricCard(
              'Average Delivery Time',
              '${avgDeliveryTime.toStringAsFixed(1)} days',
              PhosphorIcons.clock(),
              InventoryDesignConfig.infoColor,
              _getDeliveryText(avgDeliveryTime),
              avgDeliveryTime <= 5,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildMetricCard(
              'Customer Satisfaction',
              '${customerSatisfaction.toStringAsFixed(1)}/5.0',
              PhosphorIcons.star(),
              InventoryDesignConfig.warningColor,
              _getSatisfactionText(customerSatisfaction),
              customerSatisfaction >= 4.0,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildMetricCard(
              'Return/Complaint Rate',
              '${returnRate.toStringAsFixed(1)}%',
              PhosphorIcons.arrowCounterClockwise(),
              InventoryDesignConfig.errorColor,
              _getReturnText(returnRate),
              returnRate <= 5,
            ),
          ),
        ],
      ),
    );
  }

  String _getPerformanceText(double rate, double target) {
    if (rate >= target) return 'Excellent performance';
    if (rate >= target * 0.8) return 'Good performance';
    return 'Needs improvement';
  }

  String _getDeliveryText(double days) {
    if (days <= 3) return 'Very fast delivery';
    if (days <= 5) return 'Good delivery time';
    if (days <= 7) return 'Average delivery';
    return 'Slow delivery';
  }

  String _getSatisfactionText(double rating) {
    if (rating >= 4.5) return 'Excellent satisfaction';
    if (rating >= 4.0) return 'Good satisfaction';
    if (rating >= 3.5) return 'Average satisfaction';
    return 'Poor satisfaction';
  }

  String _getReturnText(double rate) {
    if (rate <= 2) return 'Very low returns';
    if (rate <= 5) return 'Low returns';
    if (rate <= 10) return 'Moderate returns';
    return 'High returns';
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: InventoryDesignConfig.headlineMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isPositive
                          ? PhosphorIcons.trendUp()
                          : PhosphorIcons.trendDown(),
                      size: 12,
                      color:
                          isPositive
                              ? InventoryDesignConfig.successColor
                              : InventoryDesignConfig.errorColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        change,
                        style: InventoryDesignConfig.bodySmall.copyWith(
                          color:
                              isPositive
                                  ? InventoryDesignConfig.successColor
                                  : InventoryDesignConfig.errorColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
