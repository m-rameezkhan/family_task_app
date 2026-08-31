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

    final fallbackName =
        (user.displayName != null && user.displayName!.trim().isNotEmpty)
        ? user.displayName!
        : (user.email != null && user.email!.contains('@'))
        ? user.email!.split('@').first
        : 'Member';

    return BlocProvider(
      create: (_) => FamilyCubit(
        repository: context.read<FamilyRepository>(),
        userId: user.uid,
      ),
      child: _DashboardView(
        userId: user.uid,
        fallbackName: fallbackName,
        userPhotoUrl: user.photoURL,
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  final String userId;
  final String fallbackName;
  final String? userPhotoUrl;

  const _DashboardView({
    required this.userId,
    required this.fallbackName,
    this.userPhotoUrl,
  });

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<FamilyCubit, FamilyState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: BlocBuilder<FamilyCubit, FamilyState>(
        builder: (context, familyState) {
          // Fetch exact user name from state.members (FamilyPage logic)
          final currentMember = familyState.members
              .where((m) => m.id == widget.userId)
              .firstOrNull;

          final userName = currentMember?.name ?? widget.fallbackName;

          return Scaffold(
            backgroundColor: theme.colorScheme.surfaceContainerLowest,
            body: SafeArea(
              child: Column(
                children: [
                  // Header using resolved userName
                  _buildHeader(theme, userName, familyState),

                  // Active Tab Content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _tab == 0
                          ? TasksPage(
                              key: const ValueKey('tasks_page'),
                              userId: widget.userId,
                              userName: userName,
                            )
                          : FamilyPage(
                              key: const ValueKey('family_page'),
                              userId: widget.userId,
                              userName: userName,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Clean Standard Navigation Bar
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
              ),
              child: NavigationBar(
                elevation: 0,
                height: 65,
                selectedIndex: _tab,
                onDestinationSelected: (index) => setState(() => _tab = index),
                indicatorColor: theme.colorScheme.primaryContainer,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.check_box_outlined),
                    selectedIcon: Icon(Icons.check_box_rounded),
                    label: 'Tasks',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline_rounded),
                    selectedIcon: Icon(Icons.people_rounded),
                    label: 'Family',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, String userName, FamilyState state) {
    final familyName = state.family?.name ?? 'Personal Workspace';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: widget.userPhotoUrl != null
                ? NetworkImage(widget.userPhotoUrl!)
                : null,
            child: widget.userPhotoUrl == null
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello, ${userName.split(' ').first} 👋',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  familyName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account Options',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Log out',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
