import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../family/presentation/bloc/family_cubit.dart';
import '../bloc/todo_cubit.dart';

class TaskCreatePage extends StatefulWidget {
  final String familyId;
  final String userId;

  const TaskCreatePage({
    super.key,
    required this.familyId,
    required this.userId,
  });

  @override
  State<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends State<TaskCreatePage> {
  late final TextEditingController _titleController;

  DateTime? _deadline;

  /// null = assign to no one / open task
  String? _assignedTo;

  bool _requiresVerification = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
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

    setState(() {
      _saving = true;
    });

    try {
      await context.read<TodoCubit>().add(
        title: title,
        deadline: _deadline,
        assignedTo: _assignedTo,
        requiresVerification: _requiresVerification,
      );

      if (!mounted) return;

      final error = context.read<TodoCubit>().state.error;

      if (error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully')),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating task: $error')));
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
      initialDate: _deadline ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
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
                hintText: 'Enter task title',
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
                          : () {
                              setState(() {
                                _deadline = null;
                              });
                            },
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

                final currentMember = members
                    .where((member) => member.id == widget.userId)
                    .firstOrNull;

                return DropdownButtonFormField<String?>(
                  value: _assignedTo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Assign to',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: _DropdownLabel('Assign to no one (open task)'),
                    ),

                    if (currentMember != null)
                      DropdownMenuItem<String?>(
                        value: widget.userId,
                        child: _DropdownLabel('You (${currentMember.name})'),
                      ),

                    ...members
                        .where((member) => member.id != widget.userId)
                        .map(
                          (member) => DropdownMenuItem<String?>(
                            value: member.id,
                            child: _DropdownLabel(member.name),
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
              _assignedTo == null
                  ? 'This task will appear in every family member\'s todo list. '
                        'Anyone can accept it.'
                  : 'This task will be assigned directly to the selected member.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            CheckboxListTile(
              value: _requiresVerification,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _requiresVerification = value ?? false;
                      });
                    },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Requires completion verification'),
              subtitle: const Text(
                'The task creator must approve the completion.',
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check_rounded),
      ),
    );
  }
}

class _DropdownLabel extends StatelessWidget {
  final String text;

  const _DropdownLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, overflow: TextOverflow.ellipsis, maxLines: 1);
  }
}
