import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../family/presentation/bloc/family_cubit.dart';
import '../../../tasks/data/repositories/todo_repository.dart';
import '../../../tasks/presentation/bloc/todo_cubit.dart';
import '../widgets/todo_dialog.dart';
import '../widgets/empty_state.dart';
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

        final familyId = familyState.family?.id;

        if (familyId == null || familyId.isEmpty) {
          return const EmptyState(
            icon: Icons.family_restroom_outlined,
            title: 'No family found',
            message: 'Join or create a family to manage tasks.',
          );
        }

        return BlocProvider(
          key: ValueKey(familyId),
          create: (_) => TodoCubit(
            repository: context.read<TodoRepository>(),
            familyId: familyId,
            userId: userId,
          ),
          child: _TaskListView(userId: userId, userName: userName),
        );
      },
    );
  }
}

class _TaskListView extends StatelessWidget {
  final String userId;
  final String userName;

  const _TaskListView({required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TodoCubit, TodoState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.todos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load tasks',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(state.error!, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        final pendingTasks = state.todos.where((todo) => !todo.status).toList();

        final completedTasks = state.todos
            .where((todo) => todo.status)
            .toList();

        final memberNames = {
          for (final member in context.read<FamilyCubit>().state.members)
            member.id: member.name,
        };

        final totalTasks = state.todos.length;
        final completedCount = completedTasks.length;

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          body: state.todos.isEmpty
              ? const EmptyState(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'No tasks yet',
                  message: 'Create a task for yourself, assign it to a family member, or leave it open for anyone to accept.',
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _TaskSummaryHeader(
                          total: totalTasks,
                          completed: completedCount,
                        ),
                      ),
                    ),

                    if (pendingTasks.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            'Active Tasks (${pendingTasks.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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

                            final isCreator = todo.createdBy == userId;

                            return TodoTile(
                              todo: todo,
                              userId: userId,
                              canEdit: isCreator,
                              creatorName: _creatorName(
                                context,
                                todo.createdBy,
                              ),
                              memberNames: memberNames,
                            );
                          }, childCount: pendingTasks.length),
                        ),
                      ),
                    ],

                    if (completedTasks.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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

                            final isCreator = todo.createdBy == userId;

                            return TodoTile(
                              todo: todo,
                              userId: userId,
                              canEdit: isCreator,
                              creatorName: _creatorName(
                                context,
                                todo.createdBy,
                              ),
                              memberNames: memberNames,
                            );
                          }, childCount: completedTasks.length),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showTodoDialog(context);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Task'),
          ),
        );
      },
    );
  }

  String? _creatorName(BuildContext context, String creatorId) {
    final familyCubit = context.read<FamilyCubit>();

    final member = familyCubit.state.members
        .where((member) => member.id == creatorId)
        .firstOrNull;

    if (member != null) {
      return member.name;
    }

    if (creatorId == userId) {
      return userName;
    }

    return null;
  }
}

class _TaskSummaryHeader extends StatelessWidget {
  final int total;
  final int completed;

  const _TaskSummaryHeader({required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progress = total == 0 ? 0.0 : completed / total;

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
