import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String familyId;
  final String assignedTo;
  final String createdBy;
  final String title;
  final DateTime? deadline;
  final bool status;
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
      deadline: date('deadline'),
      status: data['status'] as bool? ?? false,
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
      completedAt: date('completedAt'),
    );
  }
}
