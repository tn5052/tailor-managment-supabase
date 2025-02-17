import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceDetailsDialog extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailsDialog({super.key, required this.invoice});

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

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isDesktop ? 800 : null,
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 800 : screenWidth * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
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
            _buildActions(theme),
          ],
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
    return Card(
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
                color:
                    widget.invoice.remainingBalance > 0
                        ? Colors.red
                        : Colors.green,
              ),
            ],
            if (widget.invoice.measurementName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Text('Measurement:', style: theme.textTheme.bodyLarge),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.invoice.measurementName!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showInvoicePreview(context),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showInvoicePreview(BuildContext context) {}

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
}
