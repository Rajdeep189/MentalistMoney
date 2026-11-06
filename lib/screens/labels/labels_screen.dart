import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/label_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import 'label_detail_screen.dart';

const List<String> kLabelColors = <String>[
  '#A855F7',
  '#4C4C9E',
  '#E91E63',
  '#F2407E',
  '#2ED3B7',
  '#12B76A',
  '#F6C453',
  '#FB7185',
  '#3B82F6',
  '#8B5CF6',
];

class LabelsScreen extends ConsumerStatefulWidget {
  const LabelsScreen({super.key});

  @override
  ConsumerState<LabelsScreen> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends ConsumerState<LabelsScreen> {
  String _tab = 'This month';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final labelsAsync = _tab == 'This month'
        ? ref.watch(labelsThisMonthProvider)
        : ref.watch(labelsProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Labels', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.divider),
            ),
            child: Text(
              '2/2',
              style: AppTextStyles.base(
                size: 13,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(color: palette.sub),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editLabel(context),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: const Icon(Icons.sell_rounded, size: 26, color: Colors.white),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: PaisaSegment<String>(
            options: const <String>['This month', 'Overall'],
            value: _tab,
            height: 54,
            onChanged: (value) => setState(() => _tab = value),
          ),
        ),
      ),
      body: labelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (labels) {
          if (labels.isEmpty) {
            return EmptyState(
              title: 'No labels yet',
              message:
                  'Labels tag transactions across categories — like Personal or Work.',
              illustration: IllustrationKind.wallet,
              actionLabel: 'Create a label',
              onAction: () => _editLabel(context),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              4,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '${labels.length} label${labels.length == 1 ? '' : 's'}',
                    style: AppTextStyles.base(
                      size: 20,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: palette.accent),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.grid_view_rounded,
                        size: 24, color: palette.sub),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showInfo(context),
                    child: Icon(Icons.info_outline_rounded,
                        size: 24, color: palette.sub),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.divider.withOpacity(0.4)),
                ),
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < labels.length; i++)
                      _LabelRow(
                        info: labels[i],
                        showDivider: i < labels.length - 1,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LabelDetailScreen(
                              labelId: labels[i].id,
                              labelName: labels[i].name,
                            ),
                          ),
                        ),
                        onLongPress: () => _labelActions(context, labels[i]),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _labelActions(BuildContext context, LabelInfo info) async {
    final choice = await showAppSheet<String>(
      context,
      (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          16 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _SheetTile(
              icon: Icons.edit_rounded,
              label: 'Rename or recolour',
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
            _SheetTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete label',
              tone: sheetContext.c.expense,
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'edit') {
      await _editLabel(context, existing: info);
    } else if (choice == 'delete') {
      final ok = await confirmAction(
        context,
        title: 'Delete "${info.name}"?',
        message: 'The label is removed from every transaction. Transactions stay.',
      );
      if (!ok) return;
      await ref.read(labelRepositoryProvider).delete(info.id);
      if (context.mounted) showSnack(context, 'Label deleted');
    }
  }

  Future<void> _editLabel(BuildContext context, {LabelInfo? existing}) async {
    final controller =
        TextEditingController(text: existing?.name ?? '');
    var color = existing?.color ?? kLabelColors.first;
    final saved = await showAppSheet<bool>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            20,
            22,
            20 + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                existing == null ? 'New label' : 'Edit label',
                style: AppTextStyles.base(
                  size: 22,
                  weight: FontWeight.w700,
                  height: 1.2,
                ).copyWith(color: sheetContext.c.ink),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: sheetContext.c.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w500,
                    height: 1.3,
                  ).copyWith(color: sheetContext.c.ink),
                  decoration: InputDecoration(
                    hintText: 'Label name',
                    border: InputBorder.none,
                    hintStyle: AppTextStyles.base(
                      size: 15.5,
                      weight: FontWeight.w400,
                    ).copyWith(color: sheetContext.c.tertiary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final hex in kLabelColors)
                    GestureDetector(
                      onTap: () => setSheetState(() => color = hex),
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: AppColors.fromHex(hex),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: color == hex
                            ? const Icon(Icons.check_rounded,
                                size: 20, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sheetContext.c.accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    existing == null ? 'Create label' : 'Save label',
                    style: AppTextStyles.base(
                      size: 16,
                      weight: FontWeight.w700,
                      height: 1.1,
                    ).copyWith(color: AppColors.espresso),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    final name = controller.text.trim();
    if (name.isEmpty) {
      if (context.mounted) showSnack(context, 'Give the label a name', error: true);
      return;
    }
    final repo = ref.read(labelRepositoryProvider);
    if (existing == null) {
      try {
        await repo.create(name: name, color: color);
      } catch (_) {
        if (context.mounted) {
          showSnack(context, 'A label called "$name" already exists',
              error: true);
        }
        return;
      }
    } else {
      await repo.rename(existing.id, name);
      await repo.setColor(existing.id, color);
    }
    if (context.mounted) {
      showSnack(context, existing == null ? 'Label created' : 'Label updated');
    }
  }

  static Future<void> _showInfo(BuildContext context) {
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How Labels Work',
        intro:
            'Labels help you tag and organize transactions across categories for flexible tracking.',
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.sell_rounded,
            title: 'Tagging',
            body:
                'Add labels to any transaction. Use multiple labels for detailed tracking.',
          ),
          InfoSection(
            icon: Icons.filter_alt_rounded,
            title: 'Filtering',
            body:
                'Tap a label to view all associated transactions and totals.',
          ),
          InfoSection(
            icon: Icons.palette_rounded,
            title: 'Organization',
            body: 'Customize label colors to visually group related items.',
          ),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({
    required this.info,
    required this.showDivider,
    required this.onTap,
    required this.onLongPress,
  });

  final LabelInfo info;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = AppColors.fromHex(info.color);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(color: palette.divider.withOpacity(0.4)))
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.sell_rounded,
                  size: 24, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    info.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 20,
                      weight: FontWeight.w600,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${info.count} transaction${info.count == 1 ? '' : 's'}',
                    style: AppTextStyles.base(
                      size: 15,
                      weight: FontWeight.w400,
                      height: 1.2,
                    ).copyWith(color: palette.sub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              info.net < 0 ? '-${Fmt.plain(-info.net)}' : Fmt.plain(info.net),
              style: AppTextStyles.base(
                size: 17,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(
                color: info.net < 0 ? palette.expense : palette.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final color = tone ?? palette.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTextStyles.base(
                size: 17,
                weight: FontWeight.w500,
                height: 1.2,
              ).copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
