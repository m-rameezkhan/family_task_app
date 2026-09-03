import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../family/presentation/bloc/family_cubit.dart';
import '../../data/models/todo.dart';
import '../bloc/todo_cubit.dart';

class TaskCreateEditPage extends StatefulWidget {
  final Todo? todo;
  final String familyId;
  final String userId;

  const TaskCreateEditPage({
    super.key,
    this.todo,
    required this.familyId,
    required this.userId,
  });

  @override
  State<TaskCreateEditPage> createState() => _TaskCreateEditPageState();
}

class _TaskCreateEditPageState extends State<TaskCreateEditPage> {
  late final TextEditingController _titleController;

  DateTime? _deadline;
  String _assignedTo = '';
  bool _requiresVerification = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');

    if (widget.todo != null) {
      _deadline = widget.todo!.deadline;
      _assignedTo = widget.todo!.assignedTo;
      _requiresVerification = widget.todo!.requiresVerification;
    }
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
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.todo == null) {
        await context.read<TodoCubit>().add(
          title,
          deadline: _deadline,
          assignedTo: _assignedTo,
          requiresVerification: _requiresVerification,
        );
      } else {
        final updated = widget.todo!.copyWith(
          title: title,
          deadline: _deadline,
          clearDeadline: _deadline == null,
          assignedTo: _assignedTo,
          requiresVerification: _requiresVerification,
          updatedAt: DateTime.now(),
        );
        await context.read<TodoCubit>().updateTodo(updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.todo == null
                  ? 'Task created successfully'
                  : 'Task updated successfully',
            ),
          ),
        );
        Navigator.pop(context);
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

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()),
    );
    if (pickedTime == null || !mounted) return;

    setState(
      () => _deadline = DateTime(
        picked.year,
        picked.month,
        picked.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.todo != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Task' : 'Create Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                hintText: 'Enter task title',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Deadline and time',
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _deadline == null
                          ? 'No deadline'
                          : formatDeadlineWithTime(_deadline),
                    ),
                  ),
                  if (_deadline != null)
                    IconButton(
                      tooltip: 'Clear deadline',
                      visualDensity: VisualDensity.compact,
                      onPressed: _saving
                          ? null
                          : () => setState(() => _deadline = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  IconButton(
                    tooltip: 'Choose deadline',
                    visualDensity: VisualDensity.compact,
                    onPressed: _saving ? null : _selectDeadline,
                    icon: const Icon(Icons.edit_calendar_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<FamilyCubit, FamilyState>(
              builder: (context, state) {
                final members = state.members;
                final currentMemberName = members
                    .where((member) => member.id == widget.userId)
                    .firstOrNull
                    ?.name;
                final otherMembers = members
                    .where((member) => member.id != widget.userId)
                    .toList();
                final hasSelectedMember =
                    _assignedTo.isEmpty ||
                    _assignedTo == widget.userId ||
                    members.any((member) => member.id == _assignedTo);

                return DropdownButtonFormField<String>(
                  initialValue: _assignedTo,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: _DropdownLabel('Assign to no one'),
                    ),
                    DropdownMenuItem(
                      value: widget.userId,
                      child: _DropdownLabel(
                        currentMemberName == null
                            ? 'Assign to you'
                            : 'Assign to you ($currentMemberName)',
                      ),
                    ),
                    ...otherMembers.map(
                      (member) => DropdownMenuItem(
                        value: member.id,
                        child: _DropdownLabel(member.name),
                      ),
                    ),
                    if (!hasSelectedMember)
                      DropdownMenuItem(
                        value: _assignedTo,
                        child: const _DropdownLabel(
                          'Previously assigned member',
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() => _assignedTo = value ?? '');
                        },
                  decoration: const InputDecoration(
                    labelText: 'Assign to',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _requiresVerification,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() => _requiresVerification = value ?? false);
                    },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Requires verification'),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check),
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
