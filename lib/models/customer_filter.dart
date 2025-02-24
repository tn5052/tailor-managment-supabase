import 'package:flutter/material.dart';
import 'customer.dart';

enum CustomerSortBy {
  newest,
  oldest,
  nameAZ,
  nameZA,
  billNumberAsc,
  billNumberDesc,
}

enum CustomerGroupBy {
  none,
  gender,
  family,
  referrals,
  dateAdded,
}

class CustomerFilter {
  final String searchQuery;
  final DateTimeRange? dateRange;
  final bool onlyWithFamily;
  final bool onlyWithReferrals;
  final bool onlyRecentlyAdded;
  final Set<Gender> selectedGenders;
  final CustomerSortBy sortBy;
  final CustomerGroupBy groupBy;
  final bool hasWhatsapp;
  final bool hasAddress;
  final bool isReferrer;
  final bool hasFamilyMembers;
  final bool showTopReferrers;

  const CustomerFilter({
    this.searchQuery = '',
    this.dateRange,
    this.onlyWithFamily = false,
    this.onlyWithReferrals = false,
    this.onlyRecentlyAdded = false,
    this.selectedGenders = const {},
    this.sortBy = CustomerSortBy.newest,
    this.groupBy = CustomerGroupBy.none,
    this.hasWhatsapp = false,
    this.hasAddress = false,
    this.isReferrer = false,
    this.hasFamilyMembers = false,
    this.showTopReferrers = false,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      dateRange != null ||
      onlyWithFamily ||
      onlyWithReferrals ||
      onlyRecentlyAdded ||
      selectedGenders.isNotEmpty ||
      sortBy != CustomerSortBy.newest ||
      groupBy != CustomerGroupBy.none ||
      hasWhatsapp ||
      hasAddress ||
      isReferrer ||
      hasFamilyMembers ||
      showTopReferrers;

  CustomerFilter copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
    bool? onlyWithFamily,
    bool? onlyWithReferrals,
    bool? onlyRecentlyAdded,
    Set<Gender>? selectedGenders,
    CustomerSortBy? sortBy,
    CustomerGroupBy? groupBy,
    bool? hasWhatsapp,
    bool? hasAddress,
    bool? isReferrer,
    bool? hasFamilyMembers,
    bool? showTopReferrers,
    bool clearDateRange = false,
  }) {
    return CustomerFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      onlyWithFamily: onlyWithFamily ?? this.onlyWithFamily,
      onlyWithReferrals: onlyWithReferrals ?? this.onlyWithReferrals,
      onlyRecentlyAdded: onlyRecentlyAdded ?? this.onlyRecentlyAdded,
      selectedGenders: selectedGenders ?? this.selectedGenders,
      sortBy: sortBy ?? this.sortBy,
      groupBy: groupBy ?? this.groupBy,
      hasWhatsapp: hasWhatsapp ?? this.hasWhatsapp,
      hasAddress: hasAddress ?? this.hasAddress,
      isReferrer: isReferrer ?? this.isReferrer,
      hasFamilyMembers: hasFamilyMembers ?? this.hasFamilyMembers,
      showTopReferrers: showTopReferrers ?? this.showTopReferrers,
    );
  }
}
