import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/complaint.dart';
import '../../services/invoice_service.dart';
import '../../services/complaint_service.dart';
import '../../services/measurement_service.dart';
import '../../utils/number_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerReportDialog extends StatefulWidget {
  final Customer customer;
  final bool isMobile;

  const CustomerReportDialog({
    super.key, 
    required this.customer,
    this.isMobile = false,
  });

  @override
  State<CustomerReportDialog> createState() => _CustomerReportDialogState();
}

class _CustomerReportDialogState extends State<CustomerReportDialog> with SingleTickerProviderStateMixin {
  final InvoiceService _invoiceService = InvoiceService();
  final ComplaintService _complaintService = ComplaintService(Supabase.instance.client);
  final MeasurementService _measurementService = MeasurementService();

  bool _isLoading = true;
  late AnimationController _animationController;
  
  // Financial data
  List<Invoice> _invoices = [];
  double _totalSpent = 0;
  double _averageOrderValue = 0;
  double _outstandingBalance = 0;
  Map<String, int> _paymentStatusCounts = {};
  Map<int, double> _monthlySpendings = {};
  // ignore: unused_field
  Map<int, double> _yearlySpending = {};
  Map<DateTime, double> _dailySpending = {};
  List<Complaint> _complaints = [];
  // ignore: unused_field
  int _totalMeasurements = 0;
  
  // Chart selected date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();
  
  // Selected time period for charts
  String _selectedTimePeriod = 'Year';
  final List<String> _timePeriods = ['Month', 'Quarter', 'Year', 'All Time'];

  // Touch point for line chart
  FlSpot? _touchedSpot;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load financial data
      final invoices = await _invoiceService.getInvoicesByCustomerId(widget.customer.id);
      final complaints = await _complaintService.getComplaintsByCustomerId(widget.customer.id);
      final measurementsCount = await _measurementService.getMeasurementCountByCustomerId(widget.customer.id);
      
      // Process invoices to get financial insights
      double totalSpent = 0;
      double outstandingBalance = 0;
      Map<String, int> paymentStatusCounts = {};
      Map<int, double> monthlySpendings = {};
      Map<int, double> yearlySpending = {};
      Map<DateTime, double> dailySpending = {};

      for (final invoice in invoices) {
        // Calculate total spent
        totalSpent += invoice.amountIncludingVat;
        
        // Calculate outstanding balance
        if (invoice.paymentStatus == 'pending' || invoice.paymentStatus == 'partial') {
          outstandingBalance += invoice.balance;
        }
        
        // Count payment statuses
        final status = invoice.paymentStatus.toString().toLowerCase();
        paymentStatusCounts[status] = (paymentStatusCounts[status] ?? 0) + 1;
        
        // Get the month key (year*100 + month for sorting)
        final monthKey = invoice.date.year * 100 + invoice.date.month;
        monthlySpendings[monthKey] = (monthlySpendings[monthKey] ?? 0) + invoice.amountIncludingVat;
        
        // Get the year key
        final yearKey = invoice.date.year;
        yearlySpending[yearKey] = (yearlySpending[yearKey] ?? 0) + invoice.amountIncludingVat;
        
        // Get daily spending (for detailed charts)
        final dateKey = DateTime(invoice.date.year, invoice.date.month, invoice.date.day);
        dailySpending[dateKey] = (dailySpending[dateKey] ?? 0) + invoice.amountIncludingVat;
      }

      // Calculate average order value
      final averageOrderValue = invoices.isNotEmpty ? totalSpent / invoices.length : 0;

