import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../family/data/models/family.dart';
import '../../../family/presentation/bloc/family_cubit.dart';
import 'member_todos_page.dart';

class FamilyPage extends StatelessWidget {
  final String userId;
  final String userName;

  const FamilyPage({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyCubit, FamilyState>(
      builder: (context, state) {
        if (state.family == null) return FamilySetup(userName: userName);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: 0.4),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Icon(
                    Icons.home_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  state.family!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Family code: ${state.family!.code}'),
                trailing: IconButton(
                  tooltip: 'Copy family code',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: state.family!.code),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Family code copied.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 12, left: 4),
              child: Text(
                'Family Members',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ..._orderedMembers(state.members).map(
              (member) => Card(
                elevation: 0,
                color: member.id == userId
                    ? Theme.of(context).colorScheme.primaryContainer
                          .withValues(alpha: 0.25)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member.photoUrl == null
                        ? null
                        : NetworkImage(member.photoUrl!),
                    child: member.photoUrl == null
                        ? Text(member.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(
                    member.id == userId ? '${member.name} (You)' : member.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(member.email),
                  trailing: member.id == userId
                      ? const Icon(Icons.person_outline_rounded)
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: member.id == userId
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemberTodosPage(
                              familyCubit: context.read<FamilyCubit>(),
                              family: state.family!,
                              member: member,
                              createdBy: userId,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<FamilyMember> _orderedMembers(List<FamilyMember> members) {
    final ordered = [...members];
    ordered.sort((a, b) {
      if (a.id == userId) return -1;
      if (b.id == userId) return 1;
      return 0;
    });
    return ordered;
  }
}

class FamilySetup extends StatefulWidget {
  final String userName;
  const FamilySetup({super.key, required this.userName});

  @override
  State<FamilySetup> createState() => _FamilySetupState();
}

class _FamilySetupState extends State<FamilySetup> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isCreateMode = true;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loading = context.watch<FamilyCubit>().state.loading;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top Illustration Badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.family_restroom_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Build Your Family Space',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new family group or join an existing one using a code.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            // Authentication Style Card
            Card(
              elevation: 2,
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Toggle Switcher (Create vs Join)
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isCreateMode = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: _isCreateMode
                                      ? theme.colorScheme.surface
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _isCreateMode
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.shadow
                                                .withValues(alpha: 0.05),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Create New',
                                  style: TextStyle(
                                    fontWeight: _isCreateMode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _isCreateMode
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isCreateMode = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: !_isCreateMode
                                      ? theme.colorScheme.surface
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !_isCreateMode
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.shadow
                                                .withValues(alpha: 0.05),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Join Existing',
                                  style: TextStyle(
                                    fontWeight: !_isCreateMode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !_isCreateMode
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Active Form Section
                    if (_isCreateMode) ...[
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Family Name',
                          hintText: 'e.g., The Khan Family',
                          prefixIcon: const Icon(Icons.other_houses_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: loading
                              ? null
                              : () => context.read<FamilyCubit>().create(
                                  _nameController.text,
                                  widget.userName,
                                ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_home_rounded),
                          label: Text(
                            loading ? 'Creating...' : 'Create Family',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Family Code',
                          hintText: 'Enter shared code',
                          prefixIcon: const Icon(Icons.key_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: loading
                              ? null
                              : () => context.read<FamilyCubit>().join(
                                  _codeController.text,
                                ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.group_add_rounded),
                          label: Text(
                            loading ? 'Joining...' : 'Join Family Space',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
