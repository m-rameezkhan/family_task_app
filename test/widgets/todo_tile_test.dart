import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_task_app/features/dashboard/presentation/widgets/todo_tile.dart';
import 'package:family_task_app/features/tasks/data/models/todo.dart';
import 'package:family_task_app/features/tasks/presentation/bloc/todo_cubit.dart';

class MockTodoCubit extends Mock implements TodoCubit {}

void main() {
  const todo = Todo(
    id: 'todo-1',
    familyId: 'family-1',
    assignedTo: 'user-1',
    createdBy: 'user-2',
    title: 'Take out trash',
    deadline: null,
    status: false,
    createdAt: null,
    updatedAt: null,
    completedAt: null,
  );

  testWidgets('assigned user can mark a todo complete', (tester) async {
    final cubit = MockTodoCubit();
    when(() => cubit.stream).thenAnswer((_) => Stream<TodoState>.empty());
    when(() => cubit.toggle(todo, true)).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<TodoCubit>.value(
          value: cubit,
          child: const Scaffold(body: TodoTile(todo: todo, canEdit: true)),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    verify(() => cubit.toggle(todo, true)).called(1);
  });

  testWidgets('other family members see a todo without a checkbox', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TodoTile(todo: todo, canEdit: false)),
      ),
    );

    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Take out trash'), findsOneWidget);
  });
}
