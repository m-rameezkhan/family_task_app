import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_task_app/features/tasks/data/models/todo.dart';
import 'package:family_task_app/features/tasks/data/repositories/todo_repository.dart';
import 'package:family_task_app/features/tasks/presentation/bloc/todo_cubit.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late MockTodoRepository repository;
  late StreamController<List<Todo>> todos;
  const familyId = 'family-1';
  const todo = Todo(
    id: 'todo-1',
    familyId: familyId,
    assignedTo: 'user-1',
    createdBy: 'user-1',
    title: 'Wash dishes',
    description: '',
    deadline: null,
    status: false,
    requiresVerification: false,
    verifiedBy: [],
    priority: 1,
    tags: [],
    estimatedHours: null,
    createdAt: null,
    updatedAt: null,
    completedAt: null,
  );

  setUp(() {
    repository = MockTodoRepository();
    todos = StreamController<List<Todo>>();
    when(() => repository.watchTodos(familyId: familyId, userId: 'user-1'))
        .thenAnswer((_) => todos.stream);
  });

  tearDown(() async {
    await todos.close();
  });

  test('starts loading and emits todos from the repository stream', () async {
    final cubit = TodoCubit(
      repository: repository,
      familyId: familyId,
      userId: 'user-1',
    );
    expect(cubit.state.loading, isTrue);

    final nextState = expectLater(
      cubit.stream,
      emits(
        predicate<TodoState>((state) {
          return !state.loading && state.todos.single.title == 'Wash dishes';
        }),
      ),
    );
    todos.add([todo]);

    await nextState;
    await cubit.close();
  });

  test('adds a trimmed todo through the repository', () async {
    when(
      () => repository.addTodo(
        familyId: familyId,
        assignedTo: 'user-1',
        createdBy: 'user-1',
        title: '  Wash dishes  ',
        description: '',
        deadline: null,
        requiresVerification: false,
        priority: 1,
        tags: const [],
        estimatedHours: null,
      ),
    ).thenAnswer((_) async => 'todo-1');
    final cubit = TodoCubit(
      repository: repository,
      familyId: familyId,
      userId: 'user-1',
    );

    await cubit.add('  Wash dishes  ');

    verify(
      () => repository.addTodo(
        familyId: familyId,
        assignedTo: 'user-1',
        createdBy: 'user-1',
        title: '  Wash dishes  ',
        description: '',
        deadline: null,
        requiresVerification: false,
        priority: 1,
        tags: const [],
        estimatedHours: null,
      ),
    ).called(1);
    await cubit.close();
  });

  test('does not write an empty todo', () async {
    final cubit = TodoCubit(
      repository: repository,
      familyId: familyId,
      userId: 'user-1',
    );

    await cubit.add('   ');

    verifyNever(
      () => repository.addTodo(
        familyId: any(named: 'familyId'),
        assignedTo: any(named: 'assignedTo'),
        createdBy: any(named: 'createdBy'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        deadline: any(named: 'deadline'),
        requiresVerification: any(named: 'requiresVerification'),
        priority: any(named: 'priority'),
        tags: any(named: 'tags'),
        estimatedHours: any(named: 'estimatedHours'),
      ),
    );
    await cubit.close();
  });

  test('toggles completion through the repository', () async {
    when(() => repository.setStatus(familyId, 'todo-1', true))
        .thenAnswer((_) async {});
    final cubit = TodoCubit(
      repository: repository,
      familyId: familyId,
      userId: 'user-1',
    );

    await cubit.toggle('todo-1', true);

    verify(() => repository.setStatus(familyId, 'todo-1', true)).called(1);
    await cubit.close();
  });
}
