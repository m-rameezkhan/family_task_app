import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String familyId;
  final String assignedTo; // Empty string means unassigned/all members
  final String createdBy;
  final String title;
  final String description;
  final DateTime? deadline;
  final bool status;
  final bool requiresVerification;
  final List<String> verifiedBy; // UIDs of users who verified completion
  final int priority; // 0=low, 1=medium, 2=high
  final List<String> tags; // Categories/labels
  final double? estimatedHours; // Time estimate
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const Todo({
    required this.id,
    required this.familyId,
    required this.assignedTo,
    required this.createdBy,
    required this.title,
    this.description = '',
    required this.deadline,
    required this.status,
    this.requiresVerification = false,
    this.verifiedBy = const [],
    this.priority = 1,
    this.tags = const [],
    this.estimatedHours,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
  });

  factory Todo.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();
    return Todo(
      id: data['todoId'] as String? ?? document.id,
      familyId: data['familyId'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      deadline: date('deadline'),
      status: data['status'] as bool? ?? false,
      requiresVerification: data['requiresVerification'] as bool? ?? false,
      verifiedBy: List<String>.from(data['verifiedBy'] as List? ?? []),
      priority: data['priority'] as int? ?? 1,
      tags: List<String>.from(data['tags'] as List? ?? []),
      estimatedHours: (data['estimatedHours'] as num?)?.toDouble(),
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
      completedAt: date('completedAt'),
    );
  }

  // Create a copy with modified fields
  Todo copyWith({
    String? id,
    String? familyId,
    String? assignedTo,
    String? createdBy,
    String? title,
    String? description,
    DateTime? deadline,
    bool clearDeadline = false,
    bool? status,
    bool? requiresVerification,
    List<String>? verifiedBy,
    int? priority,
    List<String>? tags,
    double? estimatedHours,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: clearDeadline ? null : deadline ?? this.deadline,
      status: status ?? this.status,
      requiresVerification: requiresVerification ?? this.requiresVerification,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'todoId': id,
      'familyId': familyId,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'title': title,
      'description': description,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'status': status,
      'requiresVerification': requiresVerification,
      'verifiedBy': verifiedBy,
      'priority': priority,
      'tags': tags,
      'estimatedHours': estimatedHours,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }
}
