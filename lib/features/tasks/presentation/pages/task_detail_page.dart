import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../family/presentation/bloc/family_cubit.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/todo.dart';
import '../bloc/todo_cubit.dart';
import 'task_edit_page.dart';

class TaskDetailPage extends StatefulWidget {
  final Todo todo;
  final String userId;

  /// Controls whether the current user can edit/delete the task.
  final bool canEdit;

  final Map<String, String> memberNames;

  const TaskDetailPage({
    super.key,
    required this.todo,
    required this.userId,
    required this.canEdit,
    this.memberNames = const {},
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late Todo _localTodo;

  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _localTodo = widget.todo;
  }

  Todo _getCurrentTodo(TodoCubit cubit) {
    final matchingTodos = cubit.state.todos.where(
      (todo) => todo.id == _localTodo.id,
    );

    if (matchingTodos.isNotEmpty) {
      _localTodo = matchingTodos.first;
    }

    return _localTodo;
  }

  Future<void> _acceptTask(Todo todo) async {
    if (!todo.isUnassigned) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      await context.read<TodoCubit>().acceptTodo(todo.id);

      if (!mounted) return;

      final error = context.read<TodoCubit>().state.error;

      if (error != null) {
        _showMessage(error);
        return;
      }

      _showMessage('Task accepted successfully.');
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<void> _completeTask(Todo todo) async {
    if (todo.assignedTo != widget.userId) {
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      await context.read<TodoCubit>().completeTodo(todo.id);

      if (!mounted) return;

      final error = context.read<TodoCubit>().state.error;

      if (error != null) {
        _showMessage(error);
        return;
      }

      if (todo.requiresVerification) {
        _showMessage('Task submitted for verification.');
      } else {
        _showMessage('Task completed successfully.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<void> _reopenTask(Todo todo) async {
    if (todo.assignedTo != widget.userId) {
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Reopen Task',
      message: 'Are you sure you want to mark this task as pending again?',
      confirmText: 'Reopen',
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      await context.read<TodoCubit>().reopenTodo(todo.id);

      if (!mounted) return;

      final error = context.read<TodoCubit>().state.error;

      if (error != null) {
        _showMessage(error);
        return;
      }

      _showMessage('Task reopened.');
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<void> _approveTask(Todo todo) async {
    if (todo.createdBy != widget.userId) {
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Approve Completion',
      message: 'Confirm that this task has actually been completed.',
      confirmText: 'Approve',
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      await context.read<TodoCubit>().approveTask(todo.id);

      if (!mounted) return;

      final error = context.read<TodoCubit>().state.error;

      if (error != null) {
        _showMessage(error);
        return;
      }

      _showMessage('Task completion approved.');
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<void> _rejectTask(Todo todo) async {
    if (todo.createdBy != widget.userId) {
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Reject Completion',
      message: 'The task will be returned to the pending state.',
      confirmText: 'Reject',
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      await context.read<TodoCubit>().rejectTask(todo.id);

      if (!mounted) return;

      final error = context.read<TodoCubit>().state.error;

      if (error != null) {
        _showMessage(error);
        return;
      }

      _showMessage(
        'Completion rejected. The member can work on the task again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Delete Task',
      message: 'Are you sure you want to permanently delete this task?',
      confirmText: 'Delete',
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      await context.read<TodoCubit>().deleteTodo(_localTodo.id);

      if (!mounted) return;

      final error = context.read<TodoCubit>().state.error;

      if (error != null) {
        _showMessage(error);
        return;
      }

      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _assignmentLabel(Todo todo) {
    if (todo.assignedTo == null) {
      return 'No one (Open task)';
    }

    if (todo.assignedTo == widget.userId) {
      return 'You';
    }

    return widget.memberNames[todo.assignedTo] ?? 'Family member';
  }

  String _statusText(Todo todo) {
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
      return 'Open';
    }

    return 'Pending';
  }

  IconData _statusIcon(Todo todo) {
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
      return Icons.public_rounded;
    }

    return Icons.pending_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoCubit, TodoState>(
      builder: (context, state) {
        final todo = _getCurrentTodo(context.read<TodoCubit>());

        final isCreator = todo.createdBy == widget.userId;
        final isAssignedToMe = todo.assignedTo == widget.userId;
        final isOpenTask = todo.assignedTo == null;

        final canManageTask = widget.canEdit || isCreator;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            actions: [
              if (canManageTask)
                PopupMenuButton<String>(
                  enabled: !_actionLoading,
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                value: context.read<TodoCubit>(),
                              ),
                              BlocProvider.value(
                                value: context.read<FamilyCubit>(),
                              ),
                            ],
                            child: TaskEditPage(
                              todo: todo,
                              familyId: todo.familyId,
                              userId: widget.userId,
                            ),
                          ),
                        ),
                      );
                    }

                    if (value == 'delete') {
                      await _deleteTask();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_rounded),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Delete'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                todo.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(_statusIcon(todo), size: 18),
                    label: Text(_statusText(todo)),
                  ),
                  Chip(
                    avatar: const Icon(Icons.person_outline_rounded, size: 18),
                    label: Text('Assigned to ${_assignmentLabel(todo)}'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildInfoSection(
                context,
                title: 'Task Information',
                children: [
                  _InfoTile(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Created by',
                    value: todo.createdBy == widget.userId
                        ? 'You'
                        : widget.memberNames[todo.createdBy] ?? 'Family member',
                  ),
                  _InfoTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Assigned to',
                    value: _assignmentLabel(todo),
                  ),
                  if (todo.deadline != null)
                    _InfoTile(
                      icon: Icons.event_available_rounded,
                      title: 'Deadline',
                      value: formatDeadlineWithTime(todo.deadline),
                      subtitle: formatTimeRemaining(todo.deadline),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              if (todo.requiresVerification)
                _buildVerificationSection(context, todo, isCreator),

              const SizedBox(height: 20),

              _buildActions(
                context,
                todo,
                isCreator: isCreator,
                isAssignedToMe: isAssignedToMe,
                isOpenTask: isOpenTask,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerificationSection(
    BuildContext context,
    Todo todo,
    bool isCreator,
  ) {
    final theme = Theme.of(context);

    String title;
    String message;
    IconData icon;

    switch (todo.verificationStatus) {
      case 'pending':
        title = 'Verification pending';
        message = isCreator
            ? 'The member has marked this task as completed. '
                  'Please verify whether it is actually done.'
            : 'Your completion is waiting for the task creator '
                  'to verify it.';
        icon = Icons.pending_actions_rounded;
        break;

      case 'approved':
        title = 'Completion verified';
        message = todo.verifiedBy == widget.userId
            ? 'You approved this task completion.'
            : 'The task creator approved this completion.';
        icon = Icons.verified_rounded;
        break;

      case 'rejected':
        title = 'Completion rejected';
        message = isCreator
            ? 'You rejected the completion. The task is pending again.'
            : 'The task creator rejected the completion. '
                  'Please complete the task again.';
        icon = Icons.cancel_outlined;
        break;

      default:
        title = 'Verification required';
        message =
            'The creator must verify completion after the member '
            'marks the task as done.';
        icon = Icons.verified_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    Todo todo, {
    required bool isCreator,
    required bool isAssignedToMe,
    required bool isOpenTask,
  }) {
    final buttons = <Widget>[];

    // Open task → anyone can accept.
    if (isOpenTask && !todo.status) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _actionLoading ? null : () => _acceptTask(todo),
            icon: const Icon(Icons.assignment_turned_in_rounded),
            label: const Text('Accept Task'),
          ),
        ),
      );
    }

    // Assigned to current user → complete.
    if (isAssignedToMe && !todo.status) {
      if (todo.verificationStatus != 'pending') {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _actionLoading ? null : () => _completeTask(todo),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                todo.requiresVerification ? 'Mark as Done' : 'Complete Task',
              ),
            ),
          ),
        );
      }
    }

    // Assigned user can reopen a completed task.
    if (isAssignedToMe && todo.status) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _actionLoading ? null : () => _reopenTask(todo),
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Reopen Task'),
          ),
        ),
      );
    }

    // Creator can approve/reject a pending verification.
    if (isCreator && todo.isAwaitingVerification) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _actionLoading ? null : () => _approveTask(todo),
            icon: const Icon(Icons.verified_rounded),
            label: const Text('Approve Completion'),
          ),
        ),
      );

      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _actionLoading ? null : () => _rejectTask(todo),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Reject Completion'),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...buttons.expand((button) => [button, const SizedBox(height: 10)]),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value),
          if (subtitle != null)
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
