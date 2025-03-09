import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/measurement.dart';
import '../../models/complaint.dart';
import '../../utils/number_formatter.dart';

class CustomerInsightsReport extends StatelessWidget {
  final Customer customer;
  final List<Measurement> measurements;
  final List<Invoice> invoices;
  final List<Complaint> complaints;

  const CustomerInsightsReport({
    super.key,
    required this.customer,
    required this.measurements,
    required this.invoices,
    required this.complaints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left sidebar with menu
                  _buildSidebar(context),
                  
                  // Main content area with scrolling
                  Expanded(
                    flex: 4,
                    child: DefaultTabController(
                      length: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              border: Border(
                                bottom: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                            ),
                            child: TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              tabs: const [
                                Tab(text: 'Summary'),
                                Tab(text: 'Orders'),
                                Tab(text: 'Measurements'),
                                Tab(text: 'Financial'),
                                Tab(text: 'Support History'),
                              ],
                              labelColor: theme.colorScheme.primary,
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildSummaryTab(context),
                                _buildOrdersTab(context),
                                _buildMeasurementsTab(context),
                                _buildFinancialTab(context),
                                _buildSupportTab(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha((theme.colorScheme.primary.alpha * 0.8).toInt()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Insights Report',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  customer.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                'Generated: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = invoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);
    final totalBalance = invoices.fold(0.0, (sum, inv) => sum + inv.balance);
    final customerSince = DateFormat('MMM d, yyyy').format(customer.createdAt);
    
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Profile',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: theme.colorScheme.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Bill Number', customer.billNumber),
                  const SizedBox(height: 8),
                  _buildInfoRow('Customer Since', customerSince),
                  const SizedBox(height: 8),
                  _buildInfoRow('Phone', customer.phone),
                  if (customer.whatsapp.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('WhatsApp', customer.whatsapp),
                  ],
                  const SizedBox(height: 8),
                  _buildInfoRow('Gender', customer.gender.toString().split('.').last),
                  const SizedBox(height: 8),
                  _buildInfoRow('Address', customer.address, maxLines: 2),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildOverviewStat('Total Orders', '${invoices.length}', Icons.receipt_long, Colors.blue),
          _buildOverviewStat('Total Spent', NumberFormatter.formatCurrency(totalSpent), Icons.monetization_on, Colors.green),
          _buildOverviewStat('Outstanding Balance', NumberFormatter.formatCurrency(totalBalance), Icons.account_balance_wallet, Colors.orange),
          _buildOverviewStat('Measurements', '${measurements.length}', Icons.straighten, Colors.purple),
          _buildOverviewStat('Complaints', '${complaints.length}', Icons.warning_amber, Colors.red),
          
          const Spacer(),
          
          // Print button
          OutlinedButton.icon(
            onPressed: () {
              // Printing functionality would be added here
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Report'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab(BuildContext context) {
    final theme = Theme.of(context);
    final lastOrder = invoices.isNotEmpty 
        ? invoices.reduce((a, b) => a.date.isAfter(b.date) ? a : b) 
        : null;
    final lastMeasurement = measurements.isNotEmpty 
        ? measurements.reduce((a, b) => a.date.isAfter(b.date) ? a : b) 
        : null;
    
    // Calculate average order and other statistics
    final totalSpent = invoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);
    final avgOrderValue = invoices.isNotEmpty ? totalSpent / invoices.length : 0.0;
    final ordersThisYear = invoices.where(
      (inv) => inv.date.year == DateTime.now().year
    ).length;
    final pendingDeliveries = invoices.where(
      (inv) => !inv.isDelivered && inv.deliveryDate.isAfter(DateTime.now())
    ).length;
    final overdueDeliveries = invoices.where(
      (inv) => !inv.isDelivered && inv.deliveryDate.isBefore(DateTime.now())
    ).length;
    
    // Calculate customer lifetime (in days) and activity stats
    final daysSinceJoined = DateTime.now().difference(customer.createdAt).inDays;
    final ordersPerMonth = daysSinceJoined > 30 
        ? (invoices.length / (daysSinceJoined / 30)).toStringAsFixed(1)
        : invoices.length.toString();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Summary',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'An overview of customer activity and key performance indicators',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // KPI cards in a row
          Row(
            children: [
              Expanded(child: _buildKpiCard(context, 'Lifetime Value', NumberFormatter.formatCurrency(totalSpent), trend: '+12%', isPositive: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard(context, 'Average Order', NumberFormatter.formatCurrency(avgOrderValue), trend: '-3%', isPositive: false)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard(context, 'Orders This Year', '$ordersThisYear', trend: '+5%', isPositive: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard(context, 'Orders Per Month', ordersPerMonth, subtext: 'Average')),
            ],
          ),
          
          const SizedBox(height: 32),
          // Activity summary
          Text(
            'Activity Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent activity column
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Activity',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            
                            // Last order
                            if (lastOrder != null)
                              _buildTimelineItem(
                                context,
                                date: lastOrder.date,
                                title: 'Order Placed',
                                description: 'Invoice #${lastOrder.invoiceNumber} • ${NumberFormatter.formatCurrency(lastOrder.amountIncludingVat)}',
                                icon: Icons.receipt_long,
                                color: Colors.blue,
                              )
                            else
                              _buildEmptyTimelineItem(context, 'No orders placed yet'),
                              
                            // Last measurement
                            if (lastMeasurement != null)
                              _buildTimelineItem(
                                context,
                                date: lastMeasurement.date,
                                title: 'Measurement Taken',
                                description: 'Style: ${lastMeasurement.style} • Design: ${lastMeasurement.designType}',
                                icon: Icons.straighten,
                                color: Colors.purple,
                              )
                            else
                              _buildEmptyTimelineItem(context, 'No measurements taken yet'),
                            
                            // Last complaint if any
                            if (complaints.isNotEmpty)
                              _buildTimelineItem(
                                context,
                                date: complaints.first.createdAt,
                                title: 'Complaint Filed',
                                description: complaints.first.title,
                                icon: Icons.warning_amber,
                                color: Colors.red,
                                isLast: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Delivery status
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Status',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildStatusRow('Pending Delivery', '$pendingDeliveries', Colors.orange),
                            const SizedBox(height: 8),
                            _buildStatusRow('Overdue Delivery', '$overdueDeliveries', Colors.red),
                            const SizedBox(height: 8),
                            _buildStatusRow('Completed Delivery', '${invoices.where((inv) => inv.isDelivered).length}', Colors.green),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 24),
              
              // Purchase history chart column
              Expanded(
                flex: 4,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Purchase History',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: _buildPurchaseHistoryChart(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrdersTab(BuildContext context) {
    final theme = Theme.of(context);
    
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found for this customer',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }
    
    // Sort invoices by date, newest first
    final sortedInvoices = [...invoices]..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order History',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete order history with delivery and payment status',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Order statistics cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Orders',
                  '${invoices.length}',
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Pending Orders',
                  '${invoices.where((inv) => inv.deliveryStatus == InvoiceStatus.pending).length}',
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Completed Orders',
                  '${invoices.where((inv) => inv.isDelivered).length}',
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Orders table
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Expanded(flex: 1, child: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Delivery Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Delivery Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const Divider(height: 24),
                  ...sortedInvoices.map((invoice) => _buildOrderRow(context, invoice)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMeasurementsTab(BuildContext context) {
    final theme = Theme.of(context);
    
    if (measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.straighten,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No measurements found for this customer',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }
    
    // Sort measurements by date, newest first
    final sortedMeasurements = [...measurements]..sort((a, b) => b.date.compareTo(a.date));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measurement History',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All measurements taken for this customer with details',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Measurement cards grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: sortedMeasurements.length,
            itemBuilder: (context, index) {
              final measurement = sortedMeasurements[index];
              return _buildMeasurementCard(context, measurement);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinancialTab(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = invoices.fold(0.0, (sum, inv) => sum + inv.amountIncludingVat);
    final totalAdvance = invoices.fold(0.0, (sum, inv) => sum + inv.advance);
    final totalBalance = invoices.fold(0.0, (sum, inv) => sum + inv.balance);
    final totalRefunds = invoices.fold(0.0, (sum, inv) => sum + (inv.refundAmount ?? 0.0));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment history, balances, and financial metrics',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Financial summary cards
          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(context, 'Total Spent', NumberFormatter.formatCurrency(totalSpent), Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFinancialCard(context, 'Total Advanced', NumberFormatter.formatCurrency(totalAdvance), Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFinancialCard(context, 'Outstanding Balance', NumberFormatter.formatCurrency(totalBalance), Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFinancialCard(context, 'Total Refunds', NumberFormatter.formatCurrency(totalRefunds), Colors.red),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Payment distribution chart
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Distribution',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: _buildPaymentDistributionChart(context),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment history table
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment History',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Table headers
                  Row(
                    children: const [
                      Expanded(flex: 1, child: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Advance', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  if (invoices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No payment history available')),
                    )
                  else
                    ...invoices.map((invoice) => _buildPaymentHistoryRow(context, invoice)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSupportTab(BuildContext context) {
    final theme = Theme.of(context);
    
    if (complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.support_agent,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No support history found for this customer',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }
    
    // Sort complaints by date, newest first
    final sortedComplaints = [...complaints]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support History',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customer complaints and support interactions',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Complaints summary cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Complaints',
                  '${complaints.length}',
                  Icons.warning_amber,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Pending',
                  '${complaints.where((c) => c.status == "pending").length}',
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Resolved',
                  '${complaints.where((c) => c.status == "resolved").length}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Complaints table
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complaints History',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Table headers
                  Row(
                    children: const [
                      Expanded(flex: 3, child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Refund', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  ...sortedComplaints.map((complaint) => _buildComplaintRow(context, complaint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, {String? trend, bool isPositive = true, String? subtext}) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isPositive ? Colors.green : Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          trend,
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (subtext != null) ...[
              const SizedBox(height: 4),
              Text(
                subtext,
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required DateTime date,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: theme.dividerColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTimelineItem(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseHistoryChart(BuildContext context) {
    final theme = Theme.of(context);
    
    // Group invoices by month
    final groupedData = <DateTime, double>{};
    
    // Get the last 12 months
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      groupedData[month] = 0;
    }
    
    // Fill in the data
    for (final invoice in invoices) {
      final month = DateTime(invoice.date.year, invoice.date.month, 1);
      if (groupedData.containsKey(month)) {
        groupedData[month] = (groupedData[month] ?? 0) + invoice.amountIncludingVat;
      }
    }
    
    // Convert to list and sort
    final sortedEntries = groupedData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    // Convert to bar chart data
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              color: Theme.of(context).colorScheme.primary,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedEntries.length) {
                  final date = sortedEntries[index].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM').format(date),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormatter.formatCompactCurrency(value),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                );
              },
              reservedSize: 50,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1000,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(BuildContext context, Invoice invoice) {
    final theme = Theme.of(context);
    
    Color getStatusColor(String status) {
      switch (status) {
        case 'pending':
          return Colors.orange;
        case 'delivered':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }
    
    Color getPaymentStatusColor(String status) {
      switch (status) {
        case 'paid':
          return Colors.green;
        case 'pending':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text('#${invoice.invoiceNumber}'),
          ),
          Expanded(
            flex: 1,
            child: Text(DateFormat('MMM d, yyyy').format(invoice.date)),
          ),
          Expanded(
            flex: 1,
            child: Text(NumberFormatter.formatCurrency(invoice.amountIncludingVat)),
          ),
          Expanded(
            flex: 1,
            child: Text(DateFormat('MMM d, yyyy').format(invoice.deliveryDate)),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: getStatusColor(invoice.deliveryStatus.toString()),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(invoice.deliveryStatus.toString()),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: getPaymentStatusColor(invoice.paymentStatus.toString()),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(invoice.paymentStatus.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(BuildContext context, Measurement measurement) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  measurement.style,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy').format(measurement.date),
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMeasurementRow('Design', measurement.designType),
                  _buildMeasurementRow('Fabric', measurement.fabricName),
                  _buildMeasurementRow('Length', '${measurement.lengthArabi} (Arabi)'),
                  _buildMeasurementRow('Chest', '${measurement.chest}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard(
    BuildContext context,
    String title,
    String amount,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDistributionChart(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate payment distribution
    double totalAdvanced = 0;
    double totalBalancePaid = 0;
    double totalOutstanding = 0;
    
    for (final invoice in invoices) {
      totalAdvanced += invoice.advance;
      if (invoice.paymentStatus == 'paid') {
        totalBalancePaid += invoice.amountIncludingVat - invoice.advance;
      } else {
        totalOutstanding += invoice.balance;
      }
    }
    
    final sections = <PieChartSectionData>[];
    
    if (totalAdvanced > 0 || totalBalancePaid > 0 || totalOutstanding > 0) {
      if (totalAdvanced > 0) {
        sections.add(PieChartSectionData(
          value: totalAdvanced,
          title: 'Advance',
          color: Colors.blue,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ));
      }
      
      if (totalBalancePaid > 0) {
        sections.add(PieChartSectionData(
          value: totalBalancePaid,
          title: 'Balance Paid',
          color: Colors.green,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ));
      }
      
      if (totalOutstanding > 0) {
        sections.add(PieChartSectionData(
          value: totalOutstanding,
          title: 'Outstanding',
          color: Colors.orange,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ));
      }
    } else {
      sections.add(PieChartSectionData(
        value: 1,
        title: 'No Data',
        color: Colors.grey.shade300,
        radius: 100,
        titleStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ));
    }
    
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 50,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context, 'Advance Payments', NumberFormatter.formatCurrency(totalAdvanced), Colors.blue),
              const SizedBox(height: 16),
              _buildLegendItem(context, 'Balance Payments', NumberFormatter.formatCurrency(totalBalancePaid), Colors.green),
              const SizedBox(height: 16),
              _buildLegendItem(context, 'Outstanding Balance', NumberFormatter.formatCurrency(totalOutstanding), Colors.orange),
              const SizedBox(height: 24),
              _buildLegendItem(
                context, 
                'Total Value', 
                NumberFormatter.formatCurrency(totalAdvanced + totalBalancePaid + totalOutstanding), 
                theme.colorScheme.primary
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, String amount, Color color) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                amount,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryRow(BuildContext context, Invoice invoice) {
    final theme = Theme.of(context);
    Color statusColor;
    
    switch (invoice.paymentStatus) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text('#${invoice.invoiceNumber}'),
          ),
          Expanded(
            flex: 1,
            child: Text(DateFormat('MMM d, yyyy').format(invoice.date)),
          ),
          Expanded(
            flex: 1,
            child: Text(NumberFormatter.formatCurrency(invoice.amountIncludingVat)),
          ),
          Expanded(
            flex: 1,
            child: Text(NumberFormatter.formatCurrency(invoice.advance)),
          ),
          Expanded(
            flex: 1,
            child: Text(NumberFormatter.formatCurrency(invoice.balance)),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                invoice.paymentStatus.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintRow(BuildContext context, Complaint complaint) {
    final theme = Theme.of(context);
    
    Color getStatusColor(String status) {
      switch (status) {
        case 'pending':
          return Colors.orange;
        case 'resolved':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }
    
    Color getPriorityColor(String priority) {
      switch (priority) {
        case 'high':
          return Colors.red;
        case 'medium':
          return Colors.orange;
        case 'low':
          return Colors.green;
        default:
          return Colors.blue;
      }
    }
    
    final hasRefund = complaint.refundAmount != null && complaint.refundAmount! > 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              complaint.title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(DateFormat('MMM d, yyyy').format(complaint.createdAt)),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getStatusColor(complaint.status.toString()).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                complaint.status.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: getStatusColor(complaint.status.toString()),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getPriorityColor(complaint.priority.toString()).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                complaint.priority.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: getPriorityColor(complaint.priority.toString()),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: hasRefund
              ? Text(
                  NumberFormatter.formatCurrency(complaint.refundAmount!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : const Text('-'),
          ),
        ],
      ),
    );
  }
}
