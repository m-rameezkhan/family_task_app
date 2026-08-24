import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../tasks/presentation/bloc/task_bloc.dart';
import '../../../tasks/presentation/bloc/task_event.dart';
import '../../../tasks/presentation/bloc/task_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _titleController = TextEditingController();

  DateTime? _selectedDeadline;

  @override
  void initState() {
    super.initState();

    context.read<TaskBloc>().add(
          TasksLoadRequested(),
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDeadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _addTask() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title.'),
        ),
      );
      return;
    }

    context.read<TaskBloc>().add(
          TaskCreateRequested(
            title: title,
            deadline: _selectedDeadline,
          ),
        );

    _titleController.clear();

    setState(() {
      _selectedDeadline = null;
    });
  }

  String _formatDeadline(DateTime deadline) {
    final date = '${deadline.day}/${deadline.month}/${deadline.year}';

    final hour = deadline.hour == 0
        ? 12
        : deadline.hour > 12
            ? deadline.hour - 12
            : deadline.hour;

    final minute = deadline.minute.toString().padLeft(2, '0');

    final period = deadline.hour >= 12 ? 'PM' : 'AM';

    return '$date $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Task App'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(
                    AuthLogoutRequested(),
                  );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task title',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDeadline == null
                        ? 'No deadline'
                        : 'Deadline: '
                            '${_formatDeadline(_selectedDeadline!)}',
                  ),
                ),
                TextButton(
                  onPressed: _selectDeadline,
                  child: const Text('Set Deadline'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addTask,
                child: const Text('Add Task'),
              ),
            ),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state is TaskLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is TaskFailure) {
                    return Center(
                      child: Text(state.message),
                    );
                  }

                  if (state is TaskLoaded) {
                    if (state.tasks.isEmpty) {
                      return const Center(
                        child: Text('No tasks yet.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: state.tasks.length,
                      itemBuilder: (context, index) {
                        final task = state.tasks[index];

                        return Card(
                          child: ListTile(
                            title: Text(task.title),
                            subtitle: task.deadline == null
                                ? const Text('No deadline')
                                : Text(
                                    'Due: '
                                    '${_formatDeadline(task.deadline!)}',
                                  ),
                          ),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}