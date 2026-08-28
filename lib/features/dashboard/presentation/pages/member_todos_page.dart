import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../family/data/models/family.dart';
import '../../../family/presentation/bloc/family_cubit.dart';
import '../../../tasks/data/repositories/todo_repository.dart';
import '../../../tasks/presentation/bloc/todo_cubit.dart';
import '../widgets/empty_state.dart';
import '../widgets/todo_dialog.dart';
import '../widgets/todo_tile.dart';

class MemberTodosPage extends StatelessWidget {
  final Family family;
  final FamilyMember member;
  final String createdBy;
  final FamilyCubit familyCubit;

  const MemberTodosPage({
    super.key,
    required this.family,
    required this.member,
    required this.createdBy,
    required this.familyCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TodoCubit(
        repository: context.read<TodoRepository>(),
        familyId: family.id,
        userId: member.id,
      ),
      child: BlocProvider.value(
        value: familyCubit,
        child: Scaffold(
          appBar: AppBar(title: Text("${member.name}'s tasks")),
          body: BlocBuilder<FamilyCubit, FamilyState>(
            builder: (context, familyState) =>
                BlocBuilder<TodoCubit, TodoState>(
                  builder: (context, state) => Stack(
                    children: [
                      if (state.todos.isEmpty)
                        const EmptyState(
                          icon: Icons.task_alt,
                          title: 'Nothing on their list',
                          message: 'Assign a task using the button below.',
                        )
                      else
                        ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          children: state.todos
                              .map(
                                (todo) => TodoTile(
                                  todo: todo,
                                  canEdit: false,
                                  creatorName: familyState.members
                                      .where(
                                        (member) => member.id == todo.createdBy,
                                      )
                                      .firstOrNull
                                      ?.name,
                                ),
                              )
                              .toList(),
                        ),
                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: FloatingActionButton.extended(
                          onPressed: () => showAssignedTodoDialog(
                            context,
                            member.id,
                            createdBy,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Assign task'),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
