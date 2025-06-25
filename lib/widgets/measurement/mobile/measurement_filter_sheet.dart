import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/measurement_filter.dart';
import '../../../theme/inventory_design_config.dart';

class MeasurementFilterSheet extends StatefulWidget {
  final MeasurementFilter currentFilter;
  final Function(MeasurementFilter) onFilterApplied;

  const MeasurementFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onFilterApplied,
  });

  static Future<void> show(
    BuildContext context,
    MeasurementFilter currentFilter,
    Function(MeasurementFilter) onFilterApplied,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => MeasurementFilterSheet(
            currentFilter: currentFilter,
            onFilterApplied: onFilterApplied,
          ),
    );
  }

  @override
  State<MeasurementFilterSheet> createState() => _MeasurementFilterSheetState();
}

class _MeasurementFilterSheetState extends State<MeasurementFilterSheet> {
  late MeasurementFilter _filter;

  final List<String> _styleOptions = [
    'Emirati',
    'Kuwaiti',
    'Saudi',
    'Omani',
    'Qatari',
  ];

  final List<String> _designOptions = ['Aadi', 'Baat'];

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Row(
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
                  size: 20,
                  color: InventoryDesignConfig.primaryColor,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Measurements',
                      style: InventoryDesignConfig.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Refine your measurement list',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                    ),
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
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Style Filter
          _buildSection(
            title: 'Style',
            icon: PhosphorIcons.star(),
            child: _buildChipGroup(
              options: ['All Styles', ..._styleOptions],
              selectedOption: _filter.style ?? 'All Styles',
              onSelectionChanged: (value) {
                setState(() {
                  _filter = _filter.copyWith(
                    style: value == 'All Styles' ? null : value,
                  );
                });
              },
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXL),

          // Design Type Filter
          _buildSection(
            title: 'Design Type',
            icon: PhosphorIcons.palette(),
            child: _buildChipGroup(
              options: ['All Designs', ..._designOptions],
              selectedOption: _filter.designType ?? 'All Designs',
              onSelectionChanged: (value) {
                setState(() {
                  _filter = _filter.copyWith(
                    designType: value == 'All Designs' ? null : value,
                  );
                });
              },
            ),
          ),

          const SizedBox(height: InventoryDesignConfig.spacingXL),

          // Sort Options
          _buildSection(
            title: 'Sort By',
            icon: PhosphorIcons.sortAscending(),
            child: _buildSortOptions(),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        child,
      ],
    );
  }

  Widget _buildChipGroup({
    required List<String> options,
    required String selectedOption,
    required Function(String) onSelectionChanged,
  }) {
    return Wrap(
      spacing: InventoryDesignConfig.spacingM,
      runSpacing: InventoryDesignConfig.spacingM,
      children:
          options.map((option) {
            final isSelected = selectedOption == option;
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: InkWell(
                onTap: () => onSelectionChanged(option),
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: InventoryDesignConfig.spacingL,
                    vertical: InventoryDesignConfig.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? InventoryDesignConfig.primaryColor
                            : InventoryDesignConfig.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color:
                          isSelected
                              ? InventoryDesignConfig.primaryColor
                              : InventoryDesignConfig.borderPrimary,
                    ),
                  ),
                  child: Text(
                    option,
                    style: InventoryDesignConfig.bodyMedium.copyWith(
                      color:
                          isSelected
                              ? InventoryDesignConfig.surfaceColor
                              : InventoryDesignConfig.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSortOptions() {
    final sortOptions = [
      {'value': MeasurementSortBy.date, 'label': 'Date (Newest)'},
      {'value': MeasurementSortBy.customerName, 'label': 'Customer Name'},
      {'value': MeasurementSortBy.style, 'label': 'Style'},
    ];

    return Column(
      children:
          sortOptions.map((option) {
            final isSelected = _filter.sortBy == option['value'];
            return Container(
              margin: const EdgeInsets.only(
                bottom: InventoryDesignConfig.spacingS,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _filter = _filter.copyWith(
                        sortBy: option['value'] as MeasurementSortBy,
                      );
                    });
                  },
                  borderRadius: BorderRadius.circular(
                    InventoryDesignConfig.radiusM,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(
                      InventoryDesignConfig.spacingM,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? InventoryDesignConfig.primaryColor.withOpacity(
                                0.1,
                              )
                              : InventoryDesignConfig.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusM,
                      ),
                      border: Border.all(
                        color:
                            isSelected
                                ? InventoryDesignConfig.primaryColor
                                : InventoryDesignConfig.borderPrimary,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? PhosphorIcons.checkCircle()
                              : PhosphorIcons.circle(),
                          size: 18,
                          color:
                              isSelected
                                  ? InventoryDesignConfig.primaryColor
                                  : InventoryDesignConfig.textSecondary,
                        ),
                        const SizedBox(width: InventoryDesignConfig.spacingM),
                        Expanded(
                          child: Text(
                            option['label'] as String,
                            style: InventoryDesignConfig.bodyMedium.copyWith(
                              color:
                                  isSelected
                                      ? InventoryDesignConfig.primaryColor
                                      : InventoryDesignConfig.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingL + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          top: BorderSide(color: InventoryDesignConfig.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _filter = const MeasurementFilter();
                  });
                },
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: InventoryDesignConfig.spacingL,
                  ),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color: InventoryDesignConfig.borderPrimary,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.arrowClockwise(),
                        size: 18,
                        color: InventoryDesignConfig.textSecondary,
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingS),
                      Text(
                        'Clear All',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              child: InkWell(
                onTap: () {
                  widget.onFilterApplied(_filter);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusM,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: InventoryDesignConfig.spacingL,
                  ),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.primaryColor,
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.check(),
                        size: 18,
                        color: InventoryDesignConfig.surfaceColor,
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingS),
                      Text(
                        'Apply Filters',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.surfaceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
