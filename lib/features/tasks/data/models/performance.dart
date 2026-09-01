import 'package:cloud_firestore/cloud_firestore.dart';

class Performance {
  final String id;
  final String memberId;
  final String familyId;
  final int tasksCompleted;
  final int tasksCompletedOnTime;
  final int tasksCompletedLate;
  final int totalTasksAssigned;
  final double averageCompletionHours;
  final double performanceScore; // 0-100
  final String period; // daily, monthly, yearly
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Performance({
    required this.id,
    required this.memberId,
    required this.familyId,
    required this.tasksCompleted,
    required this.tasksCompletedOnTime,
    required this.tasksCompletedLate,
    required this.totalTasksAssigned,
    required this.averageCompletionHours,
    required this.performanceScore,
    required this.period,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory Performance.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();
    return Performance(
      id: document.id,
      memberId: data['memberId'] as String? ?? '',
      familyId: data['familyId'] as String? ?? '',
      tasksCompleted: data['tasksCompleted'] as int? ?? 0,
      tasksCompletedOnTime: data['tasksCompletedOnTime'] as int? ?? 0,
      tasksCompletedLate: data['tasksCompletedLate'] as int? ?? 0,
      totalTasksAssigned: data['totalTasksAssigned'] as int? ?? 0,
      averageCompletionHours:
          (data['averageCompletionHours'] as num?)?.toDouble() ?? 0,
      performanceScore: (data['performanceScore'] as num?)?.toDouble() ?? 0,
      period: data['period'] as String? ?? 'daily',
      date: date('date') ?? DateTime.now(),
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
    );
  }

  // Calculate completion rate
  double get completionRate {
    if (totalTasksAssigned == 0) return 0;
    return (tasksCompleted / totalTasksAssigned) * 100;
  }

  // Calculate on-time rate
  double get onTimeRate {
    if (tasksCompleted == 0) return 0;
    return (tasksCompletedOnTime / tasksCompleted) * 100;
  }

  // Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'memberId': memberId,
      'familyId': familyId,
      'tasksCompleted': tasksCompleted,
      'tasksCompletedOnTime': tasksCompletedOnTime,
      'tasksCompletedLate': tasksCompletedLate,
      'totalTasksAssigned': totalTasksAssigned,
      'averageCompletionHours': averageCompletionHours,
      'performanceScore': performanceScore,
      'period': period,
      'date': Timestamp.fromDate(date),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
