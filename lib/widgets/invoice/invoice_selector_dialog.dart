import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../theme/app_theme.dart';

class InvoiceSelectorDialog extends StatefulWidget {
  final List<Invoice> invoices;
  final Invoice? selectedInvoice;
  final ValueChanged<Invoice?> onSelect;

  const InvoiceSelectorDialog({
    super.key,
    required this.invoices,
    this.selectedInvoice,
    required this.onSelect,
  });

  static Future<Invoice?> show(
    BuildContext context,
    List<Invoice> invoices, {
    Invoice? selectedInvoice,
  }) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return showDialog<Invoice>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isDesktop ? 600 : size.width * 0.95,
          height: size.height * (isDesktop ? 0.8 : 0.7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(isDesktop ? 28 : 20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InvoiceSelectorDialog(
            invoices: invoices,
            selectedInvoice: selectedInvoice,
            onSelect: (invoice) => Navigator.pop(context, invoice),
          ),
        ),
      ),
    );
  }

  @override
  State<InvoiceSelectorDialog> createState() => _InvoiceSelectorDialogState();
}

class _InvoiceSelectorDialogState extends State<InvoiceSelectorDialog> {
  final _searchController = TextEditingController();
  List<Invoice> _filteredInvoices = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredInvoices = widget.invoices;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredInvoices = widget.invoices.where((invoice) {
        return invoice.customerName.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Updated header style
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? AppTheme.primaryColor.withOpacity(0.08)
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.receipt(),
                      color: theme.colorScheme.primary,
                      size: isDesktop ? 24 : 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select Invoice',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? null : 18,
                      color: theme.brightness == Brightness.light
                          ? AppTheme.neutralColor
                          : null,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                child: _buildCloseButton(theme),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 24 : 16),

          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by invoice number or customer...',
              prefixIcon: PhosphorIcon(
                PhosphorIcons.magnifyingGlass(),
                color: theme.colorScheme.primary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 20 : 16),

          // Invoices list
          Expanded(
            child: _filteredInvoices.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 4 : 0,
                    ),
                    itemCount: _filteredInvoices.length,
                    itemBuilder: (context, index) => _InvoiceCard(
                      invoice: _filteredInvoices[index],
                      isSelected: widget.selectedInvoice?.id ==
                          _filteredInvoices[index].id,
                      onTap: () => widget.onSelect(_filteredInvoices[index]),
                      searchQuery: _searchQuery,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PhosphorIcon(
            PhosphorIcons.x(),
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIcons.receipt(),
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No invoices found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline.withOpacity(0.7),
            ),
          ),
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

class _InvoiceCard extends StatefulWidget {
  final Invoice invoice;
  final bool isSelected;
  final VoidCallback onTap;
  final String searchQuery;

  const _InvoiceCard({
    required this.invoice,
    required this.isSelected,
    required this.onTap,
    required this.searchQuery,
  });

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: isDesktop ? 12 : 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : _isHovered
                  ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
                  : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 16 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildInvoiceNumber(theme),
                      const Spacer(),
                      _buildDate(theme, isDesktop),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 16 : 12),
                  Row(
                    children: [
                      _buildAmount(theme, isDesktop),
                      const SizedBox(width: 16),
                      _buildStatus(theme, isDesktop),
                      if (widget.isSelected)
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceNumber(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? AppTheme.primaryColor.withOpacity(0.08)
            : theme.colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIcons.hashStraight(),
            color: theme.colorScheme.primary,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Invoice #${widget.invoice.invoiceNumber}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDate(ThemeData theme, bool isDesktop) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(
          PhosphorIcons.calendar(),
          size: isDesktop ? 16 : 14,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          DateFormat(isDesktop ? 'MMM dd, yyyy' : 'MM/dd/yy')
              .format(widget.invoice.date),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildAmount(ThemeData theme, bool isDesktop) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.brightness == Brightness.light
                  ? AppTheme.neutralColor.withOpacity(0.7)
                  : theme.colorScheme.outline,
              fontSize: isDesktop ? null : 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'AED ${widget.invoice.amountIncludingVat.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isDesktop ? null : 14,
              color: theme.brightness == Brightness.light
                  ? AppTheme.primaryColor
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(ThemeData theme, bool isDesktop) {
    final statusColor = _getStatusColor(widget.invoice.deliveryStatus);
    final backgroundColor = theme.brightness == Brightness.light
        ? statusColor.withOpacity(0.08)
        : statusColor.withOpacity(0.15);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 12 : 8,
        vertical: isDesktop ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.invoice.deliveryStatus.toString().split('.').last,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
              fontSize: isDesktop ? null : 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case InvoiceStatus.pending:
        return isDark ? Colors.orange : AppTheme.warningColor;
      case InvoiceStatus.delivered:
        return isDark ? Colors.green : AppTheme.successColor;
      case InvoiceStatus.cancelled:
        return isDark ? Colors.red : AppTheme.errorColor;
      case InvoiceStatus.inProgress:
        return isDark ? Colors.blue : AppTheme.primaryColor;
    }
  }
}
