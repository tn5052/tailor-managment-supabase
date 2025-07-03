import 'new_complaint_model.dart';

class ComplaintFilter {
  final Set<ComplaintStatus> statuses;
  final Set<ComplaintPriority> priorities;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? customerId;
  final String? assignedTo;

  ComplaintFilter({
    this.statuses = const {},
    this.priorities = const {},
    this.startDate,
    this.endDate,
    this.customerId,
    this.assignedTo,
  });

  bool get isActive =>
      statuses.isNotEmpty ||
      priorities.isNotEmpty ||
      startDate != null ||
      endDate != null ||
      customerId != null ||
      assignedTo != null;

  ComplaintFilter copyWith({
    Set<ComplaintStatus>? statuses,
    Set<ComplaintPriority>? priorities,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? assignedTo,
  }) {
    return ComplaintFilter(
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      customerId: customerId ?? this.customerId,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}
