import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FamilyTaskApp());
}

class FamilyTaskApp extends StatelessWidget {
  const FamilyTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Family Task App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Family Task App'),
        ),
        body: const Center(
          child: Text('Firebase Connected!'),
        ),
      ),
    );
  }
}