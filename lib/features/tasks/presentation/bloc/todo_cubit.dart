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

  Future<void> add(String title, DateTime? deadline, String createdBy) async {
    if (title.trim().isEmpty) return;
    try {
      await _repository.addTodo(
        familyId: familyId,
        assignedTo: userId,
        createdBy: createdBy,
        title: title,
        deadline: deadline,
      );
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> toggle(Todo todo, bool completed) async {
    try {
      await _repository.setStatus(todo, completed);
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
