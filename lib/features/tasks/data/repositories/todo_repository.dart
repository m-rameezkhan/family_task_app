import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/todo.dart';

class TodoRepository {
  final FirebaseFirestore _firestore;

  TodoRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _todos =>
      _firestore.collection('todos');

  Stream<List<Todo>> watchTodos({String? familyId, required String userId}) {
    Query<Map<String, dynamic>> query = _todos.where(
      'assignedTo',
      isEqualTo: userId,
    );
    if (familyId != null) {
      query = query.where('familyId', whereIn: ['', familyId]);
    }
    return query.snapshots().map((snapshot) {
      final todos = snapshot.docs.map(Todo.fromDocument).toList();
      todos.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return todos;
    });
  }

  Stream<List<Todo>> watchMemberTodos(String familyId, String userId) {
    return watchTodos(familyId: familyId, userId: userId);
  }

  Future<void> addTodo({
    String? familyId,
    required String assignedTo,
    required String createdBy,
    required String title,
    DateTime? deadline,
  }) async {
    final document = _todos.doc();
    final now = FieldValue.serverTimestamp();
    await document.set({
      'todoId': document.id,
      'familyId': familyId ?? '',
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'title': title.trim(),
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline),
      'status': false,
      'createdAt': now,
      'updatedAt': now,
      'completedAt': null,
    });
  }

  Future<void> setStatus(Todo todo, bool completed) {
    return _todos.doc(todo.id).update({
      'status': completed,
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': completed ? FieldValue.serverTimestamp() : null,
    });
  }
}
