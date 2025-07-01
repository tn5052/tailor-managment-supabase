import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/invoice_filter.dart';
import '../../../models/invoice.dart';

class InvoiceFilterDialog extends StatefulWidget {
  final InvoiceFilter initialFilter;
  final Function(InvoiceFilter) onFilterApplied;

  const InvoiceFilterDialog({
    super.key,
    required this.initialFilter,
    required this.onFilterApplied,
  });

  @override
  State<InvoiceFilterDialog> createState() => _InvoiceFilterDialogState();
}

class _InvoiceFilterDialogState extends State<InvoiceFilterDialog> {
  late InvoiceFilter _currentFilter;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _initializeAmountControllers();
  }

  void _initializeAmountControllers() {
    if (_currentFilter.amountRange != null) {
      _minAmountController.text = _currentFilter.amountRange!.start.round().toString();
      _maxAmountController.text = _currentFilter.amountRange!.end.round().toString();
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenSize.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusXL),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(child: _buildContent()),
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
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
            ),
            child: Icon(
              PhosphorIcons.funnel(),
              size: 18,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Expanded(
            child: Text(
              'Filter Invoices',
              style: InventoryDesignConfig.headlineMedium,
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                child: Icon(
                  PhosphorIcons.x(),
                  size: 18,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionCard(
            "Date Filters",
            PhosphorIcons.calendar(),
            _buildDateRangeFilter(),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          _buildSectionCard(
            "Payment Status",
            PhosphorIcons.money(),
            _buildPaymentStatusFilter(),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          _buildSectionCard(
            "Delivery Status",
            PhosphorIcons.truck(),
            _buildDeliveryStatusFilter(),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          _buildSectionCard(
            "Amount Range",
            PhosphorIcons.currencyDollar(),
            _buildAmountRangeFilter(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(color: InventoryDesignConfig.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXXL,
      ),
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
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () {
                setState(() {
                  _currentFilter = InvoiceFilter();
                  _minAmountController.clear();
                  _maxAmountController.clear();
                });
              },
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXXL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: InventoryDesignConfig.buttonSecondaryDecoration,
                child: Text(
                  'Reset',
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingL),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: InkWell(
              onTap: () {
                widget.onFilterApplied(_currentFilter);
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: InventoryDesignConfig.spacingXXL,
                  vertical: InventoryDesignConfig.spacingM,
                ),
                decoration: InventoryDesignConfig.buttonPrimaryDecoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.check(),
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    Text(
                      'Apply Filters',
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

  Widget _buildSection(String title, Widget content, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: InventoryDesignConfig.textSecondary),
              const SizedBox(width: InventoryDesignConfig.spacingS),
            ],
            Text(title, style: InventoryDesignConfig.labelLarge),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        content,
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date type selector
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingM,
            vertical: InventoryDesignConfig.spacingS,
          ),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.calendar(),
                size: 16,
                color: InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                'Filter by:',
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              DropdownButton<FilterDateType>(
                value: _currentFilter.selectedDateType,
                underline: const SizedBox(),
                style: InventoryDesignConfig.bodyMedium,
                items: [
                  DropdownMenuItem(
                    value: FilterDateType.creation,
                    child: Text('Creation Date'),
                  ),
                  DropdownMenuItem(
                    value: FilterDateType.due,
                    child: Text('Delivery Date'),
                  ),
                  DropdownMenuItem(
                    value: FilterDateType.modified,
                    child: Text('Modified Date'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentFilter = _currentFilter.copyWith(selectedDateType: value);
                    });
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        // Quick date filters
        Wrap(
          spacing: InventoryDesignConfig.spacingS,
          runSpacing: InventoryDesignConfig.spacingS,
          children: [
            _buildQuickDateButton('Today', () {
              final today = DateTime.now();
              final range = DateTimeRange(start: today, end: today);
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  creationDateRange: _currentFilter.selectedDateType == FilterDateType.creation ? range : null,
                  dueDateRange: _currentFilter.selectedDateType == FilterDateType.due ? range : null,
                  modifiedDateRange: _currentFilter.selectedDateType == FilterDateType.modified ? range : null,
                );
              });
            }),
            _buildQuickDateButton('This Week', () {
              final now = DateTime.now();
              final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
              final range = DateTimeRange(start: startOfWeek, end: now);
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  creationDateRange: _currentFilter.selectedDateType == FilterDateType.creation ? range : null,
                  dueDateRange: _currentFilter.selectedDateType == FilterDateType.due ? range : null,
                  modifiedDateRange: _currentFilter.selectedDateType == FilterDateType.modified ? range : null,
                );
              });
            }),
            _buildQuickDateButton('This Month', () {
              final now = DateTime.now();
              final startOfMonth = DateTime(now.year, now.month, 1);
              final range = DateTimeRange(start: startOfMonth, end: now);
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  creationDateRange: _currentFilter.selectedDateType == FilterDateType.creation ? range : null,
                  dueDateRange: _currentFilter.selectedDateType == FilterDateType.due ? range : null,
                  modifiedDateRange: _currentFilter.selectedDateType == FilterDateType.modified ? range : null,
                );
              });
            }),
            _buildQuickDateButton('Last 30 Days', () {
              final now = DateTime.now();
              final thirtyDaysAgo = now.subtract(const Duration(days: 30));
              final range = DateTimeRange(start: thirtyDaysAgo, end: now);
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  creationDateRange: _currentFilter.selectedDateType == FilterDateType.creation ? range : null,
                  dueDateRange: _currentFilter.selectedDateType == FilterDateType.due ? range : null,
                  modifiedDateRange: _currentFilter.selectedDateType == FilterDateType.modified ? range : null,
                );
              });
            }),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Start Date',
                _getCurrentDateRange()?.start,
                PhosphorIcons.calendarBlank(),
                (date) => _updateDateRange(start: date),
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingL),
            Expanded(
              child: _buildDateField(
                'End Date',
                _getCurrentDateRange()?.end,
                PhosphorIcons.calendar(),
                (date) => _updateDateRange(end: date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  DateTimeRange? _getCurrentDateRange() {
    switch (_currentFilter.selectedDateType) {
      case FilterDateType.creation:
        return _currentFilter.creationDateRange;
      case FilterDateType.due:
        return _currentFilter.dueDateRange;
      case FilterDateType.modified:
        return _currentFilter.modifiedDateRange;
    }
  }

  void _updateDateRange({DateTime? start, DateTime? end}) {
    final currentRange = _getCurrentDateRange();
    final newStart = start ?? currentRange?.start ?? DateTime.now();
    final newEnd = end ?? currentRange?.end ?? DateTime.now();
    
    final newRange = DateTimeRange(start: newStart, end: newEnd);
    
    setState(() {
      switch (_currentFilter.selectedDateType) {
        case FilterDateType.creation:
          _currentFilter = _currentFilter.copyWith(creationDateRange: newRange);
          break;
        case FilterDateType.due:
          _currentFilter = _currentFilter.copyWith(dueDateRange: newRange);
          break;
        case FilterDateType.modified:
          _currentFilter = _currentFilter.copyWith(modifiedDateRange: newRange);
          break;
      }
    });
  }

  Widget _buildQuickDateButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingM,
            vertical: InventoryDesignConfig.spacingS,
          ),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: Text(
            label,
            style: InventoryDesignConfig.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? initialDate, IconData icon, ValueChanged<DateTime> onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: InventoryDesignConfig.labelLarge.copyWith(
            color: InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: initialDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (date != null) {
                onDateSelected(date);
              }
            },
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: InventoryDesignConfig.spacingL,
                vertical: InventoryDesignConfig.spacingM + 2,
              ),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.surfaceLight,
                borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                border: Border.all(color: InventoryDesignConfig.borderPrimary),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingL),
                  Expanded(
                    child: Text(
                      initialDate != null
                          ? DateFormat('MMM d, yyyy').format(initialDate)
                          : 'Select Date',
                      style: initialDate != null
                          ? InventoryDesignConfig.bodyLarge.copyWith(
                              color: InventoryDesignConfig.textPrimary,
                            )
                          : InventoryDesignConfig.bodyMedium.copyWith(
                              color: InventoryDesignConfig.textTertiary,
                            ),
                    ),
                  ),
                  Icon(
                    PhosphorIcons.caretDown(),
                    size: 16,
                    color: InventoryDesignConfig.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusFilter() {
    final paymentStatuses = ['paid', 'unpaid', 'partial', 'refunded'];
    final statusLabels = {
      'paid': 'Paid',
      'unpaid': 'Unpaid',
      'partial': 'Partially Paid',
      'refunded': 'Refunded',
    };
    final statusColors = {
      'paid': InventoryDesignConfig.successColor,
      'unpaid': InventoryDesignConfig.errorColor,
      'partial': InventoryDesignConfig.warningColor,
      'refunded': InventoryDesignConfig.infoColor,
    };

    return Wrap(
      spacing: InventoryDesignConfig.spacingS,
      runSpacing: InventoryDesignConfig.spacingS,
      children: paymentStatuses.map((status) {
        final isSelected = _currentFilter.paymentStatus.any((s) => s.name == status);
        return _buildCustomFilterChip(
          label: statusLabels[status]!,
          isSelected: isSelected,
          color: statusColors[status]!,
          onSelected: (selected) {
            setState(() {
              final newPaymentStatus = List<PaymentStatus>.from(_currentFilter.paymentStatus);
              if (selected) {
                // Find the enum value and add it
                final enumValue = PaymentStatus.values.firstWhere((e) => e.name == status);
                if (!newPaymentStatus.contains(enumValue)) {
                  newPaymentStatus.add(enumValue);
                }
              } else {
                // Remove the enum value
                newPaymentStatus.removeWhere((e) => e.name == status);
              }
              _currentFilter = _currentFilter.copyWith(paymentStatus: newPaymentStatus);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryStatusFilter() {
    final deliveryStatuses = ['pending', 'inProgress', 'delivered', 'cancelled'];
    final statusLabels = {
      'pending': 'Pending',
      'inProgress': 'In Progress',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
    };
    final statusColors = {
      'pending': InventoryDesignConfig.warningColor,
      'inProgress': InventoryDesignConfig.infoColor,
      'delivered': InventoryDesignConfig.successColor,
      'cancelled': InventoryDesignConfig.errorColor,
    };

    return Wrap(
      spacing: InventoryDesignConfig.spacingS,
      runSpacing: InventoryDesignConfig.spacingS,
      children: deliveryStatuses.map((status) {
        final isSelected = _currentFilter.deliveryStatus.any((s) => s.name == status);
        return _buildCustomFilterChip(
          label: statusLabels[status]!,
          isSelected: isSelected,
          color: statusColors[status]!,
          onSelected: (selected) {
            setState(() {
              final newDeliveryStatus = List<InvoiceStatus>.from(_currentFilter.deliveryStatus);
              if (selected) {
                // Find the enum value and add it
                final enumValue = InvoiceStatus.values.firstWhere((e) => e.name == status);
                if (!newDeliveryStatus.contains(enumValue)) {
                  newDeliveryStatus.add(enumValue);
                }
              } else {
                // Remove the enum value
                newDeliveryStatus.removeWhere((e) => e.name == status);
              }
              _currentFilter = _currentFilter.copyWith(deliveryStatus: newDeliveryStatus);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCustomFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required ValueChanged<bool> onSelected,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: () => onSelected(!isSelected),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color: isSelected ? color : InventoryDesignConfig.borderPrimary,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
                  border: Border.all(
                    color: isSelected ? color : InventoryDesignConfig.borderSecondary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        PhosphorIcons.check(),
                        size: 10,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: isSelected ? color : InventoryDesignConfig.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRangeFilter() {
    final currentRange = _currentFilter.amountRange ?? const RangeValues(0, 10000);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount range display with values
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Min Amount',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: InventoryDesignConfig.spacingXS),
                    Text(
                      '\$${currentRange.start.round()}',
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        color: InventoryDesignConfig.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: InventoryDesignConfig.borderSecondary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Max Amount',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: InventoryDesignConfig.spacingXS),
                    Text(
                      '\$${currentRange.end.round()}',
                      style: InventoryDesignConfig.titleMedium.copyWith(
                        color: InventoryDesignConfig.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        
        // Range slider with custom styling
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: InventoryDesignConfig.primaryColor,
            inactiveTrackColor: InventoryDesignConfig.borderSecondary,
            thumbColor: InventoryDesignConfig.primaryColor,
            overlayColor: InventoryDesignConfig.primaryColor.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            valueIndicatorColor: InventoryDesignConfig.primaryColor,
            valueIndicatorTextStyle: InventoryDesignConfig.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: RangeSlider(
            values: currentRange,
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              '\$${currentRange.start.round()}',
              '\$${currentRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _currentFilter.amountRange = values;
                _minAmountController.text = values.start.round().toString();
                _maxAmountController.text = values.end.round().toString();
              });
            },
          ),
        ),
        
        const SizedBox(height: InventoryDesignConfig.spacingL),
        
        // Quick amount buttons
        Text(
          'Quick Select',
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingS),
        Wrap(
          spacing: InventoryDesignConfig.spacingS,
          runSpacing: InventoryDesignConfig.spacingS,
          children: [
            _buildQuickAmountButton('Under \$100', const RangeValues(0, 100)),
            _buildQuickAmountButton('\$100 - \$500', const RangeValues(100, 500)),
            _buildQuickAmountButton('\$500 - \$1000', const RangeValues(500, 1000)),
            _buildQuickAmountButton('Over \$1000', const RangeValues(1000, 10000)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(String label, RangeValues range) {
    final isSelected = _currentFilter.amountRange != null &&
        _currentFilter.amountRange!.start == range.start &&
        _currentFilter.amountRange!.end == range.end;
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentFilter.amountRange = range;
            _minAmountController.text = range.start.round().toString();
            _maxAmountController.text = range.end.round().toString();
          });
        },
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingM,
            vertical: InventoryDesignConfig.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? InventoryDesignConfig.primaryColor.withOpacity(0.1)
                : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
            border: Border.all(
              color: isSelected 
                  ? InventoryDesignConfig.primaryColor
                  : InventoryDesignConfig.borderPrimary,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: InventoryDesignConfig.bodySmall.copyWith(
              color: isSelected 
                  ? InventoryDesignConfig.primaryColor
                  : InventoryDesignConfig.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
