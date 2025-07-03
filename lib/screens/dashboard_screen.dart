import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/inventory_design_config.dart';
import '../widgets/dashboard/overview_stats_widget.dart';
import '../widgets/dashboard/revenue_chart_widget.dart';
import '../widgets/dashboard/recent_orders_widget.dart';
import '../widgets/dashboard/customer_insights_widget.dart';
import '../widgets/dashboard/inventory_alerts_widget.dart';
import '../widgets/dashboard/performance_metrics_widget.dart';
import '../widgets/dashboard/top_customers_widget.dart';
import '../widgets/dashboard/monthly_targets_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  String _selectedTimeRange = '30 days';
  final List<String> _timeRangeOptions = [
    '7 days',
    '30 days',
    '90 days',
    '1 year',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.backgroundColor,
      ),
      child: Column(
        children: [
          // Header Section
          _buildHeader(),

          // Main Content
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildDashboardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.backgroundColor,
      ),
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
      child: Row(
        children: [
          // Title section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      InventoryDesignConfig.primaryColor,
                      InventoryDesignConfig.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: InventoryDesignConfig.primaryColor.withOpacity(
                        0.3,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIcons.chartLine(),
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Dashboard',
                    style: InventoryDesignConfig.headlineLarge.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Real-time insights for your tailor business',
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      fontSize: 14,
                      color: InventoryDesignConfig.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Time range selector and refresh
          Row(
            children: [
              _buildTimeRangeSelector(),
              const SizedBox(width: 16),
              _buildRefreshButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeRange,
          icon: Icon(
            PhosphorIcons.caretDown(),
            size: 16,
            color: InventoryDesignConfig.textSecondary,
          ),
          style: InventoryDesignConfig.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: InventoryDesignConfig.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedTimeRange = newValue;
              });
              _loadDashboardData();
            }
          },
          items:
              _timeRangeOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.calendar(),
                          size: 16,
                          color: InventoryDesignConfig.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: _isLoading ? null : _loadDashboardData,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: InventoryDesignConfig.buttonSecondaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                )
              else
                Icon(
                  PhosphorIcons.arrowClockwise(),
                  size: 16,
                  color: InventoryDesignConfig.textSecondary,
                ),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                _isLoading ? 'Refreshing...' : 'Refresh',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Dashboard...',
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fetching your business insights',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Stats Row
          OverviewStatsWidget(timeRange: _selectedTimeRange),

          const SizedBox(height: 24),

          // Charts and Analytics Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Revenue Chart
              Expanded(
                flex: 2,
                child: RevenueChartWidget(timeRange: _selectedTimeRange),
              ),

              const SizedBox(width: 24),

              // Right Column - Performance Metrics
              Expanded(
                flex: 1,
                child: PerformanceMetricsWidget(timeRange: _selectedTimeRange),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Middle Row - Customer Insights and Monthly Targets
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomerInsightsWidget(timeRange: _selectedTimeRange),
              ),

              const SizedBox(width: 24),

              Expanded(
                child: MonthlyTargetsWidget(timeRange: _selectedTimeRange),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bottom Row - Recent Orders, Top Customers, and Alerts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Orders
              Expanded(
                flex: 2,
                child: RecentOrdersWidget(timeRange: _selectedTimeRange),
              ),

              const SizedBox(width: 24),

              // Right Column with Top Customers and Inventory Alerts
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    TopCustomersWidget(timeRange: _selectedTimeRange),
                    const SizedBox(height: 24),
                    InventoryAlertsWidget(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
