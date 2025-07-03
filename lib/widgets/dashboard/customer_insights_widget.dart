import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/inventory_design_config.dart';
import '../../services/dashboard_service.dart';

class CustomerInsightsWidget extends StatefulWidget {
  final String timeRange;

  const CustomerInsightsWidget({super.key, required this.timeRange});

  @override
  State<CustomerInsightsWidget> createState() => _CustomerInsightsWidgetState();
}

class _CustomerInsightsWidgetState extends State<CustomerInsightsWidget> {
  final DashboardService _dashboardService = DashboardService();
  Map<String, dynamic> _insights = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  @override
  void didUpdateWidget(CustomerInsightsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange) {
      _loadInsights();
    }
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    try {
      final insights = await _dashboardService.getCustomerInsights(
        widget.timeRange,
      );
      if (mounted) {
        setState(() {
          _insights = insights;
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
                    color: InventoryDesignConfig.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.users(),
                    size: 18,
                    color: InventoryDesignConfig.infoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Customer Insights',
                  style: InventoryDesignConfig.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildInsightsContent(),
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

  Widget _buildInsightsContent() {
    final totalCustomers = _insights['totalCustomers'] ?? 0;
    final maleCustomers = _insights['maleCustomers'] ?? 0;
    final femaleCustomers = _insights['femaleCustomers'] ?? 0;
    final repeatCustomers = _insights['repeatCustomers'] ?? 0;
    final repeatRate = _insights['repeatCustomerRate'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Left side - Stats
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInsightRow(
                  'Total Customers',
                  totalCustomers.toString(),
                  PhosphorIcons.users(),
                  InventoryDesignConfig.primaryColor,
                ),
                const SizedBox(height: 16),
                _buildInsightRow(
                  'Male Customers',
                  maleCustomers.toString(),
                  PhosphorIcons.user(),
                  InventoryDesignConfig.infoColor,
                ),
                const SizedBox(height: 16),
                _buildInsightRow(
                  'Female Customers',
                  femaleCustomers.toString(),
                  PhosphorIcons.user(),
                  InventoryDesignConfig.successColor,
                ),
                const SizedBox(height: 16),
                _buildInsightRow(
                  'Repeat Customers',
                  '$repeatCustomers (${repeatRate.toStringAsFixed(1)}%)',
                  PhosphorIcons.arrowClockwise(),
                  InventoryDesignConfig.warningColor,
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Right side - Gender Distribution Chart
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Gender Distribution',
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      totalCustomers > 0
                          ? _buildGenderChart(maleCustomers, femaleCustomers)
                          : _buildEmptyChart(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: InventoryDesignConfig.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChart(int maleCount, int femaleCount) {
    final total = maleCount + femaleCount;
    if (total == 0) return _buildEmptyChart();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: InventoryDesignConfig.infoColor,
            value: maleCount.toDouble(),
            title: '${((maleCount / total) * 100).toInt()}%',
            radius: 45,
            titleStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          PieChartSectionData(
            color: InventoryDesignConfig.successColor,
            value: femaleCount.toDouble(),
            title: '${((femaleCount / total) * 100).toInt()}%',
            radius: 45,
            titleStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.users(),
            size: 32,
            color: InventoryDesignConfig.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(
            'No customers yet',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
