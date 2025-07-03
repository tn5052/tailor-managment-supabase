import 'package:flutter/material.dart';

enum MeasurementGroupBy {
  none,
  customer,
  date,
  month,
  style,
  designType,
  tarbooshType, // Added tarbooshType
}

enum MeasurementSortBy { date, customerName, style, designType }

class MeasurementFilter {
  final String searchQuery;
  final DateTimeRange? dateRange;
  final String? style;
  final bool onlyRepeatCustomers;
  final bool onlyRecentUpdates;
  final String? designType;
  final String? tarbooshType; // Added tarbooshType
  final double? minMeasurements;
  final bool showActive;
  final MeasurementGroupBy groupBy;
  final MeasurementSortBy sortBy; // Added sortBy
  final bool sortAscending; // Added sortAscending
  final RangeValues? lengthRange;
  final RangeValues? chestRange;
  final RangeValues? sleeveRange;

  const MeasurementFilter({
    this.searchQuery = '',
    this.dateRange,
    this.style,
    this.onlyRepeatCustomers = false,
    this.onlyRecentUpdates = false,
    this.designType,
    this.tarbooshType, // Added tarbooshType
    this.minMeasurements,
    this.showActive = true,
    this.groupBy = MeasurementGroupBy.none,
    this.sortBy = MeasurementSortBy.date, // Added sortBy with default
    this.sortAscending = true, // Added sortAscending with default
    this.lengthRange,
    this.chestRange,
    this.sleeveRange,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      dateRange != null ||
      style != null ||
      onlyRepeatCustomers ||
      onlyRecentUpdates ||
      designType != null ||
      tarbooshType != null || // Added tarbooshType
      minMeasurements != null ||
      !showActive ||
      groupBy != MeasurementGroupBy.none ||
      sortBy != MeasurementSortBy.date || // Added sortBy
      !sortAscending ||
      lengthRange != null ||
      chestRange != null ||
      sleeveRange != null;

  MeasurementFilter copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
    String? style,
    bool? onlyRepeatCustomers,
    bool? onlyRecentUpdates,
    String? designType,
    String? tarbooshType, // Added tarbooshType
    double? minMeasurements,
    bool? showActive,
    MeasurementGroupBy? groupBy,
    MeasurementSortBy? sortBy, // Added sortBy
    bool? sortAscending, // Added sortAscending
    RangeValues? lengthRange,
    RangeValues? chestRange,
    RangeValues? sleeveRange,
  }) {
    return MeasurementFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: dateRange ?? this.dateRange,
      style: style ?? this.style,
      onlyRepeatCustomers: onlyRepeatCustomers ?? this.onlyRepeatCustomers,
      onlyRecentUpdates: onlyRecentUpdates ?? this.onlyRecentUpdates,
      designType: designType ?? this.designType,
      tarbooshType: tarbooshType ?? this.tarbooshType, // Added tarbooshType
      minMeasurements: minMeasurements ?? this.minMeasurements,
      showActive: showActive ?? this.showActive,
      groupBy: groupBy ?? this.groupBy,
      sortBy: sortBy ?? this.sortBy, // Added sortBy
      sortAscending: sortAscending ?? this.sortAscending, // Added sortAscending
      lengthRange: lengthRange ?? this.lengthRange,
      chestRange: chestRange ?? this.chestRange,
      sleeveRange: sleeveRange ?? this.sleeveRange,
    );
  }
}
