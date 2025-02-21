import 'package:flutter/material.dart';

enum MeasurementGroupBy {
  none,
  customer,
  date,
  month,
  style,
  designType
}

class MeasurementFilter {
  final String searchQuery;
  final DateTimeRange? dateRange;
  final String? style;
  final bool onlyRepeatCustomers;
  final bool onlyRecentUpdates;
  final String? designType;
  final double? minMeasurements;
  final bool showActive;
  final MeasurementGroupBy groupBy;

  const MeasurementFilter({
    this.searchQuery = '',
    this.dateRange,
    this.style,
    this.onlyRepeatCustomers = false,
    this.onlyRecentUpdates = false,
    this.designType,
    this.minMeasurements,
    this.showActive = true,
    this.groupBy = MeasurementGroupBy.none,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      dateRange != null ||
      style != null ||
      onlyRepeatCustomers ||
      onlyRecentUpdates ||
      designType != null ||
      minMeasurements != null ||
      !showActive ||
      groupBy != MeasurementGroupBy.none;

  MeasurementFilter copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
    String? style,
    bool? onlyRepeatCustomers,
    bool? onlyRecentUpdates,
    String? designType,
    double? minMeasurements,
    bool? showActive,
    MeasurementGroupBy? groupBy,
  }) {
    return MeasurementFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: dateRange ?? this.dateRange,
      style: style ?? this.style,
      onlyRepeatCustomers: onlyRepeatCustomers ?? this.onlyRepeatCustomers,
      onlyRecentUpdates: onlyRecentUpdates ?? this.onlyRecentUpdates,
      designType: designType ?? this.designType,
      minMeasurements: minMeasurements ?? this.minMeasurements,
      showActive: showActive ?? this.showActive,
      groupBy: groupBy ?? this.groupBy,
    );
  }
}
