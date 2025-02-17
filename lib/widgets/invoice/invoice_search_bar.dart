import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import '../../models/invoice_filter.dart';
import 'package:intl/intl.dart';

class InvoiceSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final InvoiceFilter filter;
  final Function(InvoiceFilter) onFilterChanged;

  const InvoiceSearchBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search invoices by number, customer, bill #, or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: onClearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showFilterDialog(context),
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.filter_list),
                  if (filter.hasActiveFilters)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: Text(isDesktop ? 'Filters' : ''),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        initialFilter: filter,
        onFilterChanged: onFilterChanged,
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final InvoiceFilter initialFilter;
  final Function(InvoiceFilter) onFilterChanged;

  const _FilterDialog({
    required this.initialFilter,
    required this.onFilterChanged,
  });

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late InvoiceFilter _filter;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    if (_filter.amountRange != null) {
      _minAmountController.text = _filter.amountRange!.start.toString();
      _maxAmountController.text = _filter.amountRange!.end.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: isDesktop ? 600 : null,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusSection(theme),
                    const Divider(height: 32),
                    _buildDateFilters(theme),
                    const Divider(height: 32),
                    _buildAmountFilters(theme),
                    const Divider(height: 32),
                    _buildOverdueFilter(theme),
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
          Icon(
            Icons.filter_list,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Text(
            'Filter Invoices',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'Pending',
              selected: _filter.deliveryStatus.contains(InvoiceStatus.pending),
              onSelected: (selected) => _toggleDeliveryStatus(InvoiceStatus.pending),
            ),
            _FilterChip(
              label: 'Completed',
              selected: _filter.deliveryStatus.contains(InvoiceStatus.delivered),
              onSelected: (selected) => _toggleDeliveryStatus(InvoiceStatus.delivered),
            ),
            _FilterChip(
              label: 'Cancelled',
              selected: _filter.deliveryStatus.contains(InvoiceStatus.cancelled),
              onSelected: (selected) => _toggleDeliveryStatus(InvoiceStatus.cancelled),
            ),
            _FilterChip(
              label: 'Partially Paid',
              selected: _filter.paymentStatus.contains(PaymentStatus.partial),
              onSelected: (selected) => _togglePaymentStatus(PaymentStatus.partial),
            ),
            _FilterChip(
              label: 'Paid',
              selected: _filter.paymentStatus.contains(PaymentStatus.paid),
              onSelected: (selected) => _togglePaymentStatus(PaymentStatus.paid),
            ),
            _FilterChip(
              label: 'Unpaid',
              selected: _filter.paymentStatus.contains(PaymentStatus.unpaid),
              onSelected: (selected) => _togglePaymentStatus(PaymentStatus.unpaid),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateFilters(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SegmentedButton<FilterDateType>(
          selected: {_filter.selectedDateType},
          onSelectionChanged: (Set<FilterDateType> selection) {
            setState(() {
              _filter = _filter.copyWith(selectedDateType: selection.first);
            });
          },
          segments: const [
            ButtonSegment(
              value: FilterDateType.creation,
              label: Text('Creation'),
            ),
            ButtonSegment(
              value: FilterDateType.due,
              label: Text('Due'),
            ),
            ButtonSegment(
              value: FilterDateType.modified,
              label: Text('Modified'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DateRangeButton(
          label: 'Select Date Range',
          dateRange: _getActiveDateRange(),
          onDateRangeSelected: (range) => _updateDateRange(range),
        ),
      ],
    );
  }

  Widget _buildAmountFilters(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount Range',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                decoration: const InputDecoration(
                  labelText: 'Min Amount',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateAmountRange(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                decoration: const InputDecoration(
                  labelText: 'Max Amount',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateAmountRange(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverdueFilter(ThemeData theme) {
    return SwitchListTile(
      title: Text(
        'Show Overdue',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('Show invoices past their due date'),
      value: _filter.showOverdue,
      onChanged: (value) {
        setState(() {
          _filter = _filter.copyWith(showOverdue: value);
        });
      },
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
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
              widget.onFilterChanged(_filter);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  void _toggleDeliveryStatus(InvoiceStatus status) {
    setState(() {
      final statuses = List<InvoiceStatus>.from(_filter.deliveryStatus);
      if (statuses.contains(status)) {
        statuses.remove(status);
      } else {
        statuses.add(status);
      }
      _filter = _filter.copyWith(deliveryStatus: statuses);
    });
  }

  void _togglePaymentStatus(PaymentStatus status) {
    setState(() {
      final statuses = List<PaymentStatus>.from(_filter.paymentStatus);
      if (statuses.contains(status)) {
        statuses.remove(status);
      } else {
        statuses.add(status);
      }
      _filter = _filter.copyWith(paymentStatus: statuses);
    });
  }

  DateTimeRange? _getActiveDateRange() {
    switch (_filter.selectedDateType) {
      case FilterDateType.creation:
        return _filter.creationDateRange;
      case FilterDateType.due:
        return _filter.dueDateRange;
      case FilterDateType.modified:
        return _filter.modifiedDateRange;
    }
  }

  void _updateDateRange(DateTimeRange? range) {
    setState(() {
      switch (_filter.selectedDateType) {
        case FilterDateType.creation:
          _filter = _filter.copyWith(creationDateRange: range);
          break;
        case FilterDateType.due:
          _filter = _filter.copyWith(dueDateRange: range);
          break;
        case FilterDateType.modified:
          _filter = _filter.copyWith(modifiedDateRange: range);
          break;
      }
    });
  }

  void _updateAmountRange() {
    final min = double.tryParse(_minAmountController.text) ?? 0;
    final max = double.tryParse(_maxAmountController.text) ?? double.infinity;
    setState(() {
      _filter = _filter.copyWith(
        amountRange: RangeValues(min, max),
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final String label;
  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onDateRangeSelected;

  const _DateRangeButton({
    required this.label,
    required this.dateRange,
    required this.onDateRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRange = dateRange != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDateRangePicker(context),
                icon: Icon(
                  hasRange ? Icons.date_range : Icons.calendar_today,
                  color: hasRange ? theme.colorScheme.primary : null,
                ),
                label: Text(
                  hasRange
                      ? '${DateFormat('MMM dd').format(dateRange!.start)} - ${DateFormat('MMM dd').format(dateRange!.end)}'
                      : label,
                ),
              ),
            ),
            if (hasRange) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onDateRangeSelected(null),
                icon: const Icon(Icons.close),
                tooltip: 'Clear date range',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final initialDateRange = dateRange ?? DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 7)),
    );

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: initialDateRange,
    );

    if (pickedRange != null) {
      onDateRangeSelected(pickedRange);
    }
  }
}