      // Update state with all the processed data
      if (mounted) {
        setState(() {
          _invoices = invoices;
          _complaints = complaints;
          _totalMeasurements = measurementsCount;
          _totalSpent = totalSpent;
          _averageOrderValue = averageOrderValue.toDouble();
          _outstandingBalance = outstandingBalance;
          _paymentStatusCounts = paymentStatusCounts;
          _monthlySpendings = monthlySpendings;
          _yearlySpending = yearlySpending;
          _dailySpending = dailySpending;
          _isLoading = false;
        });
        
        // Start animations when data is loaded
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading financial data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    
    setState(() {
      _selectedTimePeriod = period;
      
      switch (period) {
        case 'Month':
          _startDate = DateTime(now.year, now.month - 1, now.day);
          _endDate = now;
          break;
        case 'Quarter':
          _startDate = DateTime(now.year, now.month - 3, now.day);
          _endDate = now;
          break;
        case 'Year':
          _startDate = DateTime(now.year - 1, now.month, now.day);
          _endDate = now;
          break;
        case 'All Time':
          // Get the earliest invoice date
          if (_invoices.isNotEmpty) {
            _invoices.sort((a, b) => a.date.compareTo(b.date));
            _startDate = _invoices.first.date;
            _endDate = now;
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.isMobile 
        ? _buildMobileLayout() 
        : _buildDesktopLayout();
  }

  Widget _buildDesktopLayout() {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          _buildHeader(theme),
          
          // Main content area
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _buildReportContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Financial Report',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Add period dropdown in the AppBar
          DropdownButton<String>(
            value: _selectedTimePeriod,
            onChanged: (String? value) {
              if (value != null) {
                _updateDateRange(value);
              }
            },
            items: _timePeriods.map<DropdownMenuItem<String>>(
              (String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: theme.textTheme.bodyMedium),
              )
            ).toList(),
            underline: Container(height: 0),
            dropdownColor: theme.colorScheme.surfaceContainer,
            icon: const Icon(Icons.arrow_drop_down),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        // Add customer name as subtitle
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Container(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            width: double.infinity,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.customer.name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _buildMobileContent(theme),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(
              widget.customer.name[0].toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Report',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                widget.customer.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Report period dropdown selector
          DropdownButton<String>(
            value: _selectedTimePeriod,
            onChanged: (String? value) {
              if (value != null) {
                _updateDateRange(value);
              }
            },
            items: _timePeriods.map<DropdownMenuItem<String>>(
              (String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              )
            ).toList(),
            underline: Container(
              height: 1,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(ThemeData theme) {
    // Use layout builder to check screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final bool isMobileWidth = screenWidth < 700;
        final bool hasInvoices = _invoices.isNotEmpty;
        
        if (isMobileWidth && !widget.isMobile) {
          // If we're in a narrow desktop window, use a layout similar to mobile
          return _buildMobileContent(theme);
        }
        
        // Original desktop layout for wider screens
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Financial Summary Cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      theme,
                      title: 'Total Spent',
                      value: NumberFormatter.formatCurrency(_totalSpent),
                      icon: Icons.account_balance_wallet_outlined,
                      color: theme.colorScheme.primary,
                      subtitle: 'Lifetime Value',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      theme,
                      title: 'Average Order',
                      value: NumberFormatter.formatCurrency(_averageOrderValue),
                      icon: Icons.analytics_outlined,
                      color: theme.colorScheme.secondary,
                      subtitle: 'Per Invoice',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      theme,
                      title: 'Outstanding',
                      value: NumberFormatter.formatCurrency(_outstandingBalance),
                      icon: Icons.payments_outlined,
                      color: _outstandingBalance > 0 ? theme.colorScheme.error : Colors.green,
                      subtitle: 'Due Balance',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      theme, 
                      title: 'Invoices',
                      value: _invoices.length.toString(),
                      icon: Icons.receipt_long_outlined,
                      color: theme.colorScheme.tertiary,
                      subtitle: '${_complaints.length} Complaints',
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0, curve: Curves.easeOutQuad),
              
              const SizedBox(height: 24),
              
              // No data message if there are no invoices
              if (!hasInvoices)
                _buildNoDataMessage(theme)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spending over time chart
                    _buildChartContainer(
                      theme,
                      title: 'Spending Timeline',
                      subtitle: 'Customer spending pattern over time',
                      height: 350,
                      chart: _buildLineChart(theme),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment status and spending breakdown
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Status Breakdown
                        Expanded(
                          flex: 1,
                          child: _buildChartContainer(
                            theme,
                            title: 'Payment Status',
                            subtitle: 'Distribution of invoice payment statuses',
                            height: 400,
                            chart: _buildPieChart(theme),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Monthly spending breakdown
                        Expanded(
                          flex: 2,
                          child: _buildChartContainer(
                            theme,
                            title: 'Monthly Spending',
                            subtitle: 'Total amount spent per month',
                            height: 400,
                            chart: _buildBarChart(theme),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).moveY(begin: 20, end: 0, curve: Curves.easeOutQuad),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Transactions List
                    _buildRecentTransactions(theme),
                  ],
                ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileContent(ThemeData theme) {
    final bool hasInvoices = _invoices.isNotEmpty;
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Summary Cards
            // Show cards in a vertical layout on mobile
            _buildSummaryCard(
              theme,
              title: 'Total Spent',
              value: NumberFormatter.formatCurrency(_totalSpent),
              icon: Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.primary,
              subtitle: 'Lifetime Value',
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              theme,
              title: 'Average Order',
              value: NumberFormatter.formatCurrency(_averageOrderValue),
              icon: Icons.analytics_outlined,
              color: theme.colorScheme.secondary,
              subtitle: 'Per Invoice',
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              theme,
              title: 'Outstanding',
              value: NumberFormatter.formatCurrency(_outstandingBalance),
              icon: Icons.payments_outlined,
              color: _outstandingBalance > 0 ? theme.colorScheme.error : Colors.green,
              subtitle: 'Due Balance',
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              theme, 
              title: 'Invoices',
              value: _invoices.length.toString(),
              icon: Icons.receipt_long_outlined,
              color: theme.colorScheme.tertiary,
              subtitle: '${_complaints.length} Complaints',
            ),
            
            const SizedBox(height: 24),
            
            // No data message if there are no invoices
            if (!hasInvoices)
              _buildNoDataMessage(theme)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Spending over time chart
                  _buildChartContainer(
                    theme,
                    title: 'Spending Timeline',
                    subtitle: 'Customer spending pattern over time',
                    height: 280, // Smaller height on mobile
                    chart: _buildLineChart(theme),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Payment status chart - full width on mobile
                  _buildChartContainer(
                    theme,
                    title: 'Payment Status',
                    subtitle: 'Distribution of invoice payment statuses',
                    height: 300,
                    chart: _buildPieChart(theme),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Monthly spending chart - full width on mobile
                  _buildChartContainer(
                    theme,
                    title: 'Monthly Spending',
                    subtitle: 'Total amount spent per month',
                    height: 300,
                    chart: _buildBarChart(theme),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Transactions List
                  _buildRecentTransactions(theme),
                ],
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    // Check if we're on mobile
    final isMobile = widget.isMobile || MediaQuery.of(context).size.width < 700;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    // Adjust font size on mobile
                    fontSize: isMobile ? 12 : null,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    // Smaller icon on mobile
                    size: isMobile ? 16 : 18,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                height: 1,
                // Adjust font size on mobile
                fontSize: isMobile ? 22 : null,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  // Adjust font size on mobile
                  fontSize: isMobile ? 10 : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildChartContainer(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required double height, 
    required Widget chart,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: chart,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLineChart(ThemeData theme) {
    if (_dailySpending.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    
    // Filter data based on selected date range
    final filteredData = _dailySpending.entries.where(
      (entry) => entry.key.isAfter(_startDate) && entry.key.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();
    
    // Sort by date
    filteredData.sort((a, b) => a.key.compareTo(b.key));
    
    if (filteredData.isEmpty) {
      return const Center(child: Text('No data in selected date range'));
    }
    
    // Find max value for y-axis scaling
    final maxY = filteredData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.1;
    
    // Create spots for the chart
    final spots = filteredData.map((entry) => 
      FlSpot(
        entry.key.millisecondsSinceEpoch.toDouble(), 
        entry.value,
      )
    ).toList();
    
    // Create formatter for horizontal axis
    String getTimeAxisFormat(double value) {
      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
      switch (_selectedTimePeriod) {
        case 'Month':
          return DateFormat.MMMd().format(date); // Apr 6
        case 'Quarter':
          return DateFormat.MMMd().format(date); // Apr 6
        case 'Year':
          return DateFormat.MMM().format(date); // Apr
        case 'All Time':
          return DateFormat.yMMM().format(date); // Apr 2023
        default:
          return DateFormat.yMMMd().format(date); // Apr 6, 2023
      }
    }

    final colorScheme = theme.colorScheme;
    
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                return LineTooltipItem(
                  '${DateFormat.yMMMd().format(date)}\n',
                  TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500),
                  children: [
                    TextSpan(
                      text: NumberFormatter.formatCurrency(touchedSpot.y),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            setState(() {
              if (touchResponse?.lineBarSpots != null && touchResponse!.lineBarSpots!.isNotEmpty) {
                _touchedSpot = touchResponse.lineBarSpots!.first;
              } else {
                _touchedSpot = null;
              }
            });
          },
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withOpacity(0.2),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateDateInterval(filteredData.first.key, filteredData.last.key),
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    getTimeAxisFormat(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    NumberFormatter.formatCompactCurrency(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: filteredData.first.key.millisecondsSinceEpoch.toDouble(),
        maxX: filteredData.last.key.millisecondsSinceEpoch.toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: _touchedSpot != null,
              getDotPainter: (spot, percent, barData, index) {
                if (_touchedSpot != null && _touchedSpot!.x == spot.x && _touchedSpot!.y == spot.y) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: colorScheme.surface,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: colorScheme.primary,
                  strokeWidth: 0,
                  strokeColor: colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.3),
                  colorScheme.primary.withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms, curve: Curves.easeIn);
  }
  
  Widget _buildPieChart(ThemeData theme) {
    if (_paymentStatusCounts.isEmpty) {
      return const Center(child: Text('No payment data available'));
    }
    
    final colorScheme = theme.colorScheme;
    int touchedIndex = -1;
    
    // Define colors for different payment statuses
    final Map<String, Color> statusColors = {
      'paid': Colors.green,
      'partial': Colors.orange,
      'pending': colorScheme.error,
      'cancelled': colorScheme.outline,
    };
    
    // Convert data for pie chart
    final List<PieChartSectionData> sections = _paymentStatusCounts.entries.map((entry) {
      final isTouched = _paymentStatusCounts.keys.toList().indexOf(entry.key) == touchedIndex;
      final color = statusColors[entry.key.toLowerCase()] ?? colorScheme.primary;
      final percentage = entry.value / _invoices.length * 100;
      
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: isTouched ? 80 : 70,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: colorScheme.surface,
        ),
        badgeWidget: isTouched 
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.info_outline, 
                size: 16, 
                color: color,
              ),
            )
          : null,
        badgePositionPercentageOffset: 1.1,
      );
    }).toList();
    
    // Create the legend items
    final List<Widget> legendItems = _paymentStatusCounts.entries.map((entry) {
      final color = statusColors[entry.key.toLowerCase()] ?? colorScheme.primary;
      final formattedStatus = entry.key[0].toUpperCase() + entry.key.substring(1);
      
      return _buildLegendItem(
        theme, 
        color: color, 
        text: '$formattedStatus (${entry.value})',
      );
    }).toList();
    
    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 300.ms, curve: Curves.easeIn),
        ),
        
        // Legend
        Container(
          margin: const EdgeInsets.only(top: 24),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: legendItems,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBarChart(ThemeData theme) {
    if (_monthlySpendings.isEmpty) {
      return const Center(child: Text('No monthly data available'));
    }
    
    // Filter and sort data by month
    final filteredData = _monthlySpendings.entries
      .where((entry) {
        final month = entry.key % 100;
        final year = entry.key ~/ 100;
        final date = DateTime(year, month, 1);
        return date.isAfter(_startDate) && date.isBefore(_endDate.add(const Duration(days: 31)));
      }).toList();

    // Sort the filtered data by month
    filteredData.sort((a, b) => a.key.compareTo(b.key));
    
    if (filteredData.isEmpty) {
      return const Center(child: Text('No data in selected period'));
    }
    
    // Get max value for scaling
    final maxY = filteredData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.1;
    
    final colorScheme = theme.colorScheme;
    
    // Convert month keys to strings
    List<String> getMonthLabels() {
      return filteredData.map((entry) {
        final month = entry.key % 100;
        final year = entry.key ~/ 100;
        
        // Different format based on time period
        if (_selectedTimePeriod == 'All Time' || _selectedTimePeriod == 'Year') {
          return DateFormat('MMM\nyy').format(DateTime(year, month));
        } else {
          return DateFormat('MMM d').format(DateTime(year, month, 1));
        }
      }).toList();
    }
    
    final labels = getMonthLabels();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = filteredData[groupIndex];
              final month = entry.key % 100;
              final year = entry.key ~/ 100;
              return BarTooltipItem(
                '${DateFormat('MMMM yyyy').format(DateTime(year, month))}\n',
                TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: NumberFormatter.formatCurrency(entry.value),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    NumberFormatter.formatCompactCurrency(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withOpacity(0.2),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: filteredData.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value.value;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: colorScheme.primary,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                rodStackItems: [],
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 300.ms, curve: Curves.easeIn);
  }
  
  Widget _buildLegendItem(ThemeData theme, {required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  double _calculateDateInterval(DateTime first, DateTime last) {
    final difference = last.difference(first).inDays;
    
    // Determine interval based on date range
    if (difference <= 7) {
      return 24 * 60 * 60 * 1000; // 1 day interval
    } else if (difference <= 30) {
      return 2 * 24 * 60 * 60 * 1000; // 2 days interval
    } else if (difference <= 90) {
      return 7 * 24 * 60 * 60 * 1000; // 1 week interval
    } else if (difference <= 365) {
      return 30 * 24 * 60 * 60 * 1000; // 1 month interval
    } else {
      return 90 * 24 * 60 * 60 * 1000; // 3 months interval
    }
  }
  
  Widget _buildRecentTransactions(ThemeData theme) {
    if (_invoices.isEmpty) {
      return const SizedBox();
    }
    
    // Take just the most recent 5 invoices
    final recentInvoices = List<Invoice>.from(_invoices)
      ..sort((a, b) => b.date.compareTo(a.date))
      ..take(5);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Latest invoices and payments',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    // View all transactions (could be implemented later)
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentInvoices.length > 5 ? 5 : recentInvoices.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final invoice = recentInvoices[index];
              
              // Determine status color
              Color statusColor;
              if (invoice.paymentStatus == 'paid') {
                statusColor = Colors.green;
              } else if (invoice.paymentStatus == 'partial') {
                statusColor = Colors.orange;
              } else {
                statusColor = theme.colorScheme.error;
              }
              
              return ListTile(
                title: Text(
                  'Invoice #${invoice.invoiceNumber}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  DateFormat.yMMMd().format(invoice.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormatter.formatCurrency(invoice.amountIncludingVat),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, 
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        invoice.paymentStatus.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.receipt_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms, curve: Curves.easeIn);
  }

  Widget _buildNoDataMessage(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 60,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Financial Data Available',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This customer has no invoices yet.\nCreate an invoice to see financial reports.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Create new invoice (implementation would depend on your app structure)
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Invoice'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, curve: Curves.easeIn);
  }
}

/// Extension for NumberFormatter to add compact currency formatting
extension CompactCurrencyFormatter on NumberFormatter {
  static String formatCompactCurrency(double value) {
    if (value < 1000) return NumberFormatter.formatCurrency(value);
    
    if (value < 1000000) {
      return '\$${(value/1000).toStringAsFixed(1)}k';
    }
    
    return '\$${(value/1000000).toStringAsFixed(1)}M';
  }
}
