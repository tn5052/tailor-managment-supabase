import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../theme/inventory_design_config.dart';

class InvoiceDetailMobileSheet extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback? onInvoiceUpdated;
  final VoidCallback? onInvoiceDeleted;

  const InvoiceDetailMobileSheet({
    Key? key,
    required this.invoice,
    this.onInvoiceUpdated,
    this.onInvoiceDeleted,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> invoice,
    VoidCallback? onInvoiceUpdated,
    VoidCallback? onInvoiceDeleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => InvoiceDetailMobileSheet(
        invoice: invoice,
        onInvoiceUpdated: onInvoiceUpdated,
        onInvoiceDeleted: onInvoiceDeleted,
      ),
    );
  }

  @override
  State<InvoiceDetailMobileSheet> createState() =>
      _InvoiceDetailMobileSheetState();
}

class _InvoiceDetailMobileSheetState extends State<InvoiceDetailMobileSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sheetAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _sheetAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.4 * _sheetAnimation.value),
          body: GestureDetector(
            onTap: _handleClose,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: screenHeight * 0.92,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (screenHeight * 0.92) * (1 - _sheetAnimation.value),
                    ),
                    child: _buildSheetContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetContent() {
    return Container(
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final invoiceNumber = widget.invoice['invoice_number'] ?? 'N/A';
    final customerName = widget.invoice['customer_name'] ?? 'No Customer';

    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(
              top: InventoryDesignConfig.spacingM,
              bottom: InventoryDesignConfig.spacingS,
            ),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingS,
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingL,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                  ),
                  child: Icon(
                    PhosphorIcons.receipt(),
                    color: InventoryDesignConfig.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice #$invoiceNumber',
                        style: InventoryDesignConfig.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        customerName,
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHeaderActionButton(
                  icon: PhosphorIcons.x(),
                  onTap: _handleClose,
                  semanticLabel: 'Close details',
                ),
              ],
            ),
          ),
          Container(height: 1, color: InventoryDesignConfig.borderSecondary),
        ],
      ),
    );
  }
  
  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsSection(),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          _buildInformationSection(),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          _buildPricingSection(),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    final amount = (widget.invoice['amount_including_vat'] ?? 0.0) as double;
    final balance = (widget.invoice['balance'] ?? 0.0) as double;
    final paymentStatus = widget.invoice['payment_status'] ?? 'Pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: InventoryDesignConfig.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Amount',
                value: NumberFormat.currency(symbol: '\$').format(amount),
                icon: PhosphorIcons.currencyDollar(),
                color: InventoryDesignConfig.primaryColor,
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildMetricCard(
                title: 'Balance Due',
                value: NumberFormat.currency(symbol: '\$').format(balance),
                icon: PhosphorIcons.wallet(),
                color: balance > 0
                    ? InventoryDesignConfig.errorColor
                    : InventoryDesignConfig.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingM),
        _buildMetricCard(
          title: 'Payment Status',
          value: paymentStatus,
          icon: _getPaymentStatusIcon(paymentStatus),
          color: _getPaymentStatusColor(paymentStatus),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                title,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          Text(
            value,
            style: InventoryDesignConfig.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection() {
    return _buildSection(
      title: 'Invoice Information',
      icon: PhosphorIcons.info(),
      children: [
        _buildDetailRow(
          'Customer Phone',
          widget.invoice['customer_phone'],
          icon: PhosphorIcons.phone(),
        ),
        _buildDetailRow(
          'Invoice Date',
          _formatDate(widget.invoice['date']),
          icon: PhosphorIcons.calendar(),
        ),
        _buildDetailRow(
          'Delivery Date',
          _formatDate(widget.invoice['delivery_date']),
          icon: PhosphorIcons.package(),
        ),
        _buildDetailRow(
          'Delivery Status',
          widget.invoice['delivery_status'],
          icon: _getDeliveryStatusIcon(widget.invoice['delivery_status']),
          statusColor: _getDeliveryStatusColor(widget.invoice['delivery_status']),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    final amount = (widget.invoice['amount'] ?? 0.0) as double;
    final vat = (widget.invoice['vat'] ?? 0.0) as double;
    final total = (widget.invoice['amount_including_vat'] ?? 0.0) as double;
    final advance = (widget.invoice['advance'] ?? 0.0) as double;

    return _buildSection(
      title: 'Pricing Details',
      icon: PhosphorIcons.currencyDollar(),
      children: [
        _buildDetailRow(
          'Subtotal',
          NumberFormat.currency(symbol: '\$').format(amount),
          icon: PhosphorIcons.coins(),
        ),
        _buildDetailRow(
          'VAT (5%)',
          NumberFormat.currency(symbol: '\$').format(vat),
          icon: PhosphorIcons.percent(),
        ),
        _buildDetailRow(
          'Total Amount',
          NumberFormat.currency(symbol: '\$').format(total),
          icon: PhosphorIcons.stack(),
        ),
        _buildDetailRow(
          'Advance Paid',
          NumberFormat.currency(symbol: '\$').format(advance),
          icon: PhosphorIcons.handCoins(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
              ),
              child: Icon(icon, size: 16, color: InventoryDesignConfig.primaryColor),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Text(
              title,
              style: InventoryDesignConfig.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        Container(
          decoration: InventoryDesignConfig.cardDecoration,
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Container(
                      height: 1,
                      color: InventoryDesignConfig.borderSecondary,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String? value, {
    IconData? icon,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: statusColor ?? InventoryDesignConfig.textSecondary,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: InventoryDesignConfig.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: statusColor ?? InventoryDesignConfig.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingXL + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          top: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Edit Invoice',
              icon: PhosphorIcons.pencilSimple(),
              color: InventoryDesignConfig.primaryColor,
              onTap: () {
                // This would typically pop and then call the edit sheet
                Navigator.of(context).pop();
                widget.onInvoiceUpdated?.call();
              },
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: _buildActionButton(
              label: 'Delete',
              icon: PhosphorIcons.trash(),
              color: InventoryDesignConfig.errorColor,
              onTap: () {
                Navigator.of(context).pop();
                widget.onInvoiceDeleted?.call();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: InventoryDesignConfig.spacingL,
            horizontal: InventoryDesignConfig.spacingM,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return InventoryDesignConfig.successColor;
      case 'Partially Paid':
        return InventoryDesignConfig.warningColor;
      case 'Unpaid':
      default:
        return InventoryDesignConfig.errorColor;
    }
  }
  
  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'Paid':
        return PhosphorIcons.checkCircle();
      case 'Partially Paid':
        return PhosphorIcons.hourglass();
      case 'Unpaid':
      default:
        return PhosphorIcons.xCircle();
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return InventoryDesignConfig.successColor;
      case 'Processing':
        return InventoryDesignConfig.infoColor;
      case 'Pending':
      default:
        return InventoryDesignConfig.warningColor;
    }
  }

  IconData _getDeliveryStatusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return PhosphorIcons.package();
      case 'Processing':
        return PhosphorIcons.arrowsClockwise();
      case 'Pending':
      default:
        return PhosphorIcons.timer();
    }
  }
}
