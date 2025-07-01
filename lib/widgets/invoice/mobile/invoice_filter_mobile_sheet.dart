import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/invoice_filter.dart';
import '../../../models/invoice.dart';

class InvoiceFilterMobileSheet extends StatefulWidget {
  final InvoiceFilter initialFilter;
  final Function(InvoiceFilter) onFilterApplied;

  const InvoiceFilterMobileSheet({
    Key? key,
    required this.initialFilter,
    required this.onFilterApplied,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required InvoiceFilter initialFilter,
    required Function(InvoiceFilter) onFilterApplied,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      useSafeArea: true,
      builder: (context) => InvoiceFilterMobileSheet(
        initialFilter: initialFilter,
        onFilterApplied: onFilterApplied,
      ),
    );
  }

  @override
  _InvoiceFilterMobileSheetState createState() =>
      _InvoiceFilterMobileSheetState();
}

class _InvoiceFilterMobileSheetState extends State<InvoiceFilterMobileSheet>
    with TickerProviderStateMixin {
  late InvoiceFilter _currentFilter;
  late AnimationController _animationController;
  late Animation<double> _sheetAnimation;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter.copyWith();
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

  void _applyFilters() {
    widget.onFilterApplied(_currentFilter);
    _handleClose();
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilter = InvoiceFilter();
    });
  }
  
  Future<void> _handleClose() async {
    HapticFeedback.lightImpact();
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.vertical(
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
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: const BoxDecoration(
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
              borderRadius:
                  BorderRadius.circular(InventoryDesignConfig.radiusM),
            ),
            child: Icon(
              PhosphorIcons.funnel(),
              size: 20,
              color: InventoryDesignConfig.primaryColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Text(
            'Filter & Sort Invoices',
            style: InventoryDesignConfig.headlineMedium,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(PhosphorIcons.x(), color: InventoryDesignConfig.textSecondary),
            onPressed: _handleClose,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Payment Status',
            icon: PhosphorIcons.creditCard(),
            child: _buildStatusChips<PaymentStatus>(
              selected: _currentFilter.paymentStatus.toSet(),
              all: PaymentStatus.values,
              onSelected: (status, selected) {
                setState(() {
                  if (selected) {
                    _currentFilter.paymentStatus.add(status);
                  } else {
                    _currentFilter.paymentStatus.remove(status);
                  }
                });
              },
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          _buildSection(
            title: 'Delivery Status',
            icon: PhosphorIcons.package(),
            child: _buildStatusChips<InvoiceStatus>(
              selected: _currentFilter.deliveryStatus.toSet(),
              all: InvoiceStatus.values,
              onSelected: (status, selected) {
                setState(() {
                  if (selected) {
                    _currentFilter.deliveryStatus.add(status);
                  } else {
                    _currentFilter.deliveryStatus.remove(status);
                  }
                });
              },
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          _buildSection(
            title: 'Date Range',
            icon: PhosphorIcons.calendar(),
            child: Column(
              children: [
                _buildDateRangePicker(
                  label: 'Creation Date',
                  range: _currentFilter.creationDateRange,
                  onChanged: (range) {
                    setState(() {
                      _currentFilter = _currentFilter.copyWith(creationDateRange: range);
                    });
                  },
                ),
                const SizedBox(height: InventoryDesignConfig.spacingL),
                _buildDateRangePicker(
                  label: 'Delivery Date',
                  range: _currentFilter.dueDateRange,
                  onChanged: (range) {
                    setState(() {
                      _currentFilter = _currentFilter.copyWith(dueDateRange: range);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          _buildSection(
            title: 'Other',
            icon: PhosphorIcons.dotsThree(),
            child: SwitchListTile(
              title: const Text('Show Overdue Only'),
              value: _currentFilter.showOverdue,
              onChanged: (value) {
                setState(() {
                  _currentFilter = _currentFilter.copyWith(showOverdue: value);
                });
              },
              activeColor: InventoryDesignConfig.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: InventoryDesignConfig.textSecondary),
            const SizedBox(width: InventoryDesignConfig.spacingS),
            Text(title, style: InventoryDesignConfig.titleMedium),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        child,
      ],
    );
  }

  Widget _buildStatusChips<T>({
    required Set<T> selected,
    required List<T> all,
    required Function(T, bool) onSelected,
  }) {
    return Wrap(
      spacing: InventoryDesignConfig.spacingM,
      runSpacing: InventoryDesignConfig.spacingM,
      children: all.map((status) {
        final isSelected = selected.contains(status);
        return ChoiceChip(
          label: Text(status.toString().split('.').last),
          selected: isSelected,
          onSelected: (selected) => onSelected(status, selected),
          backgroundColor: InventoryDesignConfig.surfaceLight,
          selectedColor: InventoryDesignConfig.primaryColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? InventoryDesignConfig.primaryColor
                : InventoryDesignConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? InventoryDesignConfig.primaryColor
                  : InventoryDesignConfig.borderPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangePicker({
    required String label,
    required DateTimeRange? range,
    required Function(DateTimeRange?) onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            initialDateRange: range,
          );
          if (picked != null) {
            onChanged(picked);
          }
        },
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
          child: Row(
            children: [
              Icon(PhosphorIcons.calendar(), color: InventoryDesignConfig.textSecondary),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: InventoryDesignConfig.bodyMedium),
                    Text(
                      range == null
                          ? 'Any'
                          : '${DateFormat.yMd().format(range.start)} - ${DateFormat.yMd().format(range.end)}',
                      style: InventoryDesignConfig.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(PhosphorIcons.caretDown(), color: InventoryDesignConfig.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingL +
            MediaQuery.of(context).padding.bottom,
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
            child: OutlinedButton(
              onPressed: _clearAllFilters,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear All'),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: Icon(PhosphorIcons.funnel()),
              label: const Text('Apply Filters'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: InventoryDesignConfig.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
