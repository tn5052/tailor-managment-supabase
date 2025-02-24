import 'package:flutter/material.dart';
import '../../models/customer_filter.dart';
import 'package:intl/intl.dart';

class CustomerFilterSheet extends StatefulWidget {
  final CustomerFilter filter;
  final Function(CustomerFilter) onFilterChanged;

  const CustomerFilterSheet({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  static void show(BuildContext context, CustomerFilter filter, Function(CustomerFilter) onFilterChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomerFilterSheet(
        filter: filter,
        onFilterChanged: onFilterChanged,
      ),
    );
  }

  @override
  State<CustomerFilterSheet> createState() => _CustomerFilterSheetState();
}

class _CustomerFilterSheetState extends State<CustomerFilterSheet> {
  late CustomerFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle and header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.filter_list, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Filter Customers',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _filter.hasActiveFilters
                          ? () {
                              setState(() {
                                _filter = const CustomerFilter();
                              });
                              widget.onFilterChanged(_filter);
                            }
                          : null,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Today',
                  icon: Icons.today,
                  selected: _isToday(),
                  onSelected: (_) => _setQuickDateRange(0),
                ),
                _FilterChip(
                  label: 'Yesterday',
                  icon: Icons.history,
                  selected: _isYesterday(),
                  onSelected: (_) => _setQuickDateRange(1),
                ),
                _FilterChip(
                  label: 'Last 7 Days',
                  icon: Icons.date_range,
                  selected: _isLast7Days(),
                  onSelected: (_) => _setQuickDateRange(7),
                ),
                _FilterChip(
                  label: 'This Month',
                  icon: Icons.calendar_month,
                  selected: _isThisMonth(),
                  onSelected: (_) => _setThisMonth(),
                ),
                _FilterChip(
                  label: 'With WhatsApp',
                  icon: Icons.message,
                  selected: _filter.hasWhatsapp,
                  onSelected: (value) {
                    setState(() {
                      _filter = _filter.copyWith(hasWhatsapp: value);
                    });
                  },
                ),
                _FilterChip(
                  label: 'Has Referrals',
                  icon: Icons.people_outline,
                  selected: _filter.isReferrer,
                  onSelected: (value) {
                    setState(() {
                      _filter = _filter.copyWith(isReferrer: value);
                    });
                  },
                ),
              ],
            ),
          ),

          // Main filters
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                _buildDateSection(theme),
                const SizedBox(height: 24),

                _buildSortingSection(theme),
                const SizedBox(height: 24),
                _buildGroupingSection(theme),
                const SizedBox(height: 24),
                _buildAdditionalFilters(theme),
              ],
            ),
          ),

          // Apply button
          Padding(
            padding: const EdgeInsets.all(24).copyWith(top: 0),
            child: FilledButton(
              onPressed: () {
                widget.onFilterChanged(_filter);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters'),
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DateButton(
                label: 'From',
                date: _filter.dateRange?.start,
                onTap: () => _selectDate(true),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward, size: 20),
            const SizedBox(width: 12),
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


  Widget _buildSortingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CustomerSortBy.values.map((sort) {
            return ChoiceChip(
              label: Text(_getSortLabel(sort)),
              selected: _filter.sortBy == sort,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _filter = _filter.copyWith(sortBy: sort);
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGroupingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group By',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CustomerGroupBy.values.map((group) {
            return ChoiceChip(
              label: Text(_getGroupLabel(group)),
              selected: _filter.groupBy == group,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _filter = _filter.copyWith(groupBy: group);
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdditionalFilters(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Filters',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
         _buildFilterSwitch(
          title: 'Top Referrers',
          subtitle: 'Show customers who brought in the most referrals',
          value: _filter.showTopReferrers,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(showTopReferrers: value);
            });
          },
          icon: Icons.star_outline,
        ),
        _buildFilterSwitch(
          title: 'Has Family Members',
          subtitle: 'Show customers who are part of a family group',
          value: _filter.hasFamilyMembers,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(hasFamilyMembers: value);
            });
          },
          icon: Icons.family_restroom,
        ),
        _buildFilterSwitch(
          title: 'Has Referrals',
          subtitle: 'Show customers who have referred others',
          value: _filter.isReferrer,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(isReferrer: value);
            });
          },
          icon: Icons.people,
        ),

      ],
    );
  }

  Widget _buildFilterSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
    );
  }

  // Helper methods for date filters
  void _setQuickDateRange(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    setState(() {
      _filter = _filter.copyWith(
        dateRange: DateTimeRange(start: start, end: end),
      );
    });
  }

  void _setThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    setState(() {
      _filter = _filter.copyWith(
        dateRange: DateTimeRange(start: start, end: now),
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

  bool _isLast7Days() {
    if (_filter.dateRange == null) return false;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final start = _filter.dateRange!.start;
    return start.isAtSameMomentAs(sevenDaysAgo);
  }

  bool _isThisMonth() {
    if (_filter.dateRange == null) return false;
    final now = DateTime.now();
    final start = _filter.dateRange!.start;
    return start.year == now.year &&
           start.month == now.month &&
           start.day == 1;
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = _filter.dateRange?.start ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _filter = _filter.copyWith(
            dateRange: DateTimeRange(
              start: date,
              end: _filter.dateRange?.end ?? DateTime.now(),
            ),
          );
        } else {
          _filter = _filter.copyWith(
            dateRange: DateTimeRange(
              start: _filter.dateRange?.start ?? date,
              end: date,
            ),
          );
        }
      });
    }
  }

  String _getSortLabel(CustomerSortBy sort) {
    switch (sort) {
      case CustomerSortBy.newest:
        return 'Newest First';
      case CustomerSortBy.oldest:
        return 'Oldest First';
      case CustomerSortBy.nameAZ:
        return 'Name (A-Z)';
      case CustomerSortBy.nameZA:
        return 'Name (Z-A)';
      case CustomerSortBy.billNumberAsc:
        return 'Bill # (Asc)';
      case CustomerSortBy.billNumberDesc:
        return 'Bill # (Desc)';
    }
  }

  String _getGroupLabel(CustomerGroupBy group) {
    switch (group) {
      case CustomerGroupBy.none:
        return 'No Grouping';
      case CustomerGroupBy.gender:
        return 'By Gender';
      case CustomerGroupBy.family:
        return 'By Family';
      case CustomerGroupBy.referrals:
        return 'By Referrals';
      case CustomerGroupBy.dateAdded:
        return 'By Date Added';
    }
  }
}

// Helper widgets
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: onSelected,
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
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
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
              date != null ? DateFormat('MMM d, y').format(date!) : 'Select Date',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: date != null
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
