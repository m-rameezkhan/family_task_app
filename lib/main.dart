import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/services/deep_link_service.dart';
import 'features/authentication/data/repositories/auth_repository.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/pages/auth_gate.dart';
import 'features/tasks/data/datasources/task_remote_data_source.dart';
import 'features/tasks/data/repositories/task_repository.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authRepository = AuthRepository();

  final deepLinkService = DeepLinkService();

  final taskDataSource = TaskRemoteDataSource();

  final taskRepository = TaskRepository(dataSource: taskDataSource);

  runApp(
    FamilyTaskApp(
      authRepository: authRepository,
      taskRepository: taskRepository,
      deepLinkService: deepLinkService,
    ),
  );
}

class FamilyTaskApp extends StatelessWidget {
  final AuthRepository authRepository;
  final TaskRepository taskRepository;
  final DeepLinkService deepLinkService;

  const FamilyTaskApp({
    super.key,
    required this.authRepository,
    required this.taskRepository,
    required this.deepLinkService,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: RepositoryProvider.value(
        value: taskRepository,
        child: BlocProvider(
          create: (context) {
            final bloc = AuthBloc(
              authRepository: context.read<AuthRepository>(),
              deepLinkService: deepLinkService,
            );

            bloc.checkInitialDeepLink();

            return bloc;
          },
          child: BlocProvider(
            create: (context) =>
                TaskBloc(taskRepository: context.read<TaskRepository>()),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Family Task App',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
