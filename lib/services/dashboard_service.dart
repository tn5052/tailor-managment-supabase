import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getOverviewStats(String timeRange) async {
    try {
      final days = _getDaysFromTimeRange(timeRange);
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      // Get current period data
      final currentPeriodData = await _getStatsForPeriod(startDate, endDate);

      // Get previous period data for comparison
      final previousStartDate = startDate.subtract(Duration(days: days));
      final previousPeriodData = await _getStatsForPeriod(
        previousStartDate,
        startDate,
      );

      return {
        'totalRevenue': currentPeriodData['revenue'],
        'totalOrders': currentPeriodData['orders'],
        'newCustomers': currentPeriodData['customers'],
        'avgOrderValue':
            currentPeriodData['orders'] > 0
                ? currentPeriodData['revenue'] / currentPeriodData['orders']
                : 0,
        'revenueChange': _calculatePercentageChange(
          previousPeriodData['revenue'],
          currentPeriodData['revenue'],
        ),
        'ordersChange': _calculatePercentageChange(
          previousPeriodData['orders'],
          currentPeriodData['orders'],
        ),
        'customersChange': _calculatePercentageChange(
          previousPeriodData['customers'],
          currentPeriodData['customers'],
        ),
        'avgOrderChange': _calculatePercentageChange(
          previousPeriodData['orders'] > 0
              ? previousPeriodData['revenue'] / previousPeriodData['orders']
              : 0,
          currentPeriodData['orders'] > 0
              ? currentPeriodData['revenue'] / currentPeriodData['orders']
              : 0,
        ),
      };
    } catch (e) {
      print('Error getting overview stats: $e');
      return {
        'totalRevenue': 0.0,
        'totalOrders': 0,
        'newCustomers': 0,
        'avgOrderValue': 0.0,
        'revenueChange': 0.0,
        'ordersChange': 0.0,
        'customersChange': 0.0,
        'avgOrderChange': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _getStatsForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Get invoices data for the period
      final invoicesResponse = await _supabase
          .from('invoices')
          .select('amount_including_vat, date')
          .gte('date', start.toIso8601String())
          .lt('date', end.toIso8601String())
          .eq('tenant_id', _supabase.auth.currentUser!.id);

      // Get customers data for the period
      final customersResponse = await _supabase
          .from('customers')
          .select('id')
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String())
          .eq('tenant_id', _supabase.auth.currentUser!.id);

      final totalRevenue = invoicesResponse.fold<double>(
        0.0,
        (sum, invoice) =>
            sum + (invoice['amount_including_vat'] as num).toDouble(),
      );

      return {
        'revenue': totalRevenue,
        'orders': invoicesResponse.length,
        'customers': customersResponse.length,
      };
    } catch (e) {
      print('Error getting stats for period: $e');
      return {'revenue': 0.0, 'orders': 0, 'customers': 0};
    }
  }

  int _getDaysFromTimeRange(String timeRange) {
    switch (timeRange) {
      case '7 days':
        return 7;
      case '30 days':
        return 30;
      case '90 days':
        return 90;
      case '1 year':
        return 365;
      default:
        return 30;
    }
  }

  double _calculatePercentageChange(num previous, num current) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }

  Future<List<Map<String, dynamic>>> getRevenueChartData(
    String timeRange,
  ) async {
    try {
      final days = _getDaysFromTimeRange(timeRange);
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final response = await _supabase
          .from('invoices')
          .select('amount_including_vat, date')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .eq('tenant_id', _supabase.auth.currentUser!.id)
          .order('date');

      // Group by date and aggregate revenue
      final Map<String, double> dailyRevenue = {};

      // Initialize all dates with 0
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        dailyRevenue[dateStr] = 0.0;
      }

      // Add actual revenue data
      for (final invoice in response) {
        final date =
            DateTime.parse(invoice['date']).toIso8601String().split('T')[0];
        dailyRevenue[date] =
            (dailyRevenue[date] ?? 0) +
            (invoice['amount_including_vat'] as num).toDouble();
      }

      return dailyRevenue.entries
          .map((entry) => {'date': entry.key, 'revenue': entry.value})
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    } catch (e) {
      print('Error getting revenue chart data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopCustomers(String timeRange) async {
    try {
      final days = _getDaysFromTimeRange(timeRange);
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('invoices')
          .select('customer_id, customer_name, amount_including_vat')
          .gte('date', startDate.toIso8601String())
          .eq('tenant_id', _supabase.auth.currentUser!.id);

      // Group by customer
      final Map<String, Map<String, dynamic>> customerData = {};

      for (final invoice in response) {
        final customerId = invoice['customer_id'];
        final customerName = invoice['customer_name'] ?? 'Unknown Customer';
        final amount = (invoice['amount_including_vat'] as num).toDouble();

        if (customerData.containsKey(customerId)) {
          customerData[customerId]!['totalSpent'] += amount;
          customerData[customerId]!['orderCount']++;
        } else {
          customerData[customerId] = {
            'id': customerId,
            'name': customerName,
            'totalSpent': amount,
            'orderCount': 1,
          };
        }
      }

      final sortedCustomers =
          customerData.values.toList()
            ..sort((a, b) => b['totalSpent'].compareTo(a['totalSpent']));

      return sortedCustomers.take(5).toList();
    } catch (e) {
      print('Error getting top customers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentOrders(int limit) async {
    try {
      final response = await _supabase
          .from('invoices')
          .select(
            'invoice_number, customer_name, amount_including_vat, delivery_status, payment_status, date',
          )
          .eq('tenant_id', _supabase.auth.currentUser!.id)
          .order('date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting recent orders: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getInventoryAlerts() async {
    try {
      final alerts = <Map<String, dynamic>>[];

      // Get actual complaints as inventory alerts
      final complaintsResponse = await _supabase
          .from('complaints')
          .select('title, description, status, priority, created_at')
          .eq('tenant_id', _supabase.auth.currentUser!.id)
          .inFilter('status', ['pending', 'in_progress'])
          .order('created_at', ascending: false)
          .limit(10);

      for (final complaint in complaintsResponse) {
        alerts.add({
          'type': 'complaint',
          'name': complaint['title'] ?? 'Issue',
          'description': complaint['description'] ?? '',
          'status': complaint['status'] ?? 'pending',
          'priority': complaint['priority'] ?? 'medium',
          'alertType': 'complaint',
          'severity': _getSeverityFromPriority(complaint['priority']),
          'date': complaint['created_at'],
        });
      }

      // Get overdue orders as alerts
      final overdueResponse = await _supabase
          .from('invoices')
          .select(
            'invoice_number, customer_name, delivery_date, delivery_status',
          )
          .eq('tenant_id', _supabase.auth.currentUser!.id)
          .lt('delivery_date', DateTime.now().toIso8601String())
          .neq('delivery_status', 'Delivered')
          .limit(5);

      for (final order in overdueResponse) {
        alerts.add({
          'type': 'overdue',
          'name': 'Overdue Order #${order['invoice_number']}',
          'description': 'Customer: ${order['customer_name']}',
          'status': order['delivery_status'],
          'alertType': 'overdue_order',
          'severity': 'critical',
          'date': order['delivery_date'],
        });
      }

      return alerts;
    } catch (e) {
      print('Error getting inventory alerts: $e');
      return [];
    }
  }

  String _getSeverityFromPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return 'critical';
      case 'medium':
        return 'warning';
      case 'low':
        return 'info';
      default:
        return 'warning';
    }
  }

  Future<Map<String, dynamic>> getCustomerInsights(String timeRange) async {
    try {
      final days = _getDaysFromTimeRange(timeRange);
      final startDate = DateTime.now().subtract(Duration(days: days));

      // Get customer data for the period
      final customersResponse = await _supabase
          .from('customers')
          .select('gender, created_at')
          .gte('created_at', startDate.toIso8601String())
          .eq('tenant_id', _supabase.auth.currentUser!.id);

      final totalCustomers = customersResponse.length;
      final maleCustomers =
          customersResponse.where((c) => c['gender'] == 'male').length;
      final femaleCustomers =
          customersResponse.where((c) => c['gender'] == 'female').length;

      // Get repeat customers (customers with more than 1 order)
      final invoicesResponse = await _supabase
          .from('invoices')
          .select('customer_id')
          .gte('date', startDate.toIso8601String())
          .eq('tenant_id', _supabase.auth.currentUser!.id);

      final customerOrderCounts = <String, int>{};
      for (final invoice in invoicesResponse) {
        final customerId = invoice['customer_id'];
        customerOrderCounts[customerId] =
            (customerOrderCounts[customerId] ?? 0) + 1;
      }

      final repeatCustomers =
          customerOrderCounts.values.where((count) => count > 1).length;

      return {
        'totalCustomers': totalCustomers,
        'maleCustomers': maleCustomers,
        'femaleCustomers': femaleCustomers,
        'repeatCustomers': repeatCustomers,
        'repeatCustomerRate':
            totalCustomers > 0 ? (repeatCustomers / totalCustomers) * 100 : 0,
      };
    } catch (e) {
      print('Error getting customer insights: $e');
      return {
        'totalCustomers': 0,
        'maleCustomers': 0,
        'femaleCustomers': 0,
        'repeatCustomers': 0,
        'repeatCustomerRate': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> getPerformanceMetrics(String timeRange) async {
    try {
      final days = _getDaysFromTimeRange(timeRange);
      final startDate = DateTime.now().subtract(Duration(days: days));

      // Get all invoices for the period
      final invoicesResponse = await _supabase
          .from('invoices')
          .select(
            'delivery_status, payment_status, date, delivery_date, amount_including_vat',
          )
          .gte('date', startDate.toIso8601String())
          .eq('tenant_id', _supabase.auth.currentUser!.id);

      final totalOrders = invoicesResponse.length;
      if (totalOrders == 0) {
        return {
          'fulfillmentRate': 0.0,
          'avgDeliveryTime': 0.0,
          'customerSatisfaction': 0.0,
          'returnRate': 0.0,
        };
      }

      // Calculate fulfillment rate (delivered orders)
      final deliveredOrders =
          invoicesResponse
              .where((o) => o['delivery_status'] == 'Delivered')
              .length;
      final fulfillmentRate = (deliveredOrders / totalOrders) * 100;

      // Calculate average delivery time
      final deliveredOrdersWithDates =
          invoicesResponse
              .where(
                (o) =>
                    o['delivery_status'] == 'Delivered' &&
                    o['date'] != null &&
                    o['delivery_date'] != null,
              )
              .toList();

      double avgDeliveryTime = 0.0;
      if (deliveredOrdersWithDates.isNotEmpty) {
        final totalDeliveryDays = deliveredOrdersWithDates.fold<int>(0, (
          sum,
          order,
        ) {
          final orderDate = DateTime.parse(order['date']);
          final deliveryDate = DateTime.parse(order['delivery_date']);
          return sum + deliveryDate.difference(orderDate).inDays;
        });
        avgDeliveryTime = totalDeliveryDays / deliveredOrdersWithDates.length;
      }

      // Get complaints for return rate calculation
      final complaintsResponse = await _supabase
          .from('complaints')
          .select('id')
          .gte('created_at', startDate.toIso8601String())
          .eq('tenant_id', _supabase.auth.currentUser!.id);

      final returnRate =
          totalOrders > 0
              ? (complaintsResponse.length / totalOrders) * 100
              : 0.0;

      // Mock customer satisfaction (in real app, you'd have a customer feedback system)
      final customerSatisfaction =
          5.0 - (returnRate / 20); // Simple calculation

      return {
        'fulfillmentRate': fulfillmentRate,
        'avgDeliveryTime': avgDeliveryTime,
        'customerSatisfaction': customerSatisfaction.clamp(0.0, 5.0),
        'returnRate': returnRate,
      };
    } catch (e) {
      print('Error getting performance metrics: $e');
      return {
        'fulfillmentRate': 0.0,
        'avgDeliveryTime': 0.0,
        'customerSatisfaction': 0.0,
        'returnRate': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> getMonthlyTargets() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Get current month data
      final monthlyData = await _getStatsForPeriod(startOfMonth, endOfMonth);

      // Calculate targets based on previous months average (simplified)
      final previousMonthStart = DateTime(now.year, now.month - 1, 1);
      final previousMonthEnd = DateTime(now.year, now.month, 0);
      final previousMonthData = await _getStatsForPeriod(
        previousMonthStart,
        previousMonthEnd,
      );

      // Set targets as 110% of previous month (growth target)
      final revenueTarget = previousMonthData['revenue'] * 1.1;
      final ordersTarget = (previousMonthData['orders'] * 1.1).round();
      final customersTarget =
          (previousMonthData['customers'] * 1.2)
              .round(); // Higher growth for customers

      return {
        'currentRevenue': monthlyData['revenue'],
        'revenueTarget':
            revenueTarget > 0
                ? revenueTarget
                : 50000, // Default target if no previous data
        'currentOrders': monthlyData['orders'],
        'ordersTarget': ordersTarget > 0 ? ordersTarget : 150,
        'currentCustomers': monthlyData['customers'],
        'customersTarget': customersTarget > 0 ? customersTarget : 25,
      };
    } catch (e) {
      print('Error getting monthly targets: $e');
      return {
        'currentRevenue': 0.0,
        'revenueTarget': 50000.0,
        'currentOrders': 0,
        'ordersTarget': 150,
        'currentCustomers': 0,
        'customersTarget': 25,
      };
    }
  }
}
