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
  const todo = Todo(
    id: 'todo-1',
    familyId: '',
    assignedTo: 'user-1',
    createdBy: 'user-1',
    title: 'Wash dishes',
    deadline: null,
    status: false,
    createdAt: null,
    updatedAt: null,
    completedAt: null,
  );

  setUp(() {
    repository = MockTodoRepository();
    todos = StreamController<List<Todo>>();
    when(() => repository.watchTodos(familyId: null, userId: 'user-1'))
        .thenAnswer((_) => todos.stream);
  });

  tearDown(() async {
    await todos.close();
  });

  test('starts loading and emits todos from the repository stream', () async {
    final cubit = TodoCubit(repository: repository, userId: 'user-1');
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
        familyId: null,
        assignedTo: 'user-1',
        createdBy: 'user-1',
        title: '  Wash dishes  ',
        deadline: null,
      ),
    ).thenAnswer((_) async {});
    final cubit = TodoCubit(repository: repository, userId: 'user-1');

    await cubit.add('  Wash dishes  ', null, 'user-1');

    verify(
      () => repository.addTodo(
        familyId: null,
        assignedTo: 'user-1',
        createdBy: 'user-1',
        title: '  Wash dishes  ',
        deadline: null,
      ),
    ).called(1);
    await cubit.close();
  });

  test('does not write an empty todo', () async {
    final cubit = TodoCubit(repository: repository, userId: 'user-1');

    await cubit.add('   ', null, 'user-1');

    verifyNever(
      () => repository.addTodo(
        familyId: any(named: 'familyId'),
        assignedTo: any(named: 'assignedTo'),
        createdBy: any(named: 'createdBy'),
        title: any(named: 'title'),
        deadline: any(named: 'deadline'),
      ),
    );
    await cubit.close();
  });

  test('toggles completion through the repository', () async {
    when(() => repository.setStatus(todo, true)).thenAnswer((_) async {});
    final cubit = TodoCubit(repository: repository, userId: 'user-1');

    await cubit.toggle(todo, true);

    verify(() => repository.setStatus(todo, true)).called(1);
    await cubit.close();
  });
}
