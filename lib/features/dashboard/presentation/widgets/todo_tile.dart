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
    final theme = Theme.of(context);
    final isDone = todo.status;
    final isOverdue =
        todo.deadline != null &&
        todo.deadline!.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        ) &&
        !isDone;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
        boxShadow: isDone
            ? []
            : [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canEdit
              ? () => context.read<TodoCubit>().toggle(todo, !isDone)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (canEdit)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isDone,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      activeColor: theme.colorScheme.primary,
                      onChanged: (value) => context.read<TodoCubit>().toggle(
                        todo,
                        value ?? false,
                      ),
                    ),
                  )
                else
                  Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isDone
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    size: 24,
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDone
                              ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (creatorName != null || todo.deadline != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (creatorName != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'By $creatorName',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            if (todo.deadline != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 13,
                                    color: isOverdue
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due ${_date(todo.deadline!)}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: isOverdue
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isOverdue
                                              ? theme.colorScheme.error
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';
