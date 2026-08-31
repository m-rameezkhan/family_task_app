import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../family/presentation/bloc/family_cubit.dart';
// import '../../../tasks/data/models/todo.dart';
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
    final theme = Theme.of(context);

    return BlocBuilder<TodoCubit, TodoState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingTasks = state.todos.where((t) => !t.status).toList();
        final completedTasks = state.todos.where((t) => t.status).toList();

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          body: state.todos.isEmpty
              ? const EmptyState(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'All caught up!',
                  message: 'You have no pending tasks. Add a new task for yourself or assign one to your family.',
                )
              : CustomScrollView(
                  slivers: [
                    // Task Summary Card Banner
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _TaskSummaryHeader(
                          total: state.todos.length,
                          completed: completedTasks.length,
                        ),
                      ),
                    ),

                    // Pending Tasks Section
                    if (pendingTasks.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            'Active Tasks (${pendingTasks.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final todo = pendingTasks[index];
                            return TodoTile(
                              todo: todo,
                              canEdit: true,
                              creatorName: _creatorName(
                                context,
                                todo.createdBy,
                              ),
                            );
                          }, childCount: pendingTasks.length),
                        ),
                      ),
                    ],

                    // Completed Tasks Section
                    if (completedTasks.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Text(
                            'Completed (${completedTasks.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final todo = completedTasks[index];
                            return TodoTile(
                              todo: todo,
                              canEdit: true,
                              creatorName: _creatorName(
                                context,
                                todo.createdBy,
                              ),
                            );
                          }, childCount: completedTasks.length),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showTodoDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Task'),
            elevation: 3,
          ),
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

class _TaskSummaryHeader extends StatelessWidget {
  final int total;
  final int completed;

  const _TaskSummaryHeader({required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = total == 0 ? 0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}% Done',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onPrimary.withValues(
                alpha: 0.25,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completed of $total tasks completed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
