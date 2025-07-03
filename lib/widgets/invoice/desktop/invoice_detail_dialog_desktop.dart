// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/invoice_product.dart';
import 'add_edit_invoice_desktop_dialog.dart';

class InvoiceDetailDialogDesktop extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback? onInvoiceUpdated;
  final VoidCallback? onInvoiceDeleted;

  const InvoiceDetailDialogDesktop({
    super.key,
    required this.invoice,
    this.onInvoiceUpdated,
    this.onInvoiceDeleted,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> invoice,
    VoidCallback? onInvoiceUpdated,
    VoidCallback? onInvoiceDeleted,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => InvoiceDetailDialogDesktop(
            invoice: invoice,
            onInvoiceUpdated: onInvoiceUpdated,
            onInvoiceDeleted: onInvoiceDeleted,
          ),
    );
  }

  @override
  State<InvoiceDetailDialogDesktop> createState() =>
      _InvoiceDetailDialogDesktopState();
}

class _InvoiceDetailDialogDesktopState
    extends State<InvoiceDetailDialogDesktop> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1100, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          topRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          // Status indicator with invoice icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
            ),
            child: Icon(
              PhosphorIcons.receipt(),
              color: _getStatusColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),

          // Invoice info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Invoice #${widget.invoice['invoice_number']}',
                      style: InventoryDesignConfig.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: InventoryDesignConfig.spacingXS),
                Text(
                  'Customer: ${widget.invoice['customer_name']}',
                  style: InventoryDesignConfig.bodyLarge.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Total amount display
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingL,
              vertical: InventoryDesignConfig.spacingM,
            ),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              border: Border.all(
                color: InventoryDesignConfig.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Amount',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: 'AED ').format(
                    (widget.invoice['amount_including_vat'] as num?)
                            ?.toDouble() ??
                        0.0,
                  ),
                  style: InventoryDesignConfig.headlineMedium.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: InventoryDesignConfig.spacingL),

          // Close button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                child: Icon(
                  PhosphorIcons.x(),
                  size: 20,
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInvoiceDetailsCard(),
                const SizedBox(height: InventoryDesignConfig.spacingXL),
                _buildProductsCard(),
              ],
            ),
          ),

          const SizedBox(width: InventoryDesignConfig.spacingXXL),

          // Right Column
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFinancialSummaryCard(),
                const SizedBox(height: InventoryDesignConfig.spacingXL),
                _buildStatusAndNotesCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailsCard() {
    return _buildCard(
      title: 'Invoice Details',
      icon: PhosphorIcons.info(),
      content: Column(
        children: [
          _buildDetailRow(
            'Invoice Date',
            DateFormat(
              'MMM d, yyyy',
            ).format(DateTime.parse(widget.invoice['date'])),
            PhosphorIcons.calendar(),
          ),
          _buildDetailRow(
            'Delivery Date',
            DateFormat(
              'MMM d, yyyy',
            ).format(DateTime.parse(widget.invoice['delivery_date'])),
            PhosphorIcons.truck(),
          ),
          const Divider(height: InventoryDesignConfig.spacingL),
          _buildDetailRow(
            'Customer Name',
            widget.invoice['customer_name'],
            PhosphorIcons.user(),
          ),
          _buildDetailRow(
            'Customer Phone',
            widget.invoice['customer_phone'],
            PhosphorIcons.phone(),
          ),
          _buildDetailRow(
            'Bill Number',
            widget.invoice['customer_bill_number'],
            PhosphorIcons.receipt(),
          ),
          if (widget.invoice['measurement_name'] != null)
            _buildDetailRow(
              'Measurement',
              widget.invoice['measurement_name'],
              PhosphorIcons.ruler(),
            ),
          if (widget.invoice['details'] != null &&
              widget.invoice['details'].toString().isNotEmpty)
            _buildDetailRow(
              'Order Details',
              widget.invoice['details'],
              PhosphorIcons.notepad(),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsCard() {
    final products =
        (widget.invoice['products'] as List?)
            ?.map((p) => InvoiceProduct.fromJson(p))
            .toList() ??
        [];

    return _buildCard(
      title: 'Products & Services',
      icon: PhosphorIcons.shoppingBag(),
      content:
          products.isEmpty
              ? _buildEmptyProductsState()
              : Column(
                children:
                    products.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      return Column(
                        children: [
                          _buildProductRow(product),
                          if (index < products.length - 1)
                            const Divider(
                              height: InventoryDesignConfig.spacingL,
                            ),
                        ],
                      );
                    }).toList(),
              ),
    );
  }

  Widget _buildEmptyProductsState() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.textTertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
            ),
            child: Icon(
              PhosphorIcons.package(),
              size: 32,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingM),
          Text(
            'No products in this invoice',
            style: InventoryDesignConfig.bodyLarge.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(InvoiceProduct product) {
    final isFabric = product.inventoryType == 'fabric';
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: Row(
        children: [
          // Product icon with color
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  product.description != null && product.description.isNotEmpty
                      ? _parseColor(product.description)
                      : InventoryDesignConfig.primaryColor,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
            ),
            child: Icon(
              isFabric ? PhosphorIcons.scissors() : PhosphorIcons.package(),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: InventoryDesignConfig.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingXS),
                Text(
                  '${product.quantity.toStringAsFixed(isFabric ? 1 : 0)} ${product.unit} × ${NumberFormat.currency(symbol: 'AED ').format(product.unitPrice)}',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Total price
          Text(
            NumberFormat.currency(symbol: 'AED ').format(product.totalPrice),
            style: InventoryDesignConfig.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    final subtotal = (widget.invoice['amount'] as num?)?.toDouble() ?? 0.0;
    final discountAmount =
        (widget.invoice['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final discountType = widget.invoice['discount_type'] ?? 'none';
    final discountValue =
        (widget.invoice['discount_value'] as num?)?.toDouble() ?? 0.0;
    final netTotal = (widget.invoice['net_total'] as num?)?.toDouble() ?? 0.0;
    final vatAmount =
        ((widget.invoice['amount_including_vat'] as num?)?.toDouble() ?? 0.0) -
        netTotal;
    final total =
        (widget.invoice['amount_including_vat'] as num?)?.toDouble() ?? 0.0;

    // Use local variables for advance and balance to allow for overrides.
    var advance = (widget.invoice['advance'] as num?)?.toDouble() ?? 0.0;
    var balance = (widget.invoice['balance'] as num?)?.toDouble() ?? 0.0;
    final paymentStatus = widget.invoice['payment_status'] as String? ?? '';

    // If payment status is 'Paid', ensure advance equals total and balance is zero for display.
    if (paymentStatus.toLowerCase() == 'paid') {
      advance = total;
      balance = 0.0;
    }

    String discountLabel = 'Discount';
    if (discountType == 'percentage') {
      discountLabel = 'Discount (${discountValue.toStringAsFixed(0)}%)';
    } else if (discountType == 'fixed' && discountValue > 0) {
      discountLabel = 'Discount (Fixed)';
    }

    return _buildCard(
      title: 'Financial Summary',
      icon: PhosphorIcons.calculator(),
      content: Column(
        children: [
          _buildFinancialRow('Subtotal', subtotal),
          if (discountAmount > 0)
            _buildFinancialRow(
              discountLabel,
              -discountAmount,
              color: InventoryDesignConfig.successColor,
            ),
          _buildFinancialRow('VAT (5%)', vatAmount),
          const Divider(height: InventoryDesignConfig.spacingL),
          _buildFinancialRow('Grand Total', total, isTotal: true),
          _buildFinancialRow('Advance Paid', -advance),
          const Divider(height: InventoryDesignConfig.spacingL),
          _buildFinancialRow(
            'Balance Due',
            balance,
            isTotal: true,
            color:
                balance > 0
                    ? InventoryDesignConfig.errorColor
                    : InventoryDesignConfig.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndNotesCard() {
    final notes = (widget.invoice['notes'] as List?)?.join('\n');

    return _buildCard(
      title: 'Status & Information',
      icon: PhosphorIcons.info(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Status',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildStatusTag(
                widget.invoice['payment_status'],
                _getPaymentStatusColor(widget.invoice['payment_status']),
              ),
            ],
          ),

          const SizedBox(height: InventoryDesignConfig.spacingM),

          // Delivery Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Status',
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildStatusTag(
                widget.invoice['delivery_status'],
                _getDeliveryStatusColor(widget.invoice['delivery_status']),
              ),
            ],
          ),

          // Notes section
          if (notes != null && notes.isNotEmpty) ...[
            const Divider(height: InventoryDesignConfig.spacingXL),
            Text(
              'Notes',
              style: InventoryDesignConfig.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusS,
                ),
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
              ),
              child: Text(
                notes,
                style: InventoryDesignConfig.bodyMedium.copyWith(height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(InventoryDesignConfig.radiusXL),
          bottomRight: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        border: Border(
          top: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Delete button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () {
                // TODO: Implement delete functionality
              },
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: InventoryDesignConfig.errorColor),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.trash(),
                      size: 16,
                      color: InventoryDesignConfig.errorColor,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      'Delete',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: InventoryDesignConfig.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: InventoryDesignConfig.spacingL),

          // Edit button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                AddEditInvoiceDesktopDialog.show(
                  context,
                  invoice: widget.invoice,
                  onInvoiceSaved: widget.onInvoiceUpdated,
                );
              },
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: InventoryDesignConfig.buttonPrimaryDecoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.pencilSimple(),
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      'Edit Invoice',
                      style: InventoryDesignConfig.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(InventoryDesignConfig.radiusL),
                topRight: Radius.circular(InventoryDesignConfig.radiusL),
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
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: InventoryDesignConfig.primaryColor,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  title,
                  style: InventoryDesignConfig.titleMedium.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: InventoryDesignConfig.spacingS,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: InventoryDesignConfig.textSecondary),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: InventoryDesignConfig.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    double value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: InventoryDesignConfig.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isTotal
                    ? InventoryDesignConfig.titleMedium
                    : InventoryDesignConfig.bodyMedium)
                .copyWith(
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
          ),
          Text(
            NumberFormat.currency(symbol: 'AED ').format(value),
            style: (isTotal
                    ? InventoryDesignConfig.titleMedium
                    : InventoryDesignConfig.bodyMedium)
                .copyWith(
                  fontWeight: FontWeight.w700,
                  color: color ?? InventoryDesignConfig.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isDelivered = widget.invoice['delivery_status'] == 'Delivered';
    final isPaid = widget.invoice['payment_status'] == 'Paid';

    if (isDelivered && isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: InventoryDesignConfig.spacingM,
          vertical: InventoryDesignConfig.spacingXS,
        ),
        decoration: BoxDecoration(
          color: InventoryDesignConfig.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          border: Border.all(
            color: InventoryDesignConfig.successColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          'Completed',
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.successColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: InventoryDesignConfig.spacingM,
          vertical: InventoryDesignConfig.spacingXS,
        ),
        decoration: BoxDecoration(
          color: InventoryDesignConfig.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          border: Border.all(
            color: InventoryDesignConfig.warningColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          'In Progress',
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.warningColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  Widget _buildStatusTag(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: InventoryDesignConfig.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper methods
  Color _getStatusColor() {
    final isDelivered = widget.invoice['delivery_status'] == 'Delivered';
    final isPaid = widget.invoice['payment_status'] == 'Paid';

    if (isDelivered && isPaid) {
      return InventoryDesignConfig.successColor;
    } else {
      return InventoryDesignConfig.warningColor;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return InventoryDesignConfig.successColor;
      case 'partially paid':
        return InventoryDesignConfig.warningColor;
      case 'pending':
        return InventoryDesignConfig.errorColor;
      case 'refunded':
        return InventoryDesignConfig.textSecondary;
      default:
        return InventoryDesignConfig.textTertiary;
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return InventoryDesignConfig.successColor;
      case 'processing':
      case 'ready for pickup':
      case 'out for delivery':
        return InventoryDesignConfig.warningColor;
      case 'pending':
        return InventoryDesignConfig.errorColor;
      default:
        return InventoryDesignConfig.textTertiary;
    }
  }

  Color _parseColor(String colorCode) {
    if (colorCode.isEmpty) return InventoryDesignConfig.primaryColor;
    try {
      if (colorCode.startsWith('#')) {
        String hex = colorCode.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        }
      }
      return InventoryDesignConfig.primaryColor;
    } catch (e) {
      return InventoryDesignConfig.primaryColor;
    }
  }
}
