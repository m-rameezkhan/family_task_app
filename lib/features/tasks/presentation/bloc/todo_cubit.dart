import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/todo.dart';
import '../../data/repositories/todo_repository.dart';

class TodoState {
  final List<Todo> todos;
  final bool loading;
  final String? error;

  const TodoState({this.todos = const [], this.loading = false, this.error});

  TodoState copyWith({
    List<Todo>? todos,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class TodoCubit extends Cubit<TodoState> {
  final TodoRepository _repository;
  final String familyId;
  final String userId;

  StreamSubscription<List<Todo>>? _subscription;

  TodoCubit({
    required TodoRepository repository,
    required this.familyId,
    required this.userId,
  }) : _repository = repository,
       super(const TodoState(loading: true)) {
    _subscribeToTodos();
  }

  void _subscribeToTodos() {
    if (familyId.isEmpty || userId.isEmpty) {
      emit(const TodoState(todos: [], loading: false));
      return;
    }

    _subscription = _repository
        .watchTodos(familyId: familyId, userId: userId)
        .listen(
          (todos) {
            emit(TodoState(todos: todos, loading: false));
          },
          onError: (Object error) {
            emit(
              TodoState(
                todos: state.todos,
                loading: false,
                error: error.toString(),
              ),
            );
          },
        );
  }

  /// Create a new task.
  ///
  /// assignedTo:
  /// null  -> open task, visible to every family member
  /// UID   -> assigned directly to that member
  Future<void> add({
    required String title,
    DateTime? deadline,
    String? assignedTo,
    bool requiresVerification = false,
  }) async {
    if (familyId.isEmpty || userId.isEmpty) {
      return;
    }

    if (title.trim().isEmpty) {
      emit(state.copyWith(error: 'Task title cannot be empty.'));
      return;
    }

    try {
      await _repository.addTodo(
        familyId: familyId,
        assignedTo: assignedTo,
        createdBy: userId,
        title: title,
        deadline: deadline,
        requiresVerification: requiresVerification,
      );

      emit(state.copyWith(clearError: true));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Update an existing task.
  Future<void> updateTodo(Todo todo) async {
    if (familyId.isEmpty) {
      return;
    }

    try {
      await _repository.updateTodo(familyId, todo);

      emit(state.copyWith(clearError: true));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Delete a task.
  Future<void> deleteTodo(String todoId) async {
    if (familyId.isEmpty || todoId.isEmpty) {
      return;
    }

    try {
      await _repository.deleteTodo(familyId, todoId);

      emit(state.copyWith(clearError: true));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Accept an open/unassigned task.
  ///
  /// If another member accepts it first, the repository transaction
  /// throws an error and the current user does not get the task.
  Future<void> acceptTodo(String todoId) async {
    if (familyId.isEmpty || userId.isEmpty || todoId.isEmpty) {
      return;
    }

    try {
      await _repository.acceptTodo(
        familyId: familyId,
        todoId: todoId,
        userId: userId,
      );

      emit(state.copyWith(clearError: true));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Complete the task assigned to the current user.
  ///
  /// With verification:
  ///     task becomes verification pending.
  ///
  /// Without verification:
  ///     task becomes completed immediately.
  Future<void> completeTodo(String todoId) async {
    if (familyId.isEmpty || userId.isEmpty || todoId.isEmpty) {
      return;
    }

    try {
      await _repository.completeTodo(
        familyId: familyId,
        todoId: todoId,
        userId: userId,
      );

      emit(state.copyWith(clearError: true));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Reopen a completed task.
  Future<void> reopenTodo(String todoId) async {
    if (familyId.isEmpty || userId.isEmpty || todoId.isEmpty) {
      return;
    }

    try {
      await _repository.reopenTodo(
        familyId: familyId,
        todoId: todoId,
        userId: userId,
      );

      emit(state.copyWith(clearError: true));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Approve completion of a task created by the current user.
  Future<void> approveTask(String todoId) async {
    if (familyId.isEmpty || userId.isEmpty || todoId.isEmpty) {
      return;
    }

    try {
      await _repository.approveTask(
        familyId: familyId,
        todoId: todoId,
        creatorId: userId,
      );

      emit(state.copyWith(clearError: true));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Reject completion of a task created by the current user.
  Future<void> rejectTask(String todoId) async {
    if (familyId.isEmpty || userId.isEmpty || todoId.isEmpty) {
      return;
    }

    try {
      await _repository.rejectTask(
        familyId: familyId,
        todoId: todoId,
        creatorId: userId,
      );

      emit(state.copyWith(clearError: true));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Clear the current error.
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
