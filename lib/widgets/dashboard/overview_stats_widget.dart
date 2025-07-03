import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme/inventory_design_config.dart';
import '../../services/dashboard_service.dart';

class OverviewStatsWidget extends StatefulWidget {
  final String timeRange;

  const OverviewStatsWidget({super.key, required this.timeRange});

  @override
  State<OverviewStatsWidget> createState() => _OverviewStatsWidgetState();
}

class _OverviewStatsWidgetState extends State<OverviewStatsWidget> {
  final DashboardService _dashboardService = DashboardService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(OverviewStatsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _dashboardService.getOverviewStats(widget.timeRange);
      if (mounted) {
        setState(() {
          _stats = stats;
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
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIcons.chartBar(),
                  size: 18,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Business Overview',
                style: InventoryDesignConfig.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.timeRange,
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stats Grid
          if (_isLoading) _buildLoadingState() else _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(
          color: InventoryDesignConfig.primaryColor,
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Revenue',
            value: NumberFormat.currency(
              symbol: 'AED ',
            ).format(_stats['totalRevenue'] ?? 0),
            change: _stats['revenueChange'] ?? 0.0,
            icon: PhosphorIcons.currencyDollar(),
            color: InventoryDesignConfig.successColor,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            title: 'Total Orders',
            value: (_stats['totalOrders'] ?? 0).toString(),
            change: _stats['ordersChange'] ?? 0.0,
            icon: PhosphorIcons.receipt(),
            color: InventoryDesignConfig.primaryColor,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            title: 'New Customers',
            value: (_stats['newCustomers'] ?? 0).toString(),
            change: _stats['customersChange'] ?? 0.0,
            icon: PhosphorIcons.users(),
            color: InventoryDesignConfig.infoColor,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            title: 'Avg. Order Value',
            value: NumberFormat.currency(
              symbol: 'AED ',
            ).format(_stats['avgOrderValue'] ?? 0),
            change: _stats['avgOrderChange'] ?? 0.0,
            icon: PhosphorIcons.trendUp(),
            color: InventoryDesignConfig.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required double change,
    required IconData icon,
    required Color color,
  }) {
    final isPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive
                          ? InventoryDesignConfig.successColor
                          : InventoryDesignConfig.errorColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    Text(
                      '${change.abs().toStringAsFixed(1)}%',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color:
                            isPositive
                                ? InventoryDesignConfig.successColor
                                : InventoryDesignConfig.errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: InventoryDesignConfig.headlineLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
