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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (status is PaymentStatus)
                widget.invoice.remainingBalance > 0
                    ? Chip(
                      label: Text(status.toString().split('.').last),
                      backgroundColor: theme.colorScheme.primaryContainer,
                    )
                    : PopupMenuButton<PaymentStatus>(
                      onSelected: (value) => onUpdate(value as T),
                      itemBuilder:
                          (context) =>
                              PaymentStatus.values
                                  .map(
                                    (s) => PopupMenuItem(
                                      value: s,
                                      child: Text(s.toString().split('.').last),
                                    ),
                                  )
                                  .toList(),
                      child: Chip(
                        label: Text(status.toString().split('.').last),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ),
                    )
              else
                PopupMenuButton<dynamic>(
                  onSelected: (value) => onUpdate(value as T),
                  itemBuilder:
                      (context) =>
                          InvoiceStatus.values
                              .map(
                                (s) => PopupMenuItem(
                                  value: s,
                                  child: Text(s.toString().split('.').last),
                                ),
                              )
                              .toList(),
                  child: Chip(
                    label: Text(status.toString().split('.').last),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 8),
            Text('Updated on $date', style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addNote,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.invoice.notes.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.invoice.notes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.note),
                    title: Text(widget.invoice.notes[index]),
                    subtitle: Text(
                      'Added on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                    ),
                  );
                },
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
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining:',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      NumberFormat.currency(
                        symbol: '',
                      ).format(widget.invoice.remainingBalance),
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      controller.text =
                          widget.invoice.remainingBalance.toString();
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete Balance'),
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
                child: const Text('ADD PAYMENT'),
              ),
            ],
          ),
    );

    if (result == true && controller.text.isNotEmpty) {
      final amount = double.tryParse(controller.text) ?? 0;
      if (amount > 0) {
        setState(() {
          widget.invoice.addPayment(amount, 'Payment received');
          if (widget.invoice.remainingBalance <= 0) {
            widget.invoice.markAsPaid();
          }
        });
        await _invoiceService.updateInvoice(widget.invoice);
      }
    }
    controller.dispose();
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
}
