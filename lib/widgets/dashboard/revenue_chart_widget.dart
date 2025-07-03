import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/inventory_design_config.dart';
import '../../services/dashboard_service.dart';

class RevenueChartWidget extends StatefulWidget {
  final String timeRange;

  const RevenueChartWidget({super.key, required this.timeRange});

  @override
  State<RevenueChartWidget> createState() => _RevenueChartWidgetState();
}

class _RevenueChartWidgetState extends State<RevenueChartWidget> {
  final DashboardService _dashboardService = DashboardService();
  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = true;
  double _maxY = 0;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  @override
  void didUpdateWidget(RevenueChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange) {
      _loadChartData();
    }
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dashboardService.getRevenueChartData(
        widget.timeRange,
      );
      if (mounted) {
        setState(() {
          _chartData = data;
          _maxY =
              data.isNotEmpty
                  ? data
                          .map((e) => e['revenue'] as double)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2
                  : 1000;
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
                    color: InventoryDesignConfig.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.trendUp(),
                    size: 18,
                    color: InventoryDesignConfig.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenue Trends',
                        style: InventoryDesignConfig.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Daily revenue over ${widget.timeRange}',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isLoading && _chartData.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.successColor.withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Total: ${NumberFormat.currency(symbol: 'AED ').format(_getTotalRevenue())}',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Chart
          Expanded(
            child:
                _isLoading
                    ? _buildLoadingState()
                    : _chartData.isEmpty
                    ? _buildEmptyState()
                    : _buildChart(),
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
          Icon(
            PhosphorIcons.chartLine(),
            size: 48,
            color: InventoryDesignConfig.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No revenue data',
            style: InventoryDesignConfig.titleMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          Text(
            'Data will appear here once you have sales',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _maxY / 5,
            getDrawingHorizontalLine:
                (value) => FlLine(
                  color: InventoryDesignConfig.borderSecondary,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _getBottomInterval(),
                getTitlesWidget: (value, meta) {
                  if (_chartData.isEmpty) return const SizedBox();

                  final index = value.toInt();
                  if (index < 0 || index >= _chartData.length)
                    return const SizedBox();

                  final date = DateTime.parse(_chartData[index]['date']);
                  return Text(
                    DateFormat('MM/dd').format(date),
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots:
                  _chartData.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value['revenue'].toDouble(),
                    );
                  }).toList(),
              isCurved: true,
              color: InventoryDesignConfig.successColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: InventoryDesignConfig.successColor,
                    strokeColor: InventoryDesignConfig.surfaceColor,
                    strokeWidth: 2,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    InventoryDesignConfig.successColor.withOpacity(0.3),
                    InventoryDesignConfig.successColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBorder: BorderSide(
                color: InventoryDesignConfig.borderPrimary,
              ),
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = DateTime.parse(
                    _chartData[spot.x.toInt()]['date'],
                  );
                  return LineTooltipItem(
                    '${DateFormat('MMM dd').format(date)}\n${NumberFormat.currency(symbol: 'AED ').format(spot.y)}',
                    InventoryDesignConfig.bodyMedium.copyWith(
                      color: InventoryDesignConfig.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          minY: 0,
          maxY: _maxY,
        ),
      ),
    );
  }

  double _getBottomInterval() {
    if (_chartData.length <= 7) return 1;
    if (_chartData.length <= 14) return 2;
    if (_chartData.length <= 30) return 5;
    return 10;
  }

  double _getTotalRevenue() {
    return _chartData.fold(
      0.0,
      (sum, data) => sum + (data['revenue'] as double),
    );
  }
}
