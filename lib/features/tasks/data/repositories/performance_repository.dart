import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/performance.dart';

class PerformanceRepository {
  final FirebaseFirestore _firestore;

  PerformanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _performanceCollection(
    String familyId,
  ) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('performance');
  }

  /// Watch performance for a member (daily and monthly)
  Stream<List<Performance>> watchMemberPerformance(
    String familyId,
    String memberId, {
    String period = 'monthly', // daily, monthly, yearly
  }) {
    return _performanceCollection(familyId)
        .doc(memberId)
        .collection(period)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Performance.fromDocument).toList(),
        );
  }

  /// Watch family performance (all members)
  Stream<List<Performance>> watchFamilyPerformance(
    String familyId, {
    String period = 'monthly',
  }) {
    return _performanceCollection(familyId).snapshots().asyncMap((
      snapshot,
    ) async {
      final allPerformance = <Performance>[];
      for (final doc in snapshot.docs) {
        final memberDocs = await doc.reference
            .collection(period)
            .orderBy('date', descending: true)
            .limit(1)
            .get();
        allPerformance.addAll(memberDocs.docs.map(Performance.fromDocument));
      }
      allPerformance.sort(
        (a, b) => b.performanceScore.compareTo(a.performanceScore),
      );
      return allPerformance;
    });
  }

  /// Get current month/day performance
  Future<Performance?> getCurrentPerformance(
    String familyId,
    String memberId, {
    String period = 'monthly',
  }) async {
    final now = DateTime.now();
    final performanceDocs = await _performanceCollection(familyId)
        .doc(memberId)
        .collection(period)
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(now.year, now.month, now.day),
          ),
        )
        .limit(1)
        .get();

    if (performanceDocs.docs.isEmpty) return null;
    return Performance.fromDocument(performanceDocs.docs.first);
  }

  /// Update or create performance record
  Future<void> upsertPerformance(
    String familyId,
    String memberId,
    Performance performance,
  ) async {
    final docRef = _performanceCollection(familyId)
        .doc(memberId)
        .collection(performance.period)
        .doc();

    await docRef.set(performance.toDocument());
  }

  /// Calculate and update performance based on task completion
  /// Called after a task is marked as complete
  Future<void> updatePerformanceOnTaskCompletion(
    String familyId,
    String memberId,
    DateTime deadline,
    double estimatedHours,
  ) async {
    final now = DateTime.now();
    final period = 'monthly';

    final currentPerformance =
        await getCurrentPerformance(familyId, memberId, period: period) ??
        Performance(
          id: '',
          memberId: memberId,
          familyId: familyId,
          tasksCompleted: 0,
          tasksCompletedOnTime: 0,
          tasksCompletedLate: 0,
          totalTasksAssigned: 1,
          averageCompletionHours: 0,
          performanceScore: 0,
          period: period,
          date: now,
        );

    final isOnTime = now.isBefore(deadline) || now.isAtSameMomentAs(deadline);
    final completionHours =
        now
            .difference(
              deadline.subtract(Duration(hours: estimatedHours.toInt())),
            )
            .inHours /
        estimatedHours;

    final updatedPerformance = Performance(
      id: currentPerformance.id,
      memberId: memberId,
      familyId: familyId,
      tasksCompleted: currentPerformance.tasksCompleted + 1,
      tasksCompletedOnTime: isOnTime
          ? currentPerformance.tasksCompletedOnTime + 1
          : currentPerformance.tasksCompletedOnTime,
      tasksCompletedLate: !isOnTime
          ? currentPerformance.tasksCompletedLate + 1
          : currentPerformance.tasksCompletedLate,
      totalTasksAssigned: currentPerformance.totalTasksAssigned,
      averageCompletionHours:
          (currentPerformance.averageCompletionHours + completionHours) / 2,
      performanceScore: _calculateScore(
        currentPerformance.tasksCompleted + 1,
        isOnTime
            ? currentPerformance.tasksCompletedOnTime + 1
            : currentPerformance.tasksCompletedOnTime,
        currentPerformance.totalTasksAssigned,
      ),
      period: period,
      date: now,
      createdAt: currentPerformance.createdAt,
      updatedAt: DateTime.now(),
    );

    await upsertPerformance(familyId, memberId, updatedPerformance);
  }

  /// Calculate performance score (0-100)
  double _calculateScore(
    int tasksCompleted,
    int tasksOnTime,
    int totalAssigned,
  ) {
    if (totalAssigned == 0) return 0;

    final completionRate = (tasksCompleted / totalAssigned) * 50;
    final onTimeRate = tasksCompleted == 0
        ? 0
        : (tasksOnTime / tasksCompleted) * 50;

    return (completionRate + onTimeRate).clamp(0, 100);
  }
}
