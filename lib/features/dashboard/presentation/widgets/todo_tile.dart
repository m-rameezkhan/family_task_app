import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../tasks/data/models/todo.dart';
import '../../../tasks/presentation/bloc/todo_cubit.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final bool canEdit;
  final String? creatorName;

  const TodoTile({
    super.key,
    required this.todo,
    required this.canEdit,
    this.creatorName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: canEdit
            ? Checkbox(
                value: todo.status,
                onChanged: (value) =>
                    context.read<TodoCubit>().toggle(todo, value ?? false),
              )
            : Icon(
                todo.status ? Icons.check_circle : Icons.radio_button_unchecked,
              ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.status ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (creatorName != null) Text('Assigned by $creatorName'),
            if (todo.deadline != null) Text('Due ${_date(todo.deadline!)}'),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';
