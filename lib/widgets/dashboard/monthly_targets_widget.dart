import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/inventory_design_config.dart';
import '../../services/dashboard_service.dart';

class MonthlyTargetsWidget extends StatefulWidget {
  final String timeRange;

  const MonthlyTargetsWidget({super.key, required this.timeRange});

  @override
  State<MonthlyTargetsWidget> createState() => _MonthlyTargetsWidgetState();
}

class _MonthlyTargetsWidgetState extends State<MonthlyTargetsWidget> {
  final DashboardService _dashboardService = DashboardService();
  Map<String, dynamic> _targets = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    setState(() => _isLoading = true);
    try {
      final targets = await _dashboardService.getMonthlyTargets();
      if (mounted) {
        setState(() {
          _targets = targets;
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
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.target(),
                    size: 18,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Targets',
                        style: InventoryDesignConfig.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime.now()),
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
                    color: _getOverallProgressColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_getOverallProgress().toInt()}%',
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: _getOverallProgressColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Targets Content
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildTargetsContent(),
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

  Widget _buildTargetsContent() {
    final currentRevenue = (_targets['currentRevenue'] ?? 0.0).toDouble();
    final revenueTarget = (_targets['revenueTarget'] ?? 50000.0).toDouble();
    final currentOrders = (_targets['currentOrders'] ?? 0).toInt();
    final ordersTarget = (_targets['ordersTarget'] ?? 150).toInt();
    final currentCustomers = (_targets['currentCustomers'] ?? 0).toInt();
    final customersTarget = (_targets['customersTarget'] ?? 25).toInt();

    final revenueProgress =
        revenueTarget > 0
            ? (currentRevenue / revenueTarget).clamp(0.0, 1.0)
            : 0.0;
    final ordersProgress =
        ordersTarget > 0 ? (currentOrders / ordersTarget).clamp(0.0, 1.0) : 0.0;
    final customersProgress =
        customersTarget > 0
            ? (currentCustomers / customersTarget).clamp(0.0, 1.0)
            : 0.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTargetRow(
            'Revenue',
            currentRevenue,
            revenueTarget,
            revenueProgress,
            PhosphorIcons.currencyDollar(),
            InventoryDesignConfig.successColor,
            true, // isCurrency
          ),
          const SizedBox(height: 16),
          _buildTargetRow(
            'Orders',
            currentOrders.toDouble(),
            ordersTarget.toDouble(),
            ordersProgress,
            PhosphorIcons.receipt(),
            InventoryDesignConfig.primaryColor,
            false,
          ),
          const SizedBox(height: 16),
          _buildTargetRow(
            'New Customers',
            currentCustomers.toDouble(),
            customersTarget.toDouble(),
            customersProgress,
            PhosphorIcons.users(),
            InventoryDesignConfig.infoColor,
            false,
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildProgressChart()),
        ],
      ),
    );
  }

  Widget _buildTargetRow(
    String label,
    double current,
    double target,
    double progress,
    IconData icon,
    Color color,
    bool isCurrency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              isCurrency
                  ? '${NumberFormat.currency(symbol: 'AED ', decimalDigits: 0).format(current)} / ${NumberFormat.currency(symbol: 'AED ', decimalDigits: 0).format(target)}'
                  : '${current.toInt()} / ${target.toInt()}',
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: InventoryDesignConfig.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChart() {
    final overallProgress = _getOverallProgress();

    return Row(
      children: [
        // Circular Progress
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: overallProgress / 100,
                strokeWidth: 6,
                backgroundColor: InventoryDesignConfig.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getOverallProgressColor(),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${overallProgress.toInt()}%',
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _getOverallProgressColor(),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Overall',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Progress Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Progress Summary',
                style: InventoryDesignConfig.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _getProgressMessage(),
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _getProgressIcon(),
                    size: 16,
                    color: _getOverallProgressColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getProgressStatus(),
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: _getOverallProgressColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getOverallProgress() {
    final currentRevenue = (_targets['currentRevenue'] ?? 0.0).toDouble();
    final revenueTarget = (_targets['revenueTarget'] ?? 50000.0).toDouble();
    final currentOrders = (_targets['currentOrders'] ?? 0).toInt();
    final ordersTarget = (_targets['ordersTarget'] ?? 150).toInt();
    final currentCustomers = (_targets['currentCustomers'] ?? 0).toInt();
    final customersTarget = (_targets['customersTarget'] ?? 25).toInt();

    final revenueProgress =
        revenueTarget > 0 ? (currentRevenue / revenueTarget) * 100 : 0;
    final ordersProgress =
        ordersTarget > 0 ? (currentOrders / ordersTarget) * 100 : 0;
    final customersProgress =
        customersTarget > 0 ? (currentCustomers / customersTarget) * 100 : 0;

    return (revenueProgress + ordersProgress + customersProgress) / 3;
  }

  Color _getOverallProgressColor() {
    final progress = _getOverallProgress();
    if (progress >= 80) return InventoryDesignConfig.successColor;
    if (progress >= 60) return InventoryDesignConfig.warningColor;
    return InventoryDesignConfig.errorColor;
  }

  IconData _getProgressIcon() {
    final progress = _getOverallProgress();
    if (progress >= 80) return PhosphorIcons.trendUp();
    if (progress >= 60) return PhosphorIcons.minus();
    return PhosphorIcons.trendDown();
  }

  String _getProgressStatus() {
    final progress = _getOverallProgress();
    if (progress >= 80) return 'On Track';
    if (progress >= 60) return 'Behind';
    return 'Needs Attention';
  }

  String _getProgressMessage() {
    final progress = _getOverallProgress();
    if (progress >= 80) return 'Great work! You\'re exceeding targets';
    if (progress >= 60) return 'Good progress, keep pushing';
    return 'Focus needed to reach targets';
  }
}
