import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/todo.dart';

class TodoRepository {
  final FirebaseFirestore _firestore;

  TodoRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _todosCollection(String familyId) {
    return _firestore.collection('families').doc(familyId).collection('todos');
  }

  /// Watch tasks visible to the current user.
  ///
  /// A user can see:
  /// 1. Tasks assigned to them.
  /// 2. Open/unassigned tasks.
  Stream<List<Todo>> watchTodos({
    required String familyId,
    required String userId,
  }) {
    if (familyId.isEmpty || userId.isEmpty) {
      return Stream.value([]);
    }

    return _todosCollection(familyId).snapshots().map((snapshot) {
      final todos = snapshot.docs
          .map(Todo.fromDocument)
          .where((todo) => todo.assignedTo == userId || todo.assignedTo == null)
          .toList();

      _sortTodos(todos);

      return todos;
    });
  }

  /// Watch every task in the family.
  ///
  /// Useful for family/admin screens.
  Stream<List<Todo>> watchFamilyTodos(String familyId) {
    if (familyId.isEmpty) {
      return Stream.value([]);
    }

    return _todosCollection(familyId).snapshots().map((snapshot) {
      final todos = snapshot.docs.map(Todo.fromDocument).toList();

      _sortTodos(todos);

      return todos;
    });
  }

  /// Get one task.
  Future<Todo?> getTodo(String familyId, String todoId) async {
    final doc = await _todosCollection(familyId).doc(todoId).get();

    if (!doc.exists) {
      return null;
    }

    return Todo.fromDocument(doc);
  }

  /// Create a new task.
  ///
  /// assignedTo == null means the task is open/unassigned.
  Future<String> addTodo({
    required String familyId,
    required String? assignedTo,
    required String createdBy,
    required String title,
    DateTime? deadline,
    bool requiresVerification = false,
  }) async {
    final trimmedTitle = title.trim();

    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Task title cannot be empty.');
    }

    final docRef = _todosCollection(familyId).doc();
    final now = Timestamp.now();

    await docRef.set({
      'todoId': docRef.id,
      'familyId': familyId,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'title': trimmedTitle,
      'deadline': deadline != null ? Timestamp.fromDate(deadline) : null,
      'status': false,
      'requiresVerification': requiresVerification,
      'verificationStatus': 'notRequired',
      'verifiedBy': null,
      'createdAt': now,
      'updatedAt': now,
      'completedAt': null,
    });

