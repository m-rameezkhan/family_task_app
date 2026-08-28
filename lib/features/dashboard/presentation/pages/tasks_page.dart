import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../family/presentation/bloc/family_cubit.dart';
import '../../../tasks/data/repositories/todo_repository.dart';
import '../../../tasks/presentation/bloc/todo_cubit.dart';
import '../widgets/empty_state.dart';
import '../widgets/todo_dialog.dart';
import '../widgets/todo_tile.dart';

class TasksPage extends StatelessWidget {
  final String userId;
  final String userName;

  const TasksPage({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyCubit, FamilyState>(
      builder: (context, familyState) {
        if (familyState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return BlocProvider(
          key: ValueKey(familyState.family?.id ?? 'personal'),
          create: (_) => TodoCubit(
            repository: context.read<TodoRepository>(),
            familyId: familyState.family?.id,
            userId: userId,
          ),
          child: _TaskListView(userName: userName),
        );
      },
    );
  }
}

class _TaskListView extends StatelessWidget {
  final String userName;

  const _TaskListView({required this.userName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoCubit, TodoState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            if (state.todos.isEmpty)
              const EmptyState(
                icon: Icons.task_alt,
                title: 'Nothing on your list',
                message: 'Add a task for yourself or ask a family member to assign one.',
              )
            else
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: state.todos
                    .map(
                      (todo) => TodoTile(
                        todo: todo,
                        canEdit: true,
                        creatorName: _creatorName(context, todo.createdBy),
                      ),
                    )
                    .toList(),
              ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: () => showTodoDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add task'),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _creatorName(BuildContext context, String creatorId) {
    final member = context
        .read<FamilyCubit>()
        .state
        .members
        .where((member) => member.id == creatorId)
        .firstOrNull;
    return member?.name ??
        (creatorId == context.read<TodoCubit>().userId ? userName : null);
  }
}
