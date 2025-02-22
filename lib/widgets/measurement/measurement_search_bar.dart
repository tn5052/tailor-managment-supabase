import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/measurement_filter.dart'; // Need to create this
import 'measurement_group_menu.dart';  // Add this import

class MeasurementSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final MeasurementFilter filter; // New filter model
  final Function(MeasurementFilter) onFilterChanged;

  const MeasurementSearchBar({
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
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: isDesktop
                      ? 'Search by customer name, bill number, or style'
                      : 'Search measurements...',
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
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showFilterDialog(context),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: filter.hasActiveFilters
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    if (filter.hasActiveFilters)
                      Positioned(
                        right: 12,
                        top: 12,
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
              ),
            ),
          ),
          const SizedBox(width: 8),
          MeasurementGroupMenu(
            currentGroup: filter.groupBy,
            onGroupChanged: (group) => onFilterChanged(
              filter.copyWith(groupBy: group),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MeasurementFilterSheet(
        filter: filter,
        onFilterChanged: onFilterChanged,
      ),
    );
  }
}

class _MeasurementFilterSheet extends StatefulWidget {
  final MeasurementFilter filter;
  final Function(MeasurementFilter) onFilterChanged;

  const _MeasurementFilterSheet({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<_MeasurementFilterSheet> createState() => _MeasurementFilterSheetState();
}

class _MeasurementFilterSheetState extends State<_MeasurementFilterSheet> {
  late MeasurementFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Text(
                  'Filter Measurements',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _filter = const MeasurementFilter());
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          // Quick Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Today',
                  selected: _isToday(),
                  onSelected: (_) => _setQuickDateRange(0),
                  icon: Icons.today,
                ),
                _FilterChip(
                  label: 'Yesterday',
                  selected: _isYesterday(),
                  onSelected: (_) => _setQuickDateRange(1),
                  icon: Icons.history,
                ),
                _FilterChip(
                  label: 'This Week',
                  selected: _isThisWeek(),
                  onSelected: (_) => _setQuickDateRange(7),
                  icon: Icons.calendar_view_week,
                ),
                _FilterChip(
                  label: 'Last 30 Days',
                  selected: _isLast30Days(),
                  onSelected: (_) => _setQuickDateRange(30),
                  icon: Icons.calendar_month,
                ),
                _FilterChip(
                  label: 'Repeat Customers',
                  selected: _filter.onlyRepeatCustomers,
                  onSelected: (value) => setState(() {
                    _filter = _filter.copyWith(onlyRepeatCustomers: value);
                  }),
                  icon: Icons.repeat,
                ),
                _FilterChip(
                  label: 'Recent Updates',
                  selected: _filter.onlyRecentUpdates,
                  onSelected: (value) => setState(() {
                    _filter = _filter.copyWith(onlyRecentUpdates: value);
                  }),
                  icon: Icons.update,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filter Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildDateSection(theme),
                const SizedBox(height: 20),
                _buildDesignTypeSection(theme),
                const SizedBox(height: 20),
                _buildStylesSection(theme),
                const SizedBox(height: 20),
                _buildFrequencySection(theme),
              ],
            ),
          ),
          // Apply Button
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
      ),
    );
  }

  Widget _buildDateSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateButton(
                label: 'From',
                date: _filter.dateRange?.start,
                onTap: () => _selectDate(true),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: _DateButton(
                label: 'To',
                date: _filter.dateRange?.end,
                onTap: () => _selectDate(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesignTypeSection(ThemeData theme) {
    final designTypes = ['Aadi', 'Modern', 'Traditional', 'Special'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Design Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: designTypes.map((type) => FilterChip(
            label: Text(type),
            selected: _filter.designType == type,
            onSelected: (selected) => setState(() {
              _filter = _filter.copyWith(
                designType: selected ? type : null,
              );
            }),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildStylesSection(ThemeData theme) {
    // Add your styles section implementation here
    return Container(); // Placeholder
  }

  Widget _buildFrequencySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Frequency',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('Only Repeat Customers'),
          subtitle: const Text('Show customers with multiple measurements'),
          leading: Icon(Icons.repeat, color: theme.colorScheme.primary),
          trailing: Switch(
            value: _filter.onlyRepeatCustomers,
            onChanged: (value) => setState(() {
              _filter = _filter.copyWith(onlyRepeatCustomers: value);
            }),
          ),
        ),
        ListTile(
          title: const Text('Recently Updated'),
          subtitle: const Text('Show measurements updated in last 7 days'),
          leading: Icon(Icons.update, color: theme.colorScheme.primary),
          trailing: Switch(
            value: _filter.onlyRecentUpdates,
            onChanged: (value) => setState(() {
              _filter = _filter.copyWith(onlyRecentUpdates: value);
            }),
          ),
        ),
      ],
    );
  }

  void _setQuickDateRange(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    setState(() {
      _filter = _filter.copyWith(
        dateRange: DateTimeRange(start: start, end: end),
      );
    });
  }


  bool _isToday() {
    if (_filter.dateRange == null) return false;
    final now = DateTime.now();
    final start = _filter.dateRange!.start;
    return start.year == now.year &&
           start.month == now.month &&
           start.day == now.day;
  }

  bool _isYesterday() {
    if (_filter.dateRange == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final start = _filter.dateRange!.start;
    return start.year == yesterday.year &&
           start.month == yesterday.month &&
           start.day == yesterday.day;
  }

  bool _isThisWeek() {
    if (_filter.dateRange == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = _filter.dateRange!.start;
    return start.year == weekStart.year &&
           start.month == weekStart.month &&
           start.day == weekStart.day;
  }

  bool _isLast30Days() {
    if (_filter.dateRange == null) return false;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final start = _filter.dateRange!.start;
    return start.isAtSameMomentAs(thirtyDaysAgo);
  }


  Future<void> _selectDate(bool isStart) async {
    final initialDate = _filter.dateRange?.start ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _filter = _filter.copyWith(
            dateRange: DateTimeRange(
              start: date,
              end: _filter.dateRange?.end ?? date.add(const Duration(days: 7)),
            ),
          );
        } else {
          _filter = _filter.copyWith(
            dateRange: DateTimeRange(
              start: _filter.dateRange?.start ?? date.subtract(const Duration(days: 7)),
              end: date,
            ),
          );
        }
      });
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: selected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        selectedColor: theme.colorScheme.secondaryContainer,
      ),
    );
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
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? DateFormat('MMM d, y').format(date!)
                  : 'Select Date',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
