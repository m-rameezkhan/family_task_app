import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../family/data/repositories/family_repository.dart';
import '../../../family/presentation/bloc/family_cubit.dart';
import 'family_page.dart';
import 'tasks_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user = authState.user;
    return BlocProvider(
      create: (_) => FamilyCubit(
        repository: context.read<FamilyRepository>(),
        userId: user.uid,
      ),
      child: _DashboardView(
        userId: user.uid,
        userName: user.displayName ?? 'Member',
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  final String userId;
  final String userName;

  const _DashboardView({required this.userId, required this.userName});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyCubit, FamilyState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tab == 0 ? 'My tasks' : 'My family'),
          actions: [
            IconButton(
              tooltip: 'Log out',
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthLogoutRequested()),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: _tab == 0
            ? TasksPage(userId: widget.userId, userName: widget.userName)
            : FamilyPage(userId: widget.userId, userName: widget.userName),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Family',
            ),
          ],
        ),
      ),
    );
  }
}
