import 'package:flutter_test/flutter_test.dart';

import 'package:family_task_app/features/family/presentation/bloc/family_cubit.dart';
import 'package:family_task_app/features/tasks/presentation/bloc/todo_cubit.dart';

void main() {
  test('feature states start empty and idle', () {
    expect(const FamilyState().members, isEmpty);
    expect(const TodoState().todos, isEmpty);
    expect(const FamilyState().loading, isFalse);
    expect(const TodoState().loading, isFalse);
  });
}
