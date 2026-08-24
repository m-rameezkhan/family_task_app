import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepository {
  final TaskRemoteDataSource _dataSource;

  TaskRepository({
  required this._dataSource,
});

  Future<TaskModel> createTask({
    required String title,
    DateTime? deadline,
  }) {
    return _dataSource.createTask(
      title: title,
      deadline: deadline,
    );
  }

  Future<List<TaskModel>> getTasks() {
    return _dataSource.getTasks();
  }
}