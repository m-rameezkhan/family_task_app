import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/family/data/repositories/family_repository.dart';
import 'features/tasks/data/repositories/todo_repository.dart';
import 'core/notifications/notification_service.dart';

import 'features/authentication/data/repositories/auth_repository.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/pages/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notificationService = NotificationService();
  await notificationService.initialize();

  final authRepository = AuthRepository();

  runApp(
    FamilyTaskApp(
      authRepository: authRepository,
      notificationService: notificationService,
    ),
  );
}

class FamilyTaskApp extends StatelessWidget {
  final AuthRepository authRepository;
  final NotificationService notificationService;

  const FamilyTaskApp({
    super.key,
    required this.authRepository,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (_) => FamilyRepository()),
          RepositoryProvider(create: (_) => TodoRepository()),
        ],
        child: BlocProvider(
          create: (context) => AuthBloc(
            authRepository: context.read<AuthRepository>(),
            notificationService: notificationService,
          ),
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
    );
  }
}
