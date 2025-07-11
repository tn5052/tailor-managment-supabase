import 'package:flutter/material.dart';
import 'invoice.dart';
import 'invoice_group_by.dart';

class InvoiceFilter {
  String searchQuery;
  List<InvoiceStatus> deliveryStatus;
  List<PaymentStatus> paymentStatus;
  DateTime? startDate;
  DateTime? endDate;
  DateTimeRange? creationDateRange;
  DateTimeRange? dueDateRange;
  DateTimeRange? modifiedDateRange;
  RangeValues? amountRange;
  FilterDateType selectedDateType;
  bool showOverdue;
  InvoiceGroupBy groupBy;
  bool ascending;

  InvoiceFilter({
    this.searchQuery = '',
    this.deliveryStatus = const [],
    this.paymentStatus = const [],
    this.startDate,
    this.endDate,
    this.creationDateRange,
    this.dueDateRange,
    this.modifiedDateRange,
    this.amountRange,
    this.selectedDateType = FilterDateType.creation,
    this.showOverdue = false,
    this.groupBy = InvoiceGroupBy.none,
    this.ascending = true,
  });

  InvoiceFilter copyWith({
    String? searchQuery,
    List<InvoiceStatus>? deliveryStatus,
    List<PaymentStatus>? paymentStatus,
    DateTimeRange? creationDateRange,
    DateTimeRange? dueDateRange,
    DateTimeRange? modifiedDateRange,
    RangeValues? amountRange,
    FilterDateType? selectedDateType,
    bool? showOverdue,
    InvoiceGroupBy? groupBy,
    bool? ascending,
  }) {
    return InvoiceFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      creationDateRange: creationDateRange ?? this.creationDateRange,
      dueDateRange: dueDateRange ?? this.dueDateRange,
      modifiedDateRange: modifiedDateRange ?? this.modifiedDateRange,
      amountRange: amountRange ?? this.amountRange,
      selectedDateType: selectedDateType ?? this.selectedDateType,
      showOverdue: showOverdue ?? this.showOverdue,
      groupBy: groupBy ?? this.groupBy,
      ascending: ascending ?? this.ascending,
    );
  }

  bool matchesInvoice(Invoice invoice) {
    final query = searchQuery.toLowerCase();
    if (searchQuery.isNotEmpty) {
      final matches = [
        invoice.invoiceNumber,
        invoice.customerName,
        invoice.customerBillNumber,
        invoice.customerPhone,
        invoice.id,
      ].any((field) => field.toLowerCase().contains(query));
      if (!matches) return false;
    }

    if (deliveryStatus.isNotEmpty && !deliveryStatus.contains(invoice.deliveryStatus)) {
      return false;
    }

    if (paymentStatus.isNotEmpty && !paymentStatus.contains(invoice.paymentStatus)) {
      return false;
    }

    if (showOverdue && invoice.deliveryDate.isBefore(DateTime.now()) && 
        invoice.deliveryStatus != InvoiceStatus.delivered) {
      return false;
    }

    switch (selectedDateType) {
      case FilterDateType.creation:
        if (creationDateRange != null && 
            !_isDateInRange(invoice.date, creationDateRange!)) {
          return false;
        }
        break;
      case FilterDateType.due:
        if (dueDateRange != null && 
            !_isDateInRange(invoice.deliveryDate, dueDateRange!)) {
          return false;
        }
        break;
      case FilterDateType.modified:
        // Assuming you have a lastModified field in your Invoice model
        // if (modifiedDateRange != null && 
        //     !_isDateInRange(invoice.lastModified, modifiedDateRange!)) {
        //   return false;
        // }
        break;
    }

    if (amountRange != null) {
      if (invoice.amountIncludingVat < amountRange!.start || 
          invoice.amountIncludingVat > amountRange!.end) {
        return false;
      }
    }

    return true;
  }

  bool _isDateInRange(DateTime date, DateTimeRange range) {
    return date.isAfter(range.start.subtract(const Duration(days: 1))) && 
           date.isBefore(range.end.add(const Duration(days: 1)));
  }

  bool get hasActiveFilters => 
    searchQuery.isNotEmpty ||
    deliveryStatus.isNotEmpty ||
    paymentStatus.isNotEmpty ||
    creationDateRange != null ||
    dueDateRange != null ||
    modifiedDateRange != null ||
    amountRange != null ||
    showOverdue;
}

enum FilterDateType {
  creation,
  due,
  modified,
}
