import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class TaskRemoteDataSource {
  final FirebaseFirestore _firestore;

  TaskRemoteDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('tasks');

  Future<TaskModel> createTask({
    required String title,
    DateTime? deadline,
  }) async {
    final document = _tasksCollection.doc();

    final task = TaskModel(
      id: document.id,
      title: title,
      deadline: deadline,
      createdAt: DateTime.now(),
    );

    await document.set(task.toMap());

    return task;
  }

  Future<List<TaskModel>> getTasks() async {
    final snapshot = await _tasksCollection
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => TaskModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }
}