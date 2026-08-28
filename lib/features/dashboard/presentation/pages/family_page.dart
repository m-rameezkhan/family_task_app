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
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.home)),
                title: Text(state.family!.name),
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
                  icon: const Icon(Icons.copy),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 28, bottom: 8),
              child: Text(
                'Family members',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ..._orderedMembers(state.members).map(
              (member) => Card(
                color: member.id == userId ? const Color(0xffe8f5e9) : null,
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
                  ),
                  subtitle: Text(member.email),
                  trailing: member.id == userId
                      ? const Icon(Icons.person)
                      : const Icon(Icons.chevron_right),
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

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<FamilyCubit>().state.loading;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.family_restroom, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Build your family space',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create a new family or join one with a shared code.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Family name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: loading
              ? null
              : () => context.read<FamilyCubit>().create(
                  _nameController.text,
                  widget.userName,
                ),
          icon: const Icon(Icons.add_home),
          label: const Text('Create family'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Divider(),
        ),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Family code',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: loading
              ? null
              : () => context.read<FamilyCubit>().join(_codeController.text),
          icon: const Icon(Icons.group_add),
          label: const Text('Join family'),
        ),
      ],
    );
  }
}
