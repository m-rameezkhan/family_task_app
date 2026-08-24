class TaskEvent {}

class TasksLoadRequested extends TaskEvent {}

class TaskCreateRequested extends TaskEvent {
  final String title;
  final DateTime? deadline;

  TaskCreateRequested({
    required this.title,
    this.deadline,
  });
}