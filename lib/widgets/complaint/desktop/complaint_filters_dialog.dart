import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/complaint_filter.dart';
import '../../../models/new_complaint_model.dart';
import '../../../theme/inventory_design_config.dart';
import 'package:google_fonts/google_fonts.dart';

class ComplaintFiltersDialog extends StatefulWidget {
  final ComplaintFilter initialFilter;

  const ComplaintFiltersDialog({super.key, required this.initialFilter});

  static Future<ComplaintFilter?> show(
    BuildContext context, {
    required ComplaintFilter initialFilter,
  }) {
    return showDialog<ComplaintFilter>(
      context: context,
      builder: (context) => ComplaintFiltersDialog(initialFilter: initialFilter),
    );
  }

  @override
  State<ComplaintFiltersDialog> createState() => _ComplaintFiltersDialogState();
}

class _ComplaintFiltersDialogState extends State<ComplaintFiltersDialog> {
  late ComplaintFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: InventoryDesignConfig.surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildContent(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.funnel(), size: 20, color: InventoryDesignConfig.primaryAccent),
          const SizedBox(width: 12),
          Text(
            'Filter Complaints',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(PhosphorIcons.x(), size: 18),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Status'),
            _buildStatusFilters(),
            const SizedBox(height: 20),
            _buildSectionTitle('Priority'),
            _buildPriorityFilters(),
            const SizedBox(height: 20),
            _buildSectionTitle('Date Range'),
            _buildDateRangeFilters(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  Widget _buildStatusFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComplaintStatus.values.map((status) {
        final isSelected = _currentFilter.statuses.contains(status);
        return FilterChip(
          label: Text(status.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _currentFilter.statuses.add(status);
              } else {
                _currentFilter.statuses.remove(status);
              }
            });
          },
          selectedColor: status.color.withOpacity(0.2),
          checkmarkColor: status.color,
        );
      }).toList(),
    );
  }

  Widget _buildPriorityFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComplaintPriority.values.map((priority) {
        final isSelected = _currentFilter.priorities.contains(priority);
        return FilterChip(
          label: Text(priority.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _currentFilter.priorities.add(priority);
              } else {
                _currentFilter.priorities.remove(priority);
              }
            });
          },
          selectedColor: priority.color.withOpacity(0.2),
          checkmarkColor: priority.color,
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            label: 'Start Date',
            date: _currentFilter.startDate,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _currentFilter.startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _currentFilter = _currentFilter.copyWith(startDate: date);
                });
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateField(
            label: 'End Date',
            date: _currentFilter.endDate,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _currentFilter.endDate ?? DateTime.now(),
                firstDate: _currentFilter.startDate ?? DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _currentFilter = _currentFilter.copyWith(endDate: date);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(PhosphorIcons.calendar()),
        ),
        child: Text(
          date != null ? DateFormat.yMMMd().format(date) : 'Select date',
          style: GoogleFonts.inter(),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _currentFilter = ComplaintFilter();
              });
            },
            child: const Text('Clear'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_currentFilter),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
