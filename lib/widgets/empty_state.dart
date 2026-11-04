import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'buttons.dart';
import 'illustration.dart';

/// Friendly empty state with an original geometric illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.illustration = IllustrationKind.wallet,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IllustrationKind illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x5,
          vertical: compact ? AppSpacing.x6 : AppSpacing.x10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIllustration(kind: illustration, size: compact ? 96 : 148),
            SizedBox(height: compact ? AppSpacing.x4 : AppSpacing.x6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.h2,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.x2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(palette.sub).copyWith(height: 1.5),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.x5),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
