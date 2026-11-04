import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/app_providers.dart';
import 'app_sheets.dart';
import 'buttons.dart';
import 'illustration.dart';
import 'premium_badge.dart';

/// Shows the upgrade sheet unless the user is Premium.
/// Returns `true` when the caller may continue.
Future<bool> ensurePremium(
  BuildContext context,
  WidgetRef ref, {
  required String feature,
  String? description,
}) async {
  if (ref.read(isPremiumProvider)) return true;
  final upgrade = await showAppSheet<bool>(
    context,
    (sheetContext) => Consumer(
      builder: (context, innerRef, _) => _UpgradePrompt(
        feature: feature,
        description: description,
        onUpgrade: () => Navigator.of(sheetContext).pop(true),
      ),
    ),
  );
  return upgrade ?? false;
}

class _UpgradePrompt extends StatelessWidget {
  const _UpgradePrompt({required this.feature, this.description, required this.onUpgrade});

  final String feature;
  final String? description;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        0,
        AppSpacing.x5,
        AppSpacing.x6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const PremiumBadge(),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: Icon(Icons.close_rounded, size: 20, color: palette.sub),
              ),
            ],
          ),
          const AppIllustration(kind: IllustrationKind.premium, size: 120),
          const SizedBox(height: AppSpacing.x4),
          Text('$feature is a Premium feature', textAlign: TextAlign.center, style: context.h2),
          const SizedBox(height: AppSpacing.x2),
          Text(
            description ??
                'Unlock unlimited budgets and goals, forecasting, bill splitting, premium themes and branded PDF reports.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(palette.sub).copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpacing.x5),
          PrimaryButton(
            label: 'See Premium plans',
            icon: Icons.workspace_premium_rounded,
            onPressed: onUpgrade,
          ),
          const SizedBox(height: AppSpacing.x2),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Maybe later', style: AppTextStyles.label(palette.sub)),
          ),
        ],
      ),
    );
  }
}

/// Adds a small lock chip to premium-only rows.
class LockedRow extends StatelessWidget {
  const LockedRow({super.key, required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon ?? Icons.lock_rounded, color: palette.accent),
      title: Row(
        children: <Widget>[
          Text(label, style: AppTextStyles.body(palette.ink)),
          const SizedBox(width: 8),
          const PremiumBadge(dense: true),
        ],
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: palette.tertiary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    );
  }
}
