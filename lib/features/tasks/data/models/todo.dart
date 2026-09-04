import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String familyId;
  final String? assignedTo;
  final String createdBy;
  final String title;
  final DateTime? deadline;

  /// True when the task has been finally completed/approved.
  final bool status;

  /// Whether creator validation is required after completion.
  final bool requiresVerification;

  /// notRequired, pending, approved, rejected
  final String verificationStatus;

  /// UID of the creator who verified the task.
  final String? verifiedBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const Todo({
    required this.id,
    required this.familyId,
    required this.assignedTo,
    required this.createdBy,
    required this.title,
    required this.deadline,
    required this.status,
    required this.requiresVerification,
    required this.verificationStatus,
    required this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
  });

  factory Todo.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};

    DateTime? readDate(String key) {
      final value = data[key];

      if (value is Timestamp) {
        return value.toDate();
      }

      return null;
    }

    String? readString(String key) {
      final value = data[key];

      if (value is String) {
        return value;
      }

      return null;
    }

    return Todo(
      id: data['todoId'] as String? ?? document.id,
      familyId: data['familyId'] as String? ?? '',
      assignedTo: readString('assignedTo'),
      createdBy: data['createdBy'] as String? ?? '',
      title: data['title'] as String? ?? '',
      deadline: readDate('deadline'),
      status: data['status'] as bool? ?? false,
      requiresVerification: data['requiresVerification'] as bool? ?? false,
      verificationStatus:
          data['verificationStatus'] as String? ?? 'notRequired',
      verifiedBy: readString('verifiedBy'),
      createdAt: readDate('createdAt'),
      updatedAt: readDate('updatedAt'),
      completedAt: readDate('completedAt'),
    );
  }

  Todo copyWith({
    String? id,
    String? familyId,
    String? assignedTo,
    bool clearAssignedTo = false,
    String? createdBy,
    String? title,
    DateTime? deadline,
    bool clearDeadline = false,
    bool? status,
    bool? requiresVerification,
    String? verificationStatus,
    String? verifiedBy,
    bool clearVerifiedBy = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Todo(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      assignedTo: clearAssignedTo ? null : assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      deadline: clearDeadline ? null : deadline ?? this.deadline,
      status: status ?? this.status,
      requiresVerification: requiresVerification ?? this.requiresVerification,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: clearVerifiedBy ? null : verifiedBy ?? this.verifiedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'todoId': id,
      'familyId': familyId,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'title': title.trim(),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'status': status,
      'requiresVerification': requiresVerification,
      'verificationStatus': verificationStatus,
      'verifiedBy': verifiedBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  bool get isUnassigned => assignedTo == null;

  bool get isCompleted => status;

  bool get isAwaitingVerification =>
      requiresVerification && verificationStatus == 'pending';

  bool get isVerified => verificationStatus == 'approved';
}
