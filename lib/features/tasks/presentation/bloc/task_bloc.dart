import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _taskRepository;

  TaskBloc({
    required this._taskRepository,
  }) : super(TaskInitial()) {
    on<TasksLoadRequested>(_onTasksLoadRequested);
    on<TaskCreateRequested>(_onTaskCreateRequested);
  }

  Future<void> _onTasksLoadRequested(
    TasksLoadRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());

    try {
      final tasks = await _taskRepository.getTasks();

      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(
        TaskFailure(
          'Failed to load tasks.',
        ),
      );
    }
  }

  Future<void> _onTaskCreateRequested(
    TaskCreateRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskRepository.createTask(
        title: event.title,
        deadline: event.deadline,
      );

      final tasks = await _taskRepository.getTasks();

      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(
        TaskFailure(
          'Failed to create task.',
        ),
      );
    }
  }
}