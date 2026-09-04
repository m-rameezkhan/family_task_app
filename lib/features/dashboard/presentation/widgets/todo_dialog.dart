import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../family/presentation/bloc/family_cubit.dart';
import '../../../tasks/presentation/bloc/todo_cubit.dart';

Future<void> showTodoDialog(BuildContext context) async {
  final todoCubit = context.read<TodoCubit>();
  final familyCubit = context.read<FamilyCubit>();

  await showDialog<void>(
    context: context,
    builder: (_) => _TodoDialog(
      todoCubit: todoCubit,
      familyCubit: familyCubit,
    ),
  );
}

Future<void> showAssignedTodoDialog(
  BuildContext context,
  String? assignedTo,
  String createdBy,
) async {
  final todoCubit = context.read<TodoCubit>();
  final familyCubit = context.read<FamilyCubit>();

  await showDialog<void>(
    context: context,
    builder: (_) => _TodoDialog(
      todoCubit: todoCubit,
      familyCubit: familyCubit,
      initialAssignedTo: assignedTo,
    ),
  );
}

class _TodoDialog extends StatefulWidget {
  final TodoCubit todoCubit;
  final FamilyCubit familyCubit;
  final String? initialAssignedTo;

  const _TodoDialog({
    required this.todoCubit,
    required this.familyCubit,
    this.initialAssignedTo,
  });

  @override
  State<_TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends State<_TodoDialog> {
  late final TextEditingController _controller;

  DateTime? _deadline;

  /// null = open/unassigned task
  String? _assignedTo;

  bool _requiresVerification = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
    _assignedTo = widget.initialAssignedTo;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _controller.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
        ),
      );
      return;
    }

    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.todoCubit.add(
        title: title,
        deadline: _deadline,
        assignedTo: _assignedTo,
        requiresVerification: _requiresVerification,
      );

      if (!mounted) return;

      final error = widget.todoCubit.state.error;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
          ),
        );
        return;
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating task: $error'),
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

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: DateTime(2100),
      initialDate:
          _deadline ?? now.add(const Duration(days: 1)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _deadline != null
          ? TimeOfDay.fromDateTime(_deadline!)
          : TimeOfDay.now(),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

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

  void _clearDeadline() {
    setState(() {
      _deadline = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read the family state from the FamilyCubit instance
    // captured before showDialog().
    final members = widget.familyCubit.state.members;

    return AlertDialog(
      title: const Text('Create Task'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                enabled: !_saving,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task title *',
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String?>(
                initialValue: _assignedTo,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Assign to',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'No one (Open task)',
                    ),
                  ),
                  ...members.map(
                    (member) => DropdownMenuItem<String?>(
                      value: member.id,
                      child: Text(
                        member.name,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
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
              ),

              const SizedBox(height: 6),

              Text(
                _assignedTo == null
                    ? 'Open task: every family member can see and accept it.'
                    : 'This task is assigned directly to the selected member.',
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

              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Deadline',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _deadline == null
                            ? 'No deadline'
                            : 'Due ${formatDeadlineDate(_deadline!)} '
                              'at ${formatTime(_deadline!)}',
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                    if (_deadline != null)
                      IconButton(
                        tooltip: 'Clear deadline',
                        onPressed:
                            _saving ? null : _clearDeadline,
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Choose deadline',
                      onPressed:
                          _saving ? null : _selectDeadline,
                      icon: const Icon(
                        Icons.edit_calendar_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

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
                  'Requires verification',
                ),
                subtitle: const Text(
                  'The task creator must approve completion.',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
