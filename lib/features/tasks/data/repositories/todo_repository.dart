import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/todo.dart';

class TodoRepository {
  final FirebaseFirestore _firestore;

  TodoRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _todosCollection(String familyId) {
    return _firestore.collection('families').doc(familyId).collection('todos');
  }

  /// Watch todos assigned to or visible to a user.
  /// Empty assignedTo means unassigned, visible only to its creator.
  Stream<List<Todo>> watchTodos({String? familyId, required String userId}) {
    if (familyId == null || familyId.isEmpty) {
      return Stream.value([]);
    }

    return _todosCollection(familyId).snapshots().map((snapshot) {
      final todos = snapshot.docs.map(Todo.fromDocument).where((todo) {
        // Assigned tasks show only for the assignee.
        // Unassigned tasks stay visible to the creator.
        return todo.assignedTo == userId ||
            (todo.assignedTo.isEmpty && todo.createdBy == userId);
      }).toList();
      todos.sort(
        (a, b) =>
            (b.deadline ?? DateTime(0)).compareTo(a.deadline ?? DateTime(0)),
      );
      return todos;
    });
  }

  /// Watch all todos in a family (for admin/dashboard)
  Stream<List<Todo>> watchFamilyTodos(String familyId) {
    return _todosCollection(familyId).snapshots().map((snapshot) {
      final todos = snapshot.docs.map(Todo.fromDocument).toList();
      todos.sort(
        (a, b) =>
            (b.deadline ?? DateTime(0)).compareTo(a.deadline ?? DateTime(0)),
      );
      return todos;
    });
  }

  /// Watch todos assigned to a specific member
  Stream<List<Todo>> watchMemberTodos(String familyId, String userId) {
    return _todosCollection(
      familyId,
    ).where('assignedTo', isEqualTo: userId).snapshots().map((snapshot) {
      final todos = snapshot.docs.map(Todo.fromDocument).toList();
      todos.sort(
        (a, b) =>
            (b.deadline ?? DateTime(0)).compareTo(a.deadline ?? DateTime(0)),
      );
      return todos;
    });
  }

  /// Create a new task
  Future<String> addTodo({
    required String familyId,
    required String assignedTo, // Empty string = unassigned
    required String createdBy,
    required String title,
    String description = '',
    DateTime? deadline,
    bool requiresVerification = false,
    int priority = 1,
    List<String> tags = const [],
    double? estimatedHours,
  }) async {
    final docRef = _todosCollection(familyId).doc();
    final now = DateTime.now();

    await docRef.set({
      'todoId': docRef.id,
      'familyId': familyId,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'title': title.trim(),
      'description': description.trim(),
      'deadline': deadline != null ? Timestamp.fromDate(deadline) : null,
      'status': false,
      'requiresVerification': requiresVerification,
      'verifiedBy': [],
      'priority': priority,
      'tags': tags,
      'estimatedHours': estimatedHours,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'completedAt': null,
    });

    return docRef.id;
  }

  /// Update an existing task
  Future<void> updateTodo(String familyId, Todo todo) async {
    await _todosCollection(familyId)
        .doc(todo.id)
        .update(todo.toDocument()..['updatedAt'] = Timestamp.now());
  }

  /// Delete a task
  Future<void> deleteTodo(String familyId, String todoId) async {
    await _todosCollection(familyId).doc(todoId).delete();
  }

  /// Toggle task status (complete/incomplete)
  Future<void> setStatus(String familyId, String todoId, bool completed) async {
    await _todosCollection(familyId).doc(todoId).update({
      'status': completed,
      'updatedAt': Timestamp.now(),
      'completedAt': completed ? Timestamp.now() : null,
    });
  }

  /// Mark task as verified by a user
  Future<void> verifyTask(String familyId, String todoId, String userId) async {
    final doc = await _todosCollection(familyId).doc(todoId).get();
    if (doc.exists) {
      final verifiedBy = List<String>.from(
        doc.data()?['verifiedBy'] as List? ?? [],
      );
      if (!verifiedBy.contains(userId)) {
        verifiedBy.add(userId);
        await _todosCollection(familyId)
            .doc(todoId)
            .update({'verifiedBy': verifiedBy, 'updatedAt': Timestamp.now()});
      }
    }
  }

  /// Unverify task
  Future<void> unverifyTask(
    String familyId,
    String todoId,
    String userId,
  ) async {
    final doc = await _todosCollection(familyId).doc(todoId).get();
    if (doc.exists) {
      final verifiedBy = List<String>.from(
        doc.data()?['verifiedBy'] as List? ?? [],
      );
      verifiedBy.remove(userId);
      await _todosCollection(familyId)
          .doc(todoId)
          .update({'verifiedBy': verifiedBy, 'updatedAt': Timestamp.now()});
    }
  }

  /// Get task by ID
  Future<Todo?> getTodo(String familyId, String todoId) async {
    final doc = await _todosCollection(familyId).doc(todoId).get();
    return doc.exists ? Todo.fromDocument(doc) : null;
  }
}
