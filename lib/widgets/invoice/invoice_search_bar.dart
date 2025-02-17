import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import '../../models/invoice_filter.dart';
import 'package:intl/intl.dart';
import 'invoice_group_menu.dart';

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
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ), // Add horizontal padding
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText:
                    'Search invoices by number, customer, bill #, or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    filter.searchQuery.isNotEmpty
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
          const SizedBox(width: 8),
          InvoiceGroupMenu(
            currentGroup: filter.groupBy,
            onGroupChanged:
                (group) => onFilterChanged(filter.copyWith(groupBy: group)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            // Reduce height to fit content better
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: _FilterSheet(
              initialFilter: filter,
              onFilterChanged: onFilterChanged,
            ),
          ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final InvoiceFilter initialFilter;
  final Function(InvoiceFilter) onFilterChanged;

  const _FilterSheet({
    required this.initialFilter,
    required this.onFilterChanged,
  });

  @override
  _FilterSheetState createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar with reduced vertical spacing
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header with reduced padding
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Text(
                'Filters',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filter = const InvoiceFilter();
                    _minAmountController.clear();
                    _maxAmountController.clear();
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
        // Quick Filters with reduced padding
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _QuickFilterChip(
                label: 'Today',
                icon: Icons.today,
                onTap: () => _setQuickDateRange(0),
              ),
              _QuickFilterChip(
                label: 'This Week',
                icon: Icons.calendar_view_week,
                onTap: () => _setQuickDateRange(7),
              ),
              _QuickFilterChip(
                label: 'This Month',
                icon: Icons.calendar_month,
                onTap: () => _setCurrentMonth(),
              ),
              _QuickFilterChip(
                label: 'Overdue',
                icon: Icons.warning_outlined,
                onTap: () {
                  setState(() {
                    _filter = _filter.copyWith(showOverdue: true);
                  });
                },
                isSelected: _filter.showOverdue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Filter Sections with optimized spacing
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            children: [
              _buildDateSection(theme),
              const SizedBox(height: 16),
              _buildStatusSection(theme),
              const SizedBox(height: 16),
              _buildAmountSection(theme),
            ],
          ),
        ),
        // Apply Button with reduced padding
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () {
                widget.onFilterChanged(_filter);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ),
      ],
    );
  }

  // Update section builders to use less padding
  Widget _buildDateSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Date Range',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'From',
                    date: _getActiveDateRange()?.start,
                    onTap: () => _selectDate(true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 20),
                ),
                Expanded(
                  child: _DateButton(
                    label: 'To',
                    date: _getActiveDateRange()?.end,
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Filters',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Delivery Status Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Status',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    icon: Icons.pending_outlined,
                    label: 'Pending',
                    selected: _filter.deliveryStatus.contains(
                      InvoiceStatus.pending,
                    ),
                    onSelected:
                        (selected) =>
                            _toggleDeliveryStatus(InvoiceStatus.pending),
                  ),
                  _StatusChip(
                    icon: Icons.check_circle_outline,
                    label: 'Completed',
                    selected: _filter.deliveryStatus.contains(
                      InvoiceStatus.delivered,
                    ),
                    onSelected:
                        (selected) =>
                            _toggleDeliveryStatus(InvoiceStatus.delivered),
                  ),
                  _StatusChip(
                    icon: Icons.cancel_outlined,
                    label: 'Cancelled',
                    selected: _filter.deliveryStatus.contains(
                      InvoiceStatus.cancelled,
                    ),
                    onSelected:
                        (selected) =>
                            _toggleDeliveryStatus(InvoiceStatus.cancelled),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Payment Status Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Status',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    icon: Icons.payments_outlined,
                    label: 'Paid',
                    selected: _filter.paymentStatus.contains(
                      PaymentStatus.paid,
                    ),
                    onSelected:
                        (selected) => _togglePaymentStatus(PaymentStatus.paid),
                    color: theme.colorScheme.secondary,
                  ),
                  _StatusChip(
                    icon: Icons.pending_actions_outlined,
                    label: 'Partial',
                    selected: _filter.paymentStatus.contains(
                      PaymentStatus.partial,
                    ),
                    onSelected:
                        (selected) =>
                            _togglePaymentStatus(PaymentStatus.partial),
                    color: theme.colorScheme.secondary,
                  ),
                  _StatusChip(
                    icon: Icons.money_off_csred_outlined,
                    label: 'Unpaid',
                    selected: _filter.paymentStatus.contains(
                      PaymentStatus.unpaid,
                    ),
                    onSelected:
                        (selected) =>
                            _togglePaymentStatus(PaymentStatus.unpaid),
                    color: theme.colorScheme.secondary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount Range',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAmountController,
                  decoration: InputDecoration(
                    labelText: 'Min Amount',
                    prefixIcon: const Icon(Icons.remove),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateAmountRange(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxAmountController,
                  decoration: InputDecoration(
                    labelText: 'Max Amount',
                    prefixIcon: const Icon(Icons.add),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateAmountRange(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = _getActiveDateRange()?.start ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _updateDateRange(
            DateTimeRange(
              start: date,
              end:
                  _getActiveDateRange()?.end ??
                  date.add(const Duration(days: 7)),
            ),
          );
        } else {
          _updateDateRange(
            DateTimeRange(
              start:
                  _getActiveDateRange()?.start ??
                  date.subtract(const Duration(days: 7)),
              end: date,
            ),
          );
        }
      });
    }
  }

  void _setQuickDateRange(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    _updateDateRange(DateTimeRange(start: start, end: end));
  }

  void _setCurrentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    _updateDateRange(DateTimeRange(start: start, end: end));
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
      _filter = _filter.copyWith(amountRange: RangeValues(min, max));
    });
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? DateFormat('MMM dd, yyyy').format(date!)
                  : 'Select Date',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    date != null
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isSelected
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        onPressed: onTap,
        backgroundColor:
            isSelected
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

// Update _StatusChip for better visual design
class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color:
                selected ? theme.colorScheme.onSecondaryContainer : chipColor,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color:
                  selected
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      onPressed: () => onSelected(!selected),
      backgroundColor:
          selected
              ? chipColor.withOpacity(0.2)
              : theme.colorScheme.surfaceContainerHighest,
      side:
          selected
              ? BorderSide(color: chipColor)
              : BorderSide(color: theme.colorScheme.outline),
    );
  }
}
