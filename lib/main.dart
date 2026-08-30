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

  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<_AppDependencies> _dependencies = _initialize();

  Future<_AppDependencies> _initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final notificationService = NotificationService();
    await notificationService.initialize();
    return _AppDependencies(
      authRepository: AuthRepository(),
      notificationService: notificationService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppDependencies>(
      future: _dependencies,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        }
        final dependencies = snapshot.data;
        if (dependencies == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Container()),
          );
        }
        return FamilyTaskApp(
          authRepository: dependencies.authRepository,
          notificationService: dependencies.notificationService,
        );
      },
    );
  }
}

class _AppDependencies {
  final AuthRepository authRepository;
  final NotificationService notificationService;

  const _AppDependencies({
    required this.authRepository,
    required this.notificationService,
  });
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
