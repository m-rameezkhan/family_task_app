import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../tasks/data/models/todo.dart';
import '../../../tasks/presentation/bloc/todo_cubit.dart';
import '../../../tasks/presentation/pages/task_detail_page.dart';
import '../../../family/presentation/bloc/family_cubit.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final String userId;
  final bool canEdit;
  final String? creatorName;
  final Map<String, String> memberNames;

  const TodoTile({
    super.key,
    required this.todo,
    required this.userId,
    required this.canEdit,
    this.creatorName,
    this.memberNames = const {},
  });

  Future<void> _openDetails(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<TodoCubit>()),
            BlocProvider.value(value: context.read<FamilyCubit>()),
          ],
          child: TaskDetailPage(
            todo: todo,
            userId: userId,
            canEdit: canEdit,
            memberNames: memberNames,
          ),
        ),
      ),
    );
  }

  Future<void> _acceptTask(BuildContext context) async {
    await context.read<TodoCubit>().acceptTodo(todo.id);

    if (!context.mounted) return;

    final error = context.read<TodoCubit>().state.error;

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task accepted successfully')));
  }

  Future<void> _completeTask(BuildContext context) async {
    await context.read<TodoCubit>().completeTodo(todo.id);

    if (!context.mounted) return;

    final error = context.read<TodoCubit>().state.error;

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          todo.requiresVerification
              ? 'Task submitted for verification'
              : 'Task completed successfully',
        ),
      ),
    );
  }

  String _assignmentText() {
    if (todo.assignedTo == null) {
      return 'Open task';
    }

    if (todo.assignedTo == userId) {
      return 'Assigned to you';
    }

    return 'Assigned to '
        '${memberNames[todo.assignedTo] ?? 'Family member'}';
  }

  String _statusText() {
    if (todo.status) {
      return 'Completed';
    }

    if (todo.isAwaitingVerification) {
      return 'Waiting for verification';
    }

    if (todo.verificationStatus == 'rejected') {
      return 'Completion rejected';
    }

    if (todo.assignedTo == null) {
      return 'Available to accept';
    }

    return 'Pending';
  }

  IconData _statusIcon() {
    if (todo.status) {
      return Icons.check_circle_rounded;
    }

    if (todo.isAwaitingVerification) {
      return Icons.pending_actions_rounded;
    }

    if (todo.verificationStatus == 'rejected') {
      return Icons.cancel_outlined;
    }

    if (todo.assignedTo == null) {
      return Icons.assignment_outlined;
    }

    return Icons.pending_outlined;
  }

  Color _statusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (todo.status) {
      return colorScheme.primary;
    }

    if (todo.isAwaitingVerification) {
      return colorScheme.tertiary;
    }

    if (todo.verificationStatus == 'rejected') {
      return colorScheme.error;
    }

    return colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isAssignedToMe = todo.assignedTo == userId;

    final isOpenTask = todo.assignedTo == null;

    final canComplete =
        isAssignedToMe && !todo.status && !todo.isAwaitingVerification;

    final canAccept = isOpenTask && !todo.status;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _statusColor(context).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(),
                      color: _statusColor(context),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: todo.status
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _assignmentText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'details') {
                        await _openDetails(context);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'details',
                        child: Text('View details'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusChip(
                    icon: _statusIcon(),
                    label: _statusText(),
                    color: _statusColor(context),
                  ),
                  if (todo.deadline != null)
                    _StatusChip(
                      icon: Icons.schedule_rounded,
                      label: formatTimeRemaining(todo.deadline),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  if (todo.requiresVerification)
                    _StatusChip(
                      icon: Icons.verified_outlined,
                      label: todo.isAwaitingVerification
                          ? 'Verification pending'
                          : 'Verification required',
                      color: theme.colorScheme.tertiary,
                    ),
                ],
              ),

              if (creatorName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Created by $creatorName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              if (canAccept || canComplete) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (canAccept)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _acceptTask(context),
                          icon: const Icon(
                            Icons.assignment_turned_in_rounded,
                            size: 18,
                          ),
                          label: const Text('Accept'),
                        ),
                      ),
                    if (canAccept && canComplete) const SizedBox(width: 8),
                    if (canComplete)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _completeTask(context),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            todo.requiresVerification
                                ? 'Mark Done'
                                : 'Complete',
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              if (todo.isAwaitingVerification && todo.createdBy == userId) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 20,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This task is waiting for your verification.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openDetails(context),
                        child: const Text('Review'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
