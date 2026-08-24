import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final DateTime? deadline;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.deadline,
    required this.createdAt,
  });

  factory TaskModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return TaskModel(
      id: id,
      title: map['title'] as String,
      deadline: (map['deadline'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'deadline': deadline,
      'createdAt': createdAt,
    };
  }
}