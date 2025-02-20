import 'package:uuid/uuid.dart';

enum ComplaintStatus {
  pending,
  inProgress,
  resolved,
  closed,
  rejected
}

enum ComplaintPriority {
  low,
  medium,
  high,
  urgent
}

class Complaint {
  final String id;
  final String customerId;
  final String? invoiceId;
  final String title;
  final String description;
  ComplaintStatus status;
  ComplaintPriority priority;
  final DateTime createdAt;
  DateTime? resolvedAt;
  final List<ComplaintUpdate> updates;
  String assignedTo;
  final List<String> attachments;

  Complaint({
    required this.id,
    required this.customerId,
    this.invoiceId,
    required this.title,
    required this.description,
    this.status = ComplaintStatus.pending,
    this.priority = ComplaintPriority.medium,
    required this.createdAt,
    this.resolvedAt,
    this.updates = const [],
    required this.assignedTo,
    this.attachments = const [],
  });

  factory Complaint.create({
    required String customerId,
    String? invoiceId,
    required String title,
    required String description,
    required ComplaintPriority priority,
    required String assignedTo,
    List<String> attachments = const [],
  }) {
    return Complaint(
      id: const Uuid().v4(),
      customerId: customerId,
      invoiceId: invoiceId,
      title: title,
      description: description,
      priority: priority,
      createdAt: DateTime.now(),
      assignedTo: assignedTo,
      attachments: attachments,
    );
  }

  void addUpdate(String comment, String updatedBy) {
    updates.add(
      ComplaintUpdate(
        id: const Uuid().v4(),
        comment: comment,
        timestamp: DateTime.now(),
        updatedBy: updatedBy,
      ),
    );
  }

  void resolve() {
    status = ComplaintStatus.resolved;
    resolvedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'invoice_id': invoiceId,
      'title': title,
      'description': description,
      'status': status.toString(),
      'priority': priority.toString(),
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'updates': updates.map((update) => update.toMap()).toList(),
      'assigned_to': assignedTo,
      'attachments': attachments,
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'],
      customerId: map['customer_id'],
      invoiceId: map['invoice_id'],
      title: map['title'],
      description: map['description'],
      status: ComplaintStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
      ),
      priority: ComplaintPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
      ),
      createdAt: DateTime.parse(map['created_at']),
      resolvedAt: map['resolved_at'] != null 
          ? DateTime.parse(map['resolved_at']) 
          : null,
      updates: (map['updates'] as List<dynamic>)
          .map((update) => ComplaintUpdate.fromMap(update))
          .toList(),
      assignedTo: map['assigned_to'],
      attachments: List<String>.from(map['attachments']),
    );
  }
}

class ComplaintUpdate {
  final String id;
  final String comment;
  final DateTime timestamp;
  final String updatedBy;

  ComplaintUpdate({
    required this.id,
    required this.comment,
    required this.timestamp,
    required this.updatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  factory ComplaintUpdate.fromMap(Map<String, dynamic> map) {
    return ComplaintUpdate(
      id: map['id'],
      comment: map['comment'],
      timestamp: DateTime.parse(map['timestamp']),
      updatedBy: map['updated_by'],
    );
  }
}
