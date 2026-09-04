import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../family/presentation/bloc/family_cubit.dart';
import '../../data/models/todo.dart';
import '../bloc/todo_cubit.dart';

class TaskEditPage extends StatefulWidget {
  final Todo todo;
  final String familyId;
  final String userId;

  const TaskEditPage({
    super.key,
    required this.todo,
    required this.familyId,
    required this.userId,
  });

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  late final TextEditingController _titleController;

  DateTime? _deadline;
  String? _assignedTo;
  bool _requiresVerification = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.todo.title,
    );

    _deadline = widget.todo.deadline;
    _assignedTo = widget.todo.assignedTo;
    _requiresVerification = widget.todo.requiresVerification;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      /*
       * If assignment changes, the task becomes active for
       * the selected member or open for everyone.
       *
       * We intentionally preserve completion/verification state
       * unless the user explicitly changes the task configuration.
       */
      final updatedTodo = widget.todo.copyWith(
        title: title,
        deadline: _deadline,
        clearDeadline: _deadline == null,
        assignedTo: _assignedTo,
        clearAssignedTo: _assignedTo == null,
        requiresVerification: _requiresVerification,
        updatedAt: DateTime.now(),
      );

      await context.read<TodoCubit>().updateTodo(
        updatedTodo,
      );

      if (!mounted) return;

      final error = context.read<TodoCubit>().state.error;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();

    final initialDate = _deadline != null
        ? DateTime(
            _deadline!.year,
            _deadline!.month,
            _deadline!.day,
          )
        : DateTime(
            now.year,
            now.month,
            now.day,
          );

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(
        DateTime(now.year, now.month, now.day),
      )
          ? DateTime(now.year, now.month, now.day)
          : initialDate,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _deadline != null
          ? TimeOfDay.fromDateTime(_deadline!)
          : TimeOfDay.now(),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _clearDeadline() async {
    setState(() {
      _deadline = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOpenTask = _assignedTo == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Deadline',
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _deadline == null
                          ? 'No deadline'
                          : formatDeadlineWithTime(
                              _deadline,
                            ),
                    ),
                  ),
                  if (_deadline != null)
                    IconButton(
                      tooltip: 'Clear deadline',
                      visualDensity:
                          VisualDensity.compact,
                      onPressed:
                          _saving ? null : _clearDeadline,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  IconButton(
                    tooltip: 'Choose deadline',
                    visualDensity:
                        VisualDensity.compact,
                    onPressed:
                        _saving ? null : _selectDeadline,
                    icon: const Icon(
                      Icons.edit_calendar_rounded,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            BlocBuilder<FamilyCubit, FamilyState>(
              builder: (context, state) {
                final members = state.members;

                final currentMember = members
                    .where(
                      (member) =>
                          member.id == widget.userId,
                    )
                    .firstOrNull;

                return DropdownButtonFormField<String?>(
                  initialValue: _assignedTo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Assign to',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: _DropdownLabel(
                        'Assign to no one (open task)',
                      ),
                    ),

                    if (currentMember != null)
                      DropdownMenuItem<String?>(
                        value: widget.userId,
                        child: _DropdownLabel(
                          'You (${currentMember.name})',
                        ),
                      ),

                    ...members
                        .where(
                          (member) =>
                              member.id != widget.userId,
                        )
                        .map(
                          (member) =>
                              DropdownMenuItem<String?>(
                            value: member.id,
                            child: _DropdownLabel(
                              member.name,
                            ),
                          ),
                        ),

                    // Keep the old assignment visible if
                    // the member was removed from the family
                    // list but the task still contains their UID.
                    if (_assignedTo != null &&
                        _assignedTo != widget.userId &&
                        members.every(
                          (member) =>
                              member.id != _assignedTo,
                        ))
                      DropdownMenuItem<String?>(
                        value: _assignedTo,
                        child: const _DropdownLabel(
                          'Previous member',
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _assignedTo = value;
                          });
                        },
                );
              },
            ),

            const SizedBox(height: 8),

            Text(
              isOpenTask
                  ? 'This is an open task. Every family member can see '
                    'and accept it.'
                  : 'This task is assigned to one family member.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),

            const SizedBox(height: 16),

            CheckboxListTile(
              value: _requiresVerification,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _requiresVerification =
                            value ?? false;
                      });
                    },
              contentPadding: EdgeInsets.zero,
              controlAffinity:
                  ListTileControlAffinity.leading,
              title: const Text(
                'Requires completion verification',
              ),
              subtitle: const Text(
                'The task creator must approve the completion.',
              ),
            ),

            const SizedBox(height: 16),

            if (widget.todo.status)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(12),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This task is already completed. '
                        'Changing its assignment or verification '
                        'settings will not automatically reopen it.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _saveTask,
        child: _saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : const Icon(
                Icons.check_rounded,
              ),
      ),
    );
  }
}

class _DropdownLabel extends StatelessWidget {
  final String text;

  const _DropdownLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      softWrap: false,
    );
  }
}