import 'package:flutter/material.dart';
import '../../utils/number_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../models/measurement.dart';
import '../../models/complaint.dart';
import '../../services/customer_service.dart';
import '../../services/measurement_service.dart';
import '../../services/invoice_service.dart';
import '../../services/complaint_service.dart';
import 'customer_search_dialog.dart';
import 'desktop_customer_search_dialog.dart'; // Add this import

class DashboardHeader extends StatefulWidget {
  final List<Invoice> invoices;
  final VoidCallback onRefresh;
  final bool isMobile;

  const DashboardHeader({
    super.key,
    required this.invoices,
    required this.onRefresh,
    this.isMobile = false,
  });

  @override
  _DashboardHeaderState createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _handleSearch() async {
    final billNumber = _searchController.text;
    if (billNumber.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final customerService = CustomerService(Supabase.instance.client);
      final customer = await customerService.getCustomerByBillNumber(billNumber);
      
      if (customer.id.isEmpty) {
        _showError('No customer found with bill number: $billNumber');
        return;
      }

      // Fetch related data
      final measurementService = MeasurementService();
      final invoiceService = InvoiceService();
      final complaintService = ComplaintService(Supabase.instance.client);

      final measurements = await measurementService.getMeasurementsByCustomerId(customer.id);
      final invoices = await invoiceService.getInvoicesByCustomerId(customer.id);
      final complaints = await complaintService.getComplaintsByCustomerId(customer.id);

      // Show customer dialog with fetched data
      if (context.mounted) {
        _showCustomerDialog(
          context,
          customer,
          measurements, // Ensure we have an empty list if null
          invoices,     // Ensure we have an empty list if null
          complaints,   // Ensure we have an empty list if null
        );
      }
    } catch (e) {
      _showError('Error searching for customer: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    setState(() {
      _isSearching = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showCustomerDialog(
    BuildContext context,
    Customer customer,
    List<Measurement> measurements,
    List<Invoice> invoices,
    List<Complaint> complaints,
  ) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isDesktop = size.width >= 1024;

    if (isDesktop) {
      // Use the new desktop dialog for desktop screens
      DesktopCustomerSearchDialog.show(
        context,
        customer: customer,
        measurements: measurements,
        invoices: invoices,
        complaints: complaints,
      );
    } else if (isMobile) {
      // Full screen dialog for mobile
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CustomerSearchDialog(
            customer: customer,
            measurements: measurements,
            invoices: invoices,
            complaints: complaints,
            isFullScreen: true,
          ),
        ),
      );
    } else {
      // Regular dialog for tablets
      showDialog(
        context: context,
        builder: (context) => CustomerSearchDialog(
          customer: customer,
          measurements: measurements,
          invoices: invoices,
          complaints: complaints,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final totalRevenue = widget.invoices.fold(
      0.0,
      (sum, inv) => sum + inv.amountIncludingVat,
    );
    final pendingOrders =
        widget.invoices
            .where((inv) => inv.deliveryStatus == InvoiceStatus.pending)
            .length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: widget.isMobile ? 16 : 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dashboard Overview',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _AnimatedRefreshButton(onRefresh: widget.onRefresh),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search by customer bill number',
                hintStyle: TextStyle(color: Colors.black45),
                prefixIcon: Icon(Icons.search, color: Colors.black45),
                suffixIcon: _isSearching
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(6),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black45),
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.arrow_forward, color: Colors.black45),
                        onPressed: _handleSearch,
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              onSubmitted: (_) => _handleSearch(),
            ),
          ),
          if (!widget.isMobile) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                _QuickStat(
                  label: 'Total Revenue',
                  value: NumberFormatter.formatCurrency(totalRevenue),
                  icon: Icons.trending_up,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 32),
                _QuickStat(
                  label: 'Pending Orders',
                  value: pendingOrders.toString(),
                  icon: Icons.pending_actions,
                  color: Colors.orangeAccent,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                  },
                  icon: const Icon(Icons.summarize),
                  label: const Text('Generate Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _AnimatedRefreshButton extends StatefulWidget {
  final VoidCallback onRefresh;

  const _AnimatedRefreshButton({required this.onRefresh});

  @override
  State<_AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<_AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    _controller.repeat();
    widget.onRefresh();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _controller.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _handleRefresh,
      icon: RotationTransition(
        turns: _controller,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
