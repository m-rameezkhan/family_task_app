import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/authentication/data/repositories/auth_repository.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/pages/auth_gate.dart';
import 'features/tasks/data/datasources/task_remote_data_source.dart';
import 'features/tasks/data/repositories/task_repository.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepository = AuthRepository();

  final taskDataSource = TaskRemoteDataSource();

  final taskRepository = TaskRepository(
    dataSource: taskDataSource,
  );

  runApp(
    FamilyTaskApp(
      authRepository: authRepository,
      taskRepository: taskRepository,
    ),
  );
}

class FamilyTaskApp extends StatelessWidget {
  final AuthRepository authRepository;
  final TaskRepository taskRepository;

  const FamilyTaskApp({
    super.key,
    required this.authRepository,
    required this.taskRepository,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: RepositoryProvider.value(
        value: taskRepository,
        child: BlocProvider(
          create: (context) => AuthBloc(
            authRepository: context.read<AuthRepository>(),
          ),
          child: BlocProvider(
            create: (context) => TaskBloc(
              taskRepository: context.read<TaskRepository>(),
            ),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Family Task App',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                ),
                useMaterial3: true,
              ),
              home: const AuthGate(),
            ),
          ),
        ),
      ),
    );
  }
}