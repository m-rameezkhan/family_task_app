import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../data/models/todo.dart';
import '../bloc/todo_cubit.dart';

class TaskDetailPage extends StatefulWidget {
  final Todo todo;
  final String userId;
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
  late final TextEditingController _titleController;
  bool _isEditing = false;
  bool _saving = false;
  bool _verificationPending = false;

  @override
  void initState() {
    super.initState();
    _localTodo = widget.todo;
    _titleController = TextEditingController(text: widget.todo.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Todo _currentTodo(TodoCubit cubit) {
    final matches = cubit.state.todos.where((todo) => todo.id == _localTodo.id);
    if (matches.isNotEmpty && !_saving && !_verificationPending) {
      _localTodo = matches.first;
    }
    return _localTodo;
  }

  Future<void> _saveTodo() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = _localTodo.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      _localTodo = updated;
      await context.read<TodoCubit>().updateTodo(updated);
      if (mounted) {
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTodo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<TodoCubit>().deleteTodo(_localTodo.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleVerification(Todo todo) async {
    final verifiedBy = [...todo.verifiedBy];
    final wasVerified = verifiedBy.contains(widget.userId);

    if (wasVerified) {
      verifiedBy.remove(widget.userId);
    } else {
      verifiedBy.add(widget.userId);
    }

    setState(() {
      _verificationPending = true;
      _localTodo = todo.copyWith(verifiedBy: verifiedBy);
    });

    try {
      if (wasVerified) {
        await context.read<TodoCubit>().unverifyTask(todo.id, widget.userId);
      } else {
        await context.read<TodoCubit>().verifyTask(todo.id, widget.userId);
      }
    } finally {
      if (mounted) {
        setState(() => _verificationPending = false);
      }
    }
  }

  String _assignmentLabel(Todo todo) {
    if (todo.assignedTo.isEmpty) return 'No one';
    if (todo.assignedTo == widget.userId) return 'You';
    return widget.memberNames[todo.assignedTo] ?? 'Family member';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TodoCubit, TodoState>(
      builder: (context, state) {
        final todo = _currentTodo(context.read<TodoCubit>());

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Task' : 'Task Details'),
            actions: [
              if (widget.canEdit && !_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Edit',
                ),
              if (widget.canEdit && !_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _deleteTodo,
                  tooltip: 'Delete',
                ),
            ],
          ),
          body: _isEditing
              ? _buildEditView(theme)
              : _buildDetailView(theme, todo),
          floatingActionButton: _isEditing
              ? FloatingActionButton(
                  onPressed: _saving ? null : _saveTodo,
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDetailView(ThemeData theme, Todo todo) {
    final verifiedByYou = todo.verifiedBy.contains(widget.userId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          todo.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: Icon(
                todo.status
                    ? Icons.check_circle_rounded
                    : Icons.pending_outlined,
                size: 18,
              ),
              label: Text(todo.status ? 'Completed' : 'Pending'),
            ),
            Chip(
              avatar: const Icon(Icons.person_outline_rounded, size: 18),
              label: Text('Assigned to ${_assignmentLabel(todo)}'),
            ),
          ],
        ),
        if (todo.deadline != null) ...[
          const SizedBox(height: 24),
          Text(
            'Deadline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available_rounded),
            title: Text(formatDeadlineWithTime(todo.deadline)),
            subtitle: Text(formatTimeRemaining(todo.deadline)),
          ),
        ],
        if (todo.requiresVerification) ...[
          const SizedBox(height: 24),
          Text(
            'Verification',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _toggleVerification(todo),
            icon: Icon(
              verifiedByYou ? Icons.verified_rounded : Icons.verified_outlined,
            ),
            label: Text(verifiedByYou ? 'Verified by you' : 'Mark as verified'),
          ),
          if (todo.verifiedBy.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${todo.verifiedBy.length} verification${todo.verifiedBy.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildEditView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Task Title *',
            border: OutlineInputBorder(),
          ),
          enabled: !_saving,
        ),
      ],
    );
  }
}
