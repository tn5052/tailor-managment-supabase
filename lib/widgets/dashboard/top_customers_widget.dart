import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme/inventory_design_config.dart';
import '../../services/dashboard_service.dart';

class TopCustomersWidget extends StatefulWidget {
  final String timeRange;

  const TopCustomersWidget({super.key, required this.timeRange});

  @override
  State<TopCustomersWidget> createState() => _TopCustomersWidgetState();
}

class _TopCustomersWidgetState extends State<TopCustomersWidget> {
  final DashboardService _dashboardService = DashboardService();
  List<Map<String, dynamic>> _topCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopCustomers();
  }

  @override
  void didUpdateWidget(TopCustomersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange) {
      _loadTopCustomers();
    }
  }

  Future<void> _loadTopCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _dashboardService.getTopCustomers(
        widget.timeRange,
      );
      if (mounted) {
        setState(() {
          _topCustomers = customers;
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
                    color: InventoryDesignConfig.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.crown(),
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
                        'Top Customers',
                        style: InventoryDesignConfig.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'By total spending',
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
                    color: InventoryDesignConfig.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Top ${_topCustomers.length}',
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child:
                _isLoading
                    ? _buildLoadingState()
                    : _topCustomers.isEmpty
                    ? _buildEmptyState()
                    : _buildCustomersList(),
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
            PhosphorIcons.users(),
            size: 48,
            color: InventoryDesignConfig.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No customer data',
            style: InventoryDesignConfig.titleMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          Text(
            'Customer rankings will appear here',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topCustomers.length,
      itemBuilder: (context, index) {
        final customer = _topCustomers[index];
        return _buildCustomerCard(customer, index);
      },
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer, int index) {
    final totalSpent = (customer['totalSpent'] as num).toDouble();
    final orderCount = customer['orderCount'] as int;
    final customerName = customer['name'] ?? 'Unknown Customer';

    // Get rank colors
    Color rankColor;
    IconData rankIcon;

    switch (index) {
      case 0:
        rankColor = const Color(0xFFFFD700); // Gold
        rankIcon = PhosphorIcons.crown();
        break;
      case 1:
        rankColor = const Color(0xFFC0C0C0); // Silver
        rankIcon = PhosphorIcons.medal();
        break;
      case 2:
        rankColor = const Color(0xFFCD7F32); // Bronze
        rankIcon = PhosphorIcons.medal();
        break;
      default:
        rankColor = InventoryDesignConfig.textSecondary;
        rankIcon = PhosphorIcons.user();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              index < 3
                  ? rankColor.withOpacity(0.3)
                  : InventoryDesignConfig.borderSecondary,
        ),
        boxShadow: [
          if (index < 3)
            BoxShadow(
              color: rankColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: rankColor.withOpacity(0.3)),
            ),
            child: Center(
              child:
                  index < 3
                      ? Icon(rankIcon, size: 16, color: rankColor)
                      : Text(
                        '${index + 1}',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: rankColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
            ),
          ),
          const SizedBox(width: 12),

          // Customer Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$orderCount orders',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(symbol: 'AED ').format(totalSpent),
                style: InventoryDesignConfig.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: InventoryDesignConfig.successColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Total',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
