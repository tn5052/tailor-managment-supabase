import 'package:flutter/material.dart';

enum ComplaintStatus {
  pending,
  inProgress,
  resolved,
  closed;

  String get displayName {
    switch (this) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
    }
  }

  Color get color {
    switch (this) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.closed:
        return Colors.grey;

    }
  }
}

enum ComplaintPriority {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case ComplaintPriority.low:
        return 'Low';
      case ComplaintPriority.medium:
        return 'Medium';
      case ComplaintPriority.high:
        return 'High';

    }
  }

  Color get color {
    switch (this) {
      case ComplaintPriority.low:
        return Colors.green;
      case ComplaintPriority.medium:
        return Colors.orange;
      case ComplaintPriority.high:
        return Colors.red;

    }
  }
}

class NewComplaint {
  final String id;
  final String customerId;
  final String? invoiceId;
  final String title;
  final String? description;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final String? assignedTo;
  final String? resolutionDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? tenantId;

  // Optional fields for UI from joins
  final String? customerName;
  final String? invoiceNumber;

  NewComplaint({
    required this.id,
    required this.customerId,
    this.invoiceId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assignedTo,
    this.resolutionDetails,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.tenantId,
    this.customerName,
    this.invoiceNumber,
  });

  factory NewComplaint.fromJson(Map<String, dynamic> json) {
    return NewComplaint(
      id: json['id'],
      customerId: json['customer_id'],
      invoiceId: json['invoice_id'],
      title: json['title'],
      description: json['description'],
      status: ComplaintStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == json['status'].toString().toLowerCase(),
        orElse: () => ComplaintStatus.pending,
      ),
      priority: ComplaintPriority.values.firstWhere(
        (e) => e.name.toLowerCase() == json['priority'].toString().toLowerCase(),
        orElse: () => ComplaintPriority.medium,
      ),
      assignedTo: json['assigned_to'],
      resolutionDetails: json['resolution_details'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      tenantId: json['tenant_id'],
      customerName: json['customers'] != null ? json['customers']['name'] : null,
      invoiceNumber: json['invoices'] != null ? json['invoices']['invoice_number'].toString() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'customer_id': customerId,
      'title': title,
      'status': status.name,
      'priority': priority.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tenant_id': tenantId,
    };

    // Only include non-empty id for updates
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    // Only include invoice_id if it's not null and not empty
    if (invoiceId != null && invoiceId!.isNotEmpty) {
      json['invoice_id'] = invoiceId;
    }

    // Include optional fields only if they have values
    if (description != null && description!.isNotEmpty) {
      json['description'] = description;
    }

    if (assignedTo != null && assignedTo!.isNotEmpty) {
      json['assigned_to'] = assignedTo;
    }

    if (resolutionDetails != null && resolutionDetails!.isNotEmpty) {
      json['resolution_details'] = resolutionDetails;
    }

    if (resolvedAt != null) {
      json['resolved_at'] = resolvedAt!.toIso8601String();
    }

    return json;
  }

  NewComplaint copyWith({
    String? id,
    String? customerId,
    String? invoiceId,
    String? title,
    String? description,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    String? assignedTo,
    String? resolutionDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? tenantId,
    String? customerName,
    String? invoiceNumber,
  }) {
    return NewComplaint(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      invoiceId: invoiceId ?? this.invoiceId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      resolutionDetails: resolutionDetails ?? this.resolutionDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      tenantId: tenantId ?? this.tenantId,
      customerName: customerName ?? this.customerName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    );
  }
}
