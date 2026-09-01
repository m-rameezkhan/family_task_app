import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../tasks/presentation/bloc/todo_cubit.dart';

Future<void> showTodoDialog(BuildContext context) async {
  final todoCubit = context.read<TodoCubit>();
  await showDialog<void>(
    context: context,
    builder: (_) => _TodoDialog(
      todoCubit: todoCubit,
      assignedTo: todoCubit.userId,
      createdBy: todoCubit.userId,
    ),
  );
}

Future<void> showAssignedTodoDialog(
  BuildContext context,
  String assignedTo,
  String createdBy,
) async {
  final todoCubit = context.read<TodoCubit>();
  await showDialog<void>(
    context: context,
    builder: (_) => _TodoDialog(
      todoCubit: todoCubit,
      assignedTo: assignedTo,
      createdBy: createdBy,
    ),
  );
}

class _TodoDialog extends StatefulWidget {
  final TodoCubit todoCubit;
  final String assignedTo;
  final String createdBy;

  const _TodoDialog({
    required this.todoCubit,
    required this.assignedTo,
    required this.createdBy,
  });

  @override
  State<_TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends State<_TodoDialog> {
  final _controller = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    await widget.todoCubit.add(
      title,
      deadline: _deadline,
      assignedTo: widget.assignedTo,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.assignedTo == widget.createdBy ? 'Add task' : 'Assign task',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Task title'),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  _deadline == null
                      ? 'No deadline'
                      : 'Due ${_date(_deadline!)}',
                ),
              ),
              IconButton(
                tooltip: 'Choose deadline',
                onPressed: _saving
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null && mounted) {
                          setState(() => _deadline = picked);
                        }
                      },
                icon: const Icon(Icons.event),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';
