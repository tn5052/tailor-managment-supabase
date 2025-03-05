import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/measurement.dart';
import '../../models/complaint.dart';
import 'mobile_report_component.dart';

// This file acts as an intermediary to maintain backward compatibility
// It forwards to the appropriate implementations

class CustomerFullReportDialog extends StatelessWidget {
  final Customer customer;
  final List<Measurement> measurements;
  final List<Invoice> invoices;
  final List<Complaint> complaints;

  const CustomerFullReportDialog({
    super.key,
    required this.customer,
    required this.measurements,
    required this.invoices,
    required this.complaints,
  });

  @override
  Widget build(BuildContext context) {
    return CustomerFullReportScreen(
      customer: customer,
      measurements: measurements,
      invoices: invoices,
      complaints: complaints,
    );
  }
}