    return docRef.id;
  }

  /// Update an existing task.
  Future<void> updateTodo(String familyId, Todo todo) async {
    await _todosCollection(familyId)
        .doc(todo.id)
        .update({...todo.toDocument(), 'updatedAt': Timestamp.now()});
  }

  /// Delete a task.
  Future<void> deleteTodo(String familyId, String todoId) async {
    await _todosCollection(familyId).doc(todoId).delete();
  }

  /// Accept/claim an open task.
  ///
  /// A Firestore transaction is used so that if two family members
  /// tap Accept at almost the same time, only one member gets the task.
  Future<void> acceptTodo({
    required String familyId,
    required String todoId,
    required String userId,
  }) async {
    final docRef = _todosCollection(familyId).doc(todoId);

    String? _readString(dynamic value) {
      return value is String ? value : null;
    }

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw StateError('Task no longer exists.');
      }

      final data = snapshot.data() ?? {};

      final assignedTo = _readString(data['assignedTo']);

      if (assignedTo != null) {
        throw StateError(
          'This task has already been accepted by another member.',
        );
      }

      transaction.update(docRef, {
        'assignedTo': userId,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  /// Member completes a task.
  ///
  /// If verification is required:
  ///     verificationStatus = pending
  ///     status remains false
  ///
  /// Otherwise:
  ///     status = true
  ///     verificationStatus = notRequired
  Future<void> completeTodo({
    required String familyId,
    required String todoId,
    required String userId,
  }) async {
    final docRef = _todosCollection(familyId).doc(todoId);
    String? _readString(dynamic value) {
      return value is String ? value : null;
    }

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw StateError('Task no longer exists.');
      }

      final data = snapshot.data() ?? {};

      final assignedTo = _readString(data['assignedTo']);

      if (assignedTo != userId) {
        throw StateError('Only the assigned member can complete this task.');
      }

      final status = data['status'] as bool? ?? false;

      if (status) {
        throw StateError('Task is already completed.');
      }

      final requiresVerification =
          data['requiresVerification'] as bool? ?? false;

      final now = Timestamp.now();

      if (requiresVerification) {
        transaction.update(docRef, {
          'status': false,
          'verificationStatus': 'pending',
          'verifiedBy': null,
          'completedAt': now,
          'updatedAt': now,
        });
      } else {
        transaction.update(docRef, {
          'status': true,
          'verificationStatus': 'notRequired',
          'verifiedBy': null,
          'completedAt': now,
          'updatedAt': now,
        });
      }
    });
  }

  /// Reopen a task.
  ///
  /// Used when a completed task needs to become pending again.
  Future<void> reopenTodo({
    required String familyId,
    required String todoId,
    required String userId,
  }) async {
    final docRef = _todosCollection(familyId).doc(todoId);

    final snapshot = await docRef.get();
    String? _readString(dynamic value) {
      return value is String ? value : null;
    }

    if (!snapshot.exists) {
      throw StateError('Task no longer exists.');
    }

    final data = snapshot.data() ?? {};
    final assignedTo = _readString(data['assignedTo']);

    if (assignedTo != userId) {
      throw StateError('Only the assigned member can reopen this task.');
    }

    await docRef.update({
      'status': false,
      'verificationStatus': 'notRequired',
      'verifiedBy': null,
      'completedAt': null,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Creator approves a task completion.
  ///
  /// Only the task creator is allowed to approve.
  Future<void> approveTask({
    required String familyId,
    required String todoId,
    required String creatorId,
  }) async {
    final docRef = _todosCollection(familyId).doc(todoId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw StateError('Task no longer exists.');
      }

      final data = snapshot.data() ?? {};

      final createdBy = data['createdBy'] as String? ?? '';

      if (createdBy != creatorId) {
        throw StateError('Only the task creator can verify completion.');
      }

      final requiresVerification =
          data['requiresVerification'] as bool? ?? false;

      final verificationStatus =
          data['verificationStatus'] as String? ?? 'notRequired';

      if (!requiresVerification || verificationStatus != 'pending') {
        throw StateError('This task is not waiting for verification.');
      }

      transaction.update(docRef, {
        'status': true,
        'verificationStatus': 'approved',
        'verifiedBy': creatorId,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  /// Creator rejects a task completion.
  ///
  /// The task becomes pending again so the assigned member
  /// can work on it and submit it again.
  Future<void> rejectTask({
    required String familyId,
    required String todoId,
    required String creatorId,
  }) async {
    final docRef = _todosCollection(familyId).doc(todoId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw StateError('Task no longer exists.');
      }

      final data = snapshot.data() ?? {};

      final createdBy = data['createdBy'] as String? ?? '';

      if (createdBy != creatorId) {
        throw StateError('Only the task creator can reject completion.');
      }

      final requiresVerification =
          data['requiresVerification'] as bool? ?? false;

      final verificationStatus =
          data['verificationStatus'] as String? ?? 'notRequired';

      if (!requiresVerification || verificationStatus != 'pending') {
        throw StateError('This task is not waiting for verification.');
      }

      transaction.update(docRef, {
        'status': false,
        'verificationStatus': 'rejected',
        'verifiedBy': null,
        'completedAt': null,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  void _sortTodos(List<Todo> todos) {
    todos.sort((a, b) {
      // Tasks without a deadline go after tasks with deadlines.
      if (a.deadline == null && b.deadline == null) {
        return (b.createdAt ?? DateTime(0)).compareTo(
          a.createdAt ?? DateTime(0),
        );
      }

      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;

      return a.deadline!.compareTo(b.deadline!);
    });
  }
}
