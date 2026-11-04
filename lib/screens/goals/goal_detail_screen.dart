import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/fields.dart';
import '../../widgets/pickers.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/section_header.dart';
import 'goal_form_screen.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final int goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final goalAsync = ref.watch(goalByIdProvider(goalId));

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Goal'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) async {
              final goal = goalAsync.valueOrNull;
              if (goal == null) return;
              switch (value) {
                case 'edit':
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => GoalFormScreen(goal: goal)),
                  );
                  break;
                case 'pause':
                  await ref.read(goalRepositoryProvider).setStatus(
                        goalId,
                        goal.status == kGoalPaused ? kGoalActive : kGoalPaused,
                      );
                  break;
                case 'complete':
                  await ref.read(goalRepositoryProvider).setStatus(goalId, kGoalCompleted);
                  break;
                case 'delete':
                  final ok = await confirmAction(
                    context,
                    title: 'Delete this goal?',
                    message: 'Contribution history will be removed. Transactions stay.',
                  );
                  if (!ok) return;
                  await ref.read(goalRepositoryProvider).delete(goalId);
                  if (context.mounted) Navigator.of(context).pop();
                  break;
              }
            },
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text('Edit goal')),
              PopupMenuItem<String>(value: 'pause', child: Text('Pause / resume')),
              PopupMenuItem<String>(value: 'complete', child: Text('Mark complete')),
              PopupMenuItem<String>(value: 'delete', child: Text('Delete goal')),
            ],
          ),
        ],
      ),
      body: goalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (goal) {
          if (goal == null) return const Center(child: Text('Goal not found'));
          final tone = AppColors.fromHex(goal.color);
          final contributions =
              ref.watch(goalContributionsProvider(goalId)).valueOrNull ??
                  const <GoalContribution>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.x2,
              AppSpacing.screen,
              AppSpacing.x10,
            ),
            children: <Widget>[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.x5),
                child: Column(
                  children: <Widget>[
                    ProgressRing(
                      value: goal.progress,
                      size: 150,
                      strokeWidth: 13,
                      color: goal.isCompleted ? palette.income : tone,
                      backgroundGradient: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${(goal.progress * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.money(26, color: palette.ink,
                                weight: FontWeight.w700),
                          ),
                          Text('saved', style: context.caption),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    Text(goal.name, style: context.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    AmountText(goal.savedAmount, size: 24, weight: FontWeight.w700),
                    Text(
                      'of ${Fmt.money(goal.targetAmount)} target',
                      style: context.caption,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _miniStat(context, 'Remaining',
                              Fmt.money(goal.remainingAmount, forceCompact: true)),
                        ),
                        Expanded(
                          child: _miniStat(
                            context,
                            'Deadline',
                            goal.deadline == null
                                ? 'No deadline'
                                : Fmt.date(goal.deadline!),
                          ),
                        ),
                        Expanded(
                          child: _miniStat(
                            context,
                            'Status',
                            goal.status[0].toUpperCase() + goal.status.substring(1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              PrimaryButton(
                label: 'Add contribution',
                icon: Icons.add_rounded,
                onPressed: () => _addContribution(context, ref, goal),
              ),
              const SizedBox(height: AppSpacing.x5),
              SectionHeader(title: 'Contributions', padding: EdgeInsets.zero),
              if (contributions.isEmpty)
                AppCard(
                  child: Text('No contributions yet. Add your first one!',
                      style: context.bodyMuted),
                )
              else
                AppCard(
                  child: Column(
                    children: contributions
                        .map((contribution) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: <Widget>[
                                  CategoryIcon(
                                    icon: Icons.savings_rounded,
                                    color: tone,
                                    size: 34,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          contribution.note?.trim().isNotEmpty == true
                                              ? contribution.note!
                                              : 'Contribution',
                                          style: AppTextStyles.label(palette.ink),
                                        ),
                                        Text(
                                          Fmt.date(contribution.date),
                                          style: context.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  AmountText(contribution.amount, size: 14,
                                      color: palette.income),
                                  IconButton(
                                    icon: Icon(Icons.close_rounded,
                                        size: 16, color: palette.tertiary),
                                    onPressed: () async {
                                      final ok = await confirmAction(
                                        context,
                                        title: 'Remove contribution?',
                                        message:
                                            'The linked transaction (if any) will also be deleted.',
                                      );
                                      if (!ok) return;
                                      await ref
                                          .read(goalRepositoryProvider)
                                          .deleteContribution(contribution, goalId);
                                    },
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    return Column(
      children: <Widget>[
        Text(label, style: context.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.label(context.c.ink), textAlign: TextAlign.center),
      ],
    );
  }

  Future<void> _addContribution(BuildContext context, WidgetRef ref, Goal goal) async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const <Account>[];
    final controller = TextEditingController();
    int amount = 0;
    int? accountId = accounts.isEmpty ? null : accounts.first.id;
    bool createTransaction = true;

    final confirmed = await showAppSheet<bool>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SheetHeader(
                title: 'Add contribution',
                subtitle: 'Move money towards this goal',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
                child: Column(
                  children: <Widget>[
                    AmountField(
                      paise: amount,
                      onChanged: (value) => setSheetState(() => amount = value),
                      label: 'Amount',
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    if (accounts.isNotEmpty)
                      AppDropdown<Account>(
                        label: 'From account',
                        items: accounts,
                        value: accounts.firstWhere((a) => a.id == accountId,
                            orElse: () => accounts.first),
                        itemLabel: (item) => item.name,
                        onChanged: (item) => setSheetState(() => accountId = item.id),
                      ),
                    const SizedBox(height: AppSpacing.x2),
                    SwitchRow(
                      title: 'Also create a savings transaction',
                      subtitle: 'Keeps your account balance accurate',
                      value: createTransaction,
                      onChanged: (value) => setSheetState(() => createTransaction = value),
                      icon: Icons.receipt_long_outlined,
                    ),
                    AppTextField(
                      controller: controller,
                      label: 'Note',
                      hint: 'Optional',
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    PrimaryButton(
                      label: 'Add to goal',
                      onPressed: () {
                        if (amount <= 0) {
                          showSnack(context, 'Enter an amount', error: true);
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                    ),
                    const SizedBox(height: AppSpacing.x4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    await ref.read(goalRepositoryProvider).addContribution(
          goal: goal,
          amount: amount,
          date: DateTime.now(),
          accountId: accountId,
          note: controller.text.trim().isEmpty ? null : controller.text.trim(),
          createTransaction: createTransaction,
          savingsCategory: 'Savings',
        );
    if (context.mounted) showSnack(context, 'Contribution added');
  }
}
