import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/todo.dart';
import '../../data/repositories/todo_repository.dart';

class TodoState {
  final List<Todo> todos;
  final bool loading;
  final String? error;

  const TodoState({this.todos = const [], this.loading = false, this.error});

  TodoState copyWith({List<Todo>? todos, bool? loading, String? error}) {
    return TodoState(
      todos: todos ?? this.todos,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class TodoCubit extends Cubit<TodoState> {
  final TodoRepository _repository;
  final String? familyId;
  final String userId;
  StreamSubscription<List<Todo>>? _subscription;

  TodoCubit({required this._repository, this.familyId, required this.userId})
    : super(const TodoState(loading: true)) {
    _subscription = _repository
        .watchTodos(familyId: familyId, userId: userId)
        .listen(
          (todos) => emit(TodoState(todos: todos)),
          onError: (Object error) => emit(TodoState(error: error.toString())),
        );
  }

  Future<void> add(
    String title, {
    String description = '',
    DateTime? deadline,
    String? assignedTo,
    bool requiresVerification = false,
    int priority = 1,
    List<String> tags = const [],
    double? estimatedHours,
  }) async {
    if (title.trim().isEmpty || familyId == null || familyId!.isEmpty) return;
    try {
      await _repository.addTodo(
        familyId: familyId!,
        assignedTo: assignedTo ?? '',
        createdBy: userId,
        title: title,
        description: description,
        deadline: deadline,
        requiresVerification: requiresVerification,
        priority: priority,
        tags: tags,
        estimatedHours: estimatedHours,
      );
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> toggle(String todoId, bool completed) async {
    if (familyId == null || familyId!.isEmpty) return;
    try {
      await _repository.setStatus(familyId!, todoId, completed);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> updateTodo(Todo todo) async {
    if (familyId == null || familyId!.isEmpty) return;
    try {
      await _repository.updateTodo(familyId!, todo);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> deleteTodo(String todoId) async {
    if (familyId == null || familyId!.isEmpty) return;
    try {
      await _repository.deleteTodo(familyId!, todoId);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> verifyTask(String todoId, String userId) async {
    if (familyId == null || familyId!.isEmpty) return;
    try {
      await _repository.verifyTask(familyId!, todoId, userId);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> unverifyTask(String todoId, String userId) async {
    if (familyId == null || familyId!.isEmpty) return;
    try {
      await _repository.unverifyTask(familyId!, todoId, userId);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
