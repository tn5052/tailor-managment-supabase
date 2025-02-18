import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../models/invoice_group_by.dart';
import 'invoice_card.dart';
import 'invoice_group_header.dart';

class InvoiceGroupView extends StatefulWidget {
  final List<Invoice> invoices;
  final InvoiceGroupBy groupBy;
  final bool isGridView;
  final Function(Invoice) onTap;
  final Function(Invoice) onDelete;

  const InvoiceGroupView({
    super.key,
    required this.invoices,
    required this.groupBy,
    required this.isGridView,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<InvoiceGroupView> createState() => _InvoiceGroupViewState();
}

class _InvoiceGroupViewState extends State<InvoiceGroupView> {
  final Set<String> _expandedGroups = {};

  @override
  Widget build(BuildContext context) {
    if (widget.groupBy == InvoiceGroupBy.none) {
      return _buildList(context, widget.invoices);
    }

    final groupedInvoices = _groupInvoices();
    return ListView.builder(
      itemCount: groupedInvoices.length,
      itemBuilder: (context, index) {
        final group = groupedInvoices.entries.elementAt(index);
        return _buildCollapsibleGroup(context, group.key, group.value);
      },
    );
  }

  Map<String, List<Invoice>> _groupInvoices() {
    final grouped = <String, List<Invoice>>{};

    switch (widget.groupBy) {
      case InvoiceGroupBy.customer:
        for (var invoice in widget.invoices) {
          final key = '${invoice.customerName} (${invoice.customerBillNumber})';
          grouped.putIfAbsent(key, () => []).add(invoice);
        }
        break;

      case InvoiceGroupBy.date:
        final dateFormat = DateFormat('MMMM d, yyyy');
        for (var invoice in widget.invoices) {
          final key = dateFormat.format(invoice.date);
          grouped.putIfAbsent(key, () => []).add(invoice);
        }
        break;

      case InvoiceGroupBy.month:
        final monthFormat = DateFormat('MMMM yyyy');
        for (var invoice in widget.invoices) {
          final key = monthFormat.format(invoice.date);
          grouped.putIfAbsent(key, () => []).add(invoice);
        }
        break;

      case InvoiceGroupBy.status:
        for (var invoice in widget.invoices) {
          final key =
              '${invoice.deliveryStatus.name} / ${invoice.paymentStatus.name}';
          grouped.putIfAbsent(key, () => []).add(invoice);
        }
        break;

      case InvoiceGroupBy.amount:
        for (var invoice in widget.invoices) {
          String key;
          if (invoice.amountIncludingVat < 1000) {
            key = 'Under 1,000';
          } else if (invoice.amountIncludingVat < 5000) {
            key = '1,000 - 5,000';
          } else if (invoice.amountIncludingVat < 10000) {
            key = '5,000 - 10,000';
          } else {
            key = 'Over 10,000';
          }
          grouped.putIfAbsent(key, () => []).add(invoice);
        }
        break;

      case InvoiceGroupBy.none:
        grouped[''] = widget.invoices;
        break;
    }

    return grouped;
  }

  Widget _buildCollapsibleGroup(
    BuildContext context,
    String title,
    List<Invoice> groupInvoices,
  ) {
    final theme = Theme.of(context);
    final totalAmount = groupInvoices.fold(
      0.0,
      (sum, inv) => sum + inv.amountIncludingVat,
    );
    final currencyFormat = NumberFormat.currency(symbol: '');
    final isExpanded = _expandedGroups.contains(title);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InvoiceGroupHeader(
            title: title,
            subtitle:
                '${groupInvoices.length} invoices • ${currencyFormat.format(totalAmount)}',
            isExpanded: isExpanded,
            onToggle:
                () => setState(() {
                  if (isExpanded) {
                    _expandedGroups.remove(title);
                  } else {
                    _expandedGroups.add(title);
                  }
                }),
            headerColor: _getHeaderColor(theme, title),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: Column(
            children: [
              widget.isGridView
                  ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getGridCrossAxisCount(context),
                      childAspectRatio: 1.1,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemCount: groupInvoices.length,
                    itemBuilder:
                        (context, index) => InvoiceCard(
                          invoice: groupInvoices[index],
                          onTap: () => widget.onTap(groupInvoices[index]),
                          onDelete: () => widget.onDelete(groupInvoices[index]),
                          isGridView: true,
                        ),
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: groupInvoices.length,
                    itemBuilder:
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InvoiceCard(
                            invoice: groupInvoices[index],
                            onTap: () => widget.onTap(groupInvoices[index]),
                            onDelete:
                                () => widget.onDelete(groupInvoices[index]),
                          ),
                        ),
                  ),
              if (isExpanded) const Divider(height: 1),
            ],
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Color? _getHeaderColor(ThemeData theme, String title) {
    switch (widget.groupBy) {
      case InvoiceGroupBy.status:
        if (title.toLowerCase().contains('pending')) {
          return Colors.orange.withOpacity(0.1);
        } else if (title.toLowerCase().contains('delivered')) {
          return Colors.green.withOpacity(0.1);
        } else if (title.toLowerCase().contains('cancelled')) {
          return Colors.red.withOpacity(0.1);
        }
        break;
      case InvoiceGroupBy.amount:
        return theme.colorScheme.primaryContainer.withOpacity(0.5);
      default:
        return null;
    }
    return null;
  }

  Widget _buildList(BuildContext context, List<Invoice> invoices) {
    final sidePadding = MediaQuery.of(context).size.width >= 1024 ? 16.0 : 8.0;

    return widget.isGridView
        ? GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: sidePadding), // Add horizontal padding
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getGridCrossAxisCount(context),
            childAspectRatio: MediaQuery.of(context).size.width >= 1024 ? 1.4 : 1.2,
            mainAxisSpacing: sidePadding, // Add spacing
            crossAxisSpacing: sidePadding, // Add spacing
          ),
          itemCount: invoices.length,
          itemBuilder:
              (context, index) => InvoiceCard(
                invoice: invoices[index],
                onTap: () => widget.onTap(invoices[index]),
                onDelete: () => widget.onDelete(invoices[index]),
                isGridView: true,
              ),
        )
        : ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: sidePadding), // Add horizontal padding
          itemCount: invoices.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(bottom: sidePadding), // Add bottom spacing
            child: InvoiceCard(
              invoice: invoices[index],
              onTap: () => widget.onTap(invoices[index]),
              onDelete: () => widget.onDelete(invoices[index]),
            ),
          ),
        );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1600) return 4;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }
}
