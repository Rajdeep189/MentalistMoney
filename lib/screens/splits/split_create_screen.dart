import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import 'split_detail_screen.dart';

class SplitCreateScreen extends ConsumerStatefulWidget {
  const SplitCreateScreen({super.key});

  @override
  ConsumerState<SplitCreateScreen> createState() => _SplitCreateScreenState();
}

class _SplitCreateScreenState extends ConsumerState<SplitCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final List<String> _members = <String>['You'];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  void _addMember([String? name]) {
    final value = (name ?? _memberController.text).trim();
    if (value.isEmpty) return;
    if (_members.any((member) => member.toLowerCase() == value.toLowerCase())) return;
    setState(() {
      _members.add(value);
      _memberController.clear();
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      showSnack(context, 'Give this group a name', error: true);
      return;
    }
    if (_members.length < 2) {
      showSnack(context, 'Add at least one more member', error: true);
      return;
    }
    setState(() => _saving = true);
    final id = await ref
        .read(splitRepositoryProvider)
        .createGroup(_nameController.text.trim(), _members);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => SplitDetailScreen(groupId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('New split group')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.x2,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          AppTextField(
            controller: _nameController,
            label: 'Group name',
            hint: 'e.g. Goa Trip, Flatmates',
            prefixIcon: Icons.groups_outlined,
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('Members', style: AppTextStyles.label(palette.sub)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _members
                .map(
                  (member) => Chip(
                    label: Text(member),
                    onDeleted: member == 'You'
                        ? null
                        : () => setState(() => _members.remove(member)),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: <Widget>[
              Expanded(
                child: AppTextField(
                  controller: _memberController,
                  hint: 'Add a member',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: PrimaryButton(
                  label: 'Add',
                  expanded: false,
                  onPressed: _addMember,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: 8,
            children: const <String>['Rahul', 'Amit', 'Priya', 'Neha']
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: () => _addMember(suggestion),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.x6),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x4),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.info_outline_rounded, size: 18, color: palette.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Splits are tracked separately from your accounts, so they never affect your budgets.',
                    style: AppTextStyles.caption(palette.onSoft).copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: 'Create group',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
