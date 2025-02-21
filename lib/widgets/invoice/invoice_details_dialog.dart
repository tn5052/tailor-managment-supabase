import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import 'pdf_preview_widget.dart';
import '../measurement/detail_dialog.dart';
import '../../services/measurement_service.dart';

class InvoiceDetailsDialog extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailsDialog({super.key, required this.invoice});

  // Add static show method
  static Future<void> show(BuildContext context, Invoice invoice) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 800,
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: InvoiceDetailsDialog(invoice: invoice),
          ),
        ),
      );
    }

    // Full screen for mobile
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => InvoiceDetailsDialog(invoice: invoice),
      ),
    );
  }

  @override
  State<InvoiceDetailsDialog> createState() => _InvoiceDetailsDialogState();
}

class _InvoiceDetailsDialogState extends State<InvoiceDetailsDialog> {
  final _noteController = TextEditingController();
  final _invoiceService = InvoiceService();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '');

    return isDesktop 
      ? Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 800,
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: _buildContent(theme, isDesktop, dateFormat, currencyFormat),
          ),
        )
      : Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.colorScheme.primaryContainer,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice #${widget.invoice.invoiceNumber}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Bill #${widget.invoice.customerBillNumber}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          body: _buildContent(theme, isDesktop, dateFormat, currencyFormat),
        );
  }

  Widget _buildContent(
    ThemeData theme,
    bool isDesktop,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
  ) {
    return Column(
      children: [
        if (isDesktop) _buildHeader(theme),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildMainInfo(
                          theme,
                          dateFormat,
                          currencyFormat,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: _buildStatusSection(theme)),
                    ],
                  )
                else ...[
                  _buildMainInfo(theme, dateFormat, currencyFormat),
                  const SizedBox(height: 24),
                  _buildStatusSection(theme),
                ],
                const SizedBox(height: 24),
                _buildNotesSection(theme),
              ],
            ),
          ),
        ),
        _buildGenerateButton(theme, isDesktop),
      ],
    );
  }

  Widget _buildGenerateButton(ThemeData theme, bool isDesktop) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        isDesktop ? 24 : 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: isDesktop 
          ? const BorderRadius.vertical(bottom: Radius.circular(28))
          : null,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isDesktop 
          ? const BorderRadius.vertical(bottom: Radius.circular(28))
          : BorderRadius.zero,
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: () => _showInvoicePreview(context),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Generate Invoice'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: theme.colorScheme.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice #${widget.invoice.invoiceNumber}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Bill #${widget.invoice.customerBillNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(
                      0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfo(
    ThemeData theme,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
  ) {
    return Column(
      children: [
        // Customer Card
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(widget.invoice.customerName),
                  subtitle: Text(
                    'Bill #${widget.invoice.customerBillNumber} • ${widget.invoice.customerPhone}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(),
                _buildInfoRow(
                  'Date:',
                  dateFormat.format(widget.invoice.date),
                  theme,
                ),
                _buildInfoRow(
                  'Delivery:',
                  dateFormat.format(widget.invoice.deliveryDate),
                  theme,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Products Card (if products exist)
        if (widget.invoice.products.isNotEmpty)
          Card(
            elevation: 0,
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Products',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        'Total: ${currencyFormat.format(widget.invoice.calculateProductsTotal())}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.invoice.products.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = widget.invoice.products[index];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text(
                          product.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        trailing: Text(
                          currencyFormat.format(product.price),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Totals Card
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  'Amount:',
                  currencyFormat.format(widget.invoice.amount),
                  theme,
                ),
                _buildInfoRow(
                  'VAT (5%):',
                  currencyFormat.format(widget.invoice.vat),
                  theme,
                ),
                const Divider(),
                _buildInfoRow(
                  'Total:',
                  currencyFormat.format(widget.invoice.amountIncludingVat),
                  theme,
                  isBold: true,
                ),
                if (widget.invoice.advance > 0) ...[
                  _buildInfoRow(
                    'Advance:',
                    currencyFormat.format(widget.invoice.advance),
                    theme,
                  ),
                  _buildInfoRow(
                    'Balance:',
                    currencyFormat.format(widget.invoice.remainingBalance),
                    theme,
                    isBold: true,
                    color: widget.invoice.remainingBalance > 0
                        ? Colors.red
                        : Colors.green,
                  ),
                ],
              ],
            ),
          ),
        ),

        if (widget.invoice.measurementName != null) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListTile(
              leading: Icon(Icons.straighten, color: theme.colorScheme.primary),
              title: Text('Measurement'),
              subtitle: Text(
              widget.invoice.measurementName!,
              style: TextStyle(color: theme.colorScheme.primary),
              ),
              trailing: FilledButton.icon(
              onPressed: () => _viewMeasurementDetails(context),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View Details'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(120, 40),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                ),
              ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              theme,
              'Delivery Status',
              widget.invoice.deliveryStatus,
              widget.invoice.deliveredAt != null
                  ? DateFormat(
                    'MMM dd, yyyy',
                  ).format(widget.invoice.deliveredAt!)
                  : null,
              onUpdate: _updateDeliveryStatus,
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              theme,
              'Payment Status',
              widget.invoice.paymentStatus,
              widget.invoice.paidAt != null
                  ? DateFormat('MMM dd, yyyy').format(widget.invoice.paidAt!)
                  : null,
              onUpdate: _updatePaymentStatus,
            ),
            if (widget.invoice.remainingBalance > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton.icon(
                  onPressed: _handlePayment,
                  icon: const Icon(Icons.payments),
                  label: Text(
                    'Add Payment (${NumberFormat.currency(symbol: '').format(widget.invoice.remainingBalance)})',
                  ),
                ),
              ),
            if (widget.invoice.paymentStatus == PaymentStatus.paid &&
                !widget.invoice.isRefunded)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton.icon(
                  onPressed: _handleRefund,
                  icon: const Icon(Icons.currency_exchange),
                  label: const Text('Process Refund'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            if (widget.invoice.isRefunded)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refunded',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amount: AED ${NumberFormat('#,##0.00').format(widget.invoice.refundAmount)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(widget.invoice.refundedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    Text(
                      'Reason: ${widget.invoice.refundReason}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
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

  Widget _buildStatusCard<T>(
    ThemeData theme,
    String title,
    T status,
    String? date, {
    required Function(T) onUpdate,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status is PaymentStatus 
                      ? Icons.payments_outlined 
                      : Icons.local_shipping_outlined,
                  color: _getStatusColor(theme, status),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusDropdown(theme, status, onUpdate),
            if (date != null) ...[
              const SizedBox(height: 8),
              Text(
                'Updated on $date',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
            if (status is PaymentStatus) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.invoice.remainingBalance <= 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.invoice.remainingBalance <= 0
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.invoice.remainingBalance <= 0
                          ? 'Overpaid Amount'
                          : 'Remaining Balance',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.invoice.remainingBalance <= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    Text(
                      'AED ${NumberFormat('#,##0.00').format(widget.invoice.remainingBalance.abs())}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.invoice.remainingBalance <= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown<T>(
    ThemeData theme,
    T status,
    Function(T) onUpdate,
  ) {
    final isPaymentStatus = status is PaymentStatus;
    final values = isPaymentStatus 
        ? PaymentStatus.values 
        : InvoiceStatus.values;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: status,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          items: values.map((s) {
            final isSelected = s == status;
            return DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(theme, s),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getStatusLabel(s),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: isPaymentStatus && widget.invoice.remainingBalance > 0
              ? null  // Disable dropdown if payment is not complete
              : (value) => onUpdate(value as T),
        ),
      ),
    );
  }

  String _getStatusLabel(dynamic status) {
    final label = status.toString().split('.').last;
    return label[0].toUpperCase() + label.substring(1).toLowerCase();
  }

  Color _getStatusColor(ThemeData theme, dynamic status) {
    if (status is PaymentStatus) {
      switch (status) {
        case PaymentStatus.paid:
          return Colors.green;
        case PaymentStatus.partial:
          return Colors.orange;
        case PaymentStatus.unpaid:
          return Colors.red;
        case PaymentStatus.refunded:
          return Colors.grey;
      }
    } else if (status is InvoiceStatus) {
      switch (status) {
        case InvoiceStatus.delivered:
          return Colors.green;
        case InvoiceStatus.pending:
          return Colors.orange;
        case InvoiceStatus.cancelled:
          return Colors.red;
      }
    }
    return theme.colorScheme.primary;
  }

  Widget _buildNotesSection(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with adaptive padding and sizing
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  ),
                  child: Icon(
                    Icons.notes_rounded,
                    color: theme.colorScheme.primary,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes & Comments',
                        style: (isMobile 
                          ? theme.textTheme.titleMedium 
                          : theme.textTheme.titleLarge)?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (!isMobile)
                        Text(
                          'Add notes or comments to this invoice',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.invoice.notes.length} Notes',
                    style: (isMobile 
                      ? theme.textTheme.labelSmall 
                      : theme.textTheme.labelMedium)?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Note input section
            Container(
              constraints: BoxConstraints(
                maxHeight: isMobile ? 120 : double.infinity,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: TextField(
                      controller: _noteController,
                      maxLines: isMobile ? 2 : 3,
                      minLines: 1,
                      style: isMobile 
                        ? theme.textTheme.bodyMedium 
                        : theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Type your note here...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _addNote,
                          icon: Icon(Icons.add_comment_rounded, 
                            size: isMobile ? 18 : 24),
                          label: Text(isMobile ? 'Add' : 'Add Note'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isMobile ? 8 : 12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 8 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Previous notes section
            if (widget.invoice.notes.isNotEmpty) ...[
              Text(
                'Previous Notes',
                style: (isMobile 
                  ? theme.textTheme.titleSmall 
                  : theme.textTheme.titleMedium)?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isMobile 
                    ? MediaQuery.of(context).size.height * 0.3 
                    : double.infinity,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: isMobile 
                    ? const AlwaysScrollableScrollPhysics() 
                    : const NeverScrollableScrollPhysics(),
                  itemCount: widget.invoice.notes.length,
                  separatorBuilder: (context, index) => 
                    SizedBox(height: isMobile ? 8 : 12),
                  itemBuilder: (context, index) {
                    final note = widget.invoice.notes[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: ListTile(
                        dense: isMobile,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 4 : 8,
                        ),
                        leading: Container(
                          padding: EdgeInsets.all(isMobile ? 6 : 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.comment_outlined,
                            color: theme.colorScheme.primary,
                            size: isMobile ? 16 : 20,
                          ),
                        ),
                        title: Text(
                          note,
                          style: (isMobile 
                            ? theme.textTheme.bodyMedium 
                            : theme.textTheme.bodyLarge)?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: isMobile ? 12 : 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now()),
                                style: (isMobile 
                                  ? theme.textTheme.labelSmall 
                                  : theme.textTheme.bodySmall)?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          onPressed: () => _deleteNote(index),
                          icon: Icon(Icons.delete_outline, 
                            size: isMobile ? 20 : 24),
                          color: theme.colorScheme.error,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: isMobile ? 32 : 40,
                            minHeight: isMobile ? 32 : 40,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              _buildEmptyNotesPlaceholder(theme, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotesPlaceholder(ThemeData theme, bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: Column(
          children: [
            Icon(
              Icons.notes_rounded,
              size: isMobile ? 36 : 48,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'No notes yet',
              style: (isMobile 
                ? theme.textTheme.titleSmall 
                : theme.textTheme.titleMedium)?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              'Add your first note to this invoice',
              style: (isMobile 
                ? theme.textTheme.bodySmall 
                : theme.textTheme.bodyMedium)?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Update the preview dialog to have rounded corners on desktop
  void _showInvoicePreview(BuildContext context) async {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    try {
      final pdfBytes = await _invoiceService.generatePdfBytes(widget.invoice);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: isDesktop ? 800 : MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice Preview',
                        style: theme.textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    child: PdfPreviewWidget(pdfBytes: pdfBytes),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _invoiceService.generateAndShareInvoice(
                            widget.invoice,
                          );
                        },
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Share PDF'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    Color? color,
  }) {
    final style = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: isBold ? FontWeight.bold : null,
      color: color,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }

  void _updateDeliveryStatus(InvoiceStatus status) async {
    setState(() {
      widget.invoice.deliveryStatus = status;
      if (status == InvoiceStatus.delivered) {
        widget.invoice.deliveredAt = DateTime.now();
      }
    });
    await _invoiceService.updateInvoice(widget.invoice);
  }

  void _updatePaymentStatus(PaymentStatus status) async {
    setState(() {
      widget.invoice.paymentStatus = status;
      if (status == PaymentStatus.paid) {
        widget.invoice.paidAt = DateTime.now();
      }
    });
    await _invoiceService.updateInvoice(widget.invoice);
  }

  void _addNote() async {
    if (_noteController.text.isNotEmpty) {
      setState(() {
        widget.invoice.addNote(_noteController.text);
        _noteController.clear();
      });
      await _invoiceService.updateInvoice(widget.invoice);
    }
  }

  void _handlePayment() async {
    final controller = TextEditingController();
    final isRefund = widget.invoice.remainingBalance <= 0;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRefund ? 'Process Refund' : 'Add Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'AED ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isRefund ? 'Overpaid:' : 'Remaining:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  'AED ${NumberFormat('#,##0.00').format(widget.invoice.remainingBalance.abs())}',
                  style: TextStyle(
                    color: isRefund ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isRefund) 
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    controller.text = widget.invoice.remainingBalance.toString();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Complete Balance'),
                ),
              ),
            if (isRefund)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    controller.text = widget.invoice.remainingBalance.abs().toString();
                  },
                  icon: const Icon(Icons.currency_exchange),
                  label: const Text('Full Refund'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isRefund ? 'PROCESS REFUND' : 'ADD PAYMENT'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      final amount = double.tryParse(controller.text) ?? 0;
      if (amount > 0) {
        final paymentAmount = isRefund ? -amount : amount;
        final note = isRefund 
            ? 'Refund processed: AED ${NumberFormat('#,##0.00').format(amount)}'
            : 'Payment received: AED ${NumberFormat('#,##0.00').format(amount)}';

        setState(() {
          widget.invoice.addPayment(paymentAmount, note);
          _updateInternalPaymentStatus();
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(note),
            backgroundColor: isRefund ? Colors.red : Colors.green,
          ),
        );

        await _invoiceService.updateInvoice(widget.invoice);
      }
    }
    controller.dispose();
  }

  void _updateInternalPaymentStatus() {
    if (widget.invoice.remainingBalance <= 0) {
      widget.invoice.paymentStatus = PaymentStatus.paid;
      widget.invoice.paidAt = DateTime.now();
    } else if (widget.invoice.payments.isNotEmpty) {
      widget.invoice.paymentStatus = PaymentStatus.partial;
    } else {
      widget.invoice.paymentStatus = PaymentStatus.unpaid;
    }
  }

  Future<void> _viewMeasurementDetails(BuildContext context) async {
    if (!mounted) return;

    final measurementService = MeasurementService();
    try {
      final measurement = await measurementService.getMeasurement(widget.invoice.measurementId!);
      
      if (!mounted) return;
      if (measurement == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Store context in local variable before async gap
      final currentContext = context;
      if (!mounted) return;

      await DetailDialog.show(
        currentContext,
        measurement: measurement,
        customerId: widget.invoice.customerId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading measurement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNote(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        widget.invoice.deleteNote(index);
      });
      if (!mounted) return;
      await _invoiceService.updateInvoice(widget.invoice);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleRefund() async {
    final controller = TextEditingController();
    final reasonController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Refund Amount',
                prefixText: 'AED ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Refund Reason',
                hintText: 'Enter reason for refund',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Total Paid: AED ${NumberFormat('#,##0.00').format(widget.invoice.amountIncludingVat)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isEmpty || reasonController.text.isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'amount': double.parse(controller.text),
                'reason': reasonController.text,
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('PROCESS REFUND'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await _invoiceService.processRefund(
          widget.invoice.id,
          result['amount'],
          result['reason'],
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund processed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process refund: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
