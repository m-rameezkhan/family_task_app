import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_model.dart';

class TaskRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  TaskRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('tasks');

  String get _currentUserId {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    return user.uid;
  }

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
      createdBy: _currentUserId,
    );

    await document.set(task.toMap());

    return task;
  }

  Future<List<TaskModel>> getTasks() async {
    final snapshot = await _tasksCollection
        .where('createdBy', isEqualTo: _currentUserId)
        .get();

    final tasks = snapshot.docs
        .map((doc) => TaskModel.fromMap(doc.id, doc.data()))
        .toList();

    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return tasks;
  }
}
