import 'package:flutter/material.dart';
import '../../utils/number_formatter.dart';
import '../../models/invoice.dart';
import 'dashboard_search.dart';

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
  @override
  void initState() {
    super.initState();
    // Remove keyboard shortcut handler
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openSearch() {
    DashboardSearch.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final _ = size.width < 600;
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
          
          // Updated search bar without keyboard shortcut
          Hero(
            tag: 'search_bar',
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _openSearch,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Search by name or bill number...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
