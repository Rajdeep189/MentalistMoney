import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// Section label with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.x3),
    this.icon,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: palette.tertiary),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h3(palette.ink),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: palette.ink,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(action!,
                      style: AppTextStyles.label(palette.sub)
                          .copyWith(fontSize: 12)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded,
                      size: 13, color: palette.sub),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Tiny uppercase label such as "THIS MONTH".
class OverlineLabel extends StatelessWidget {
  const OverlineLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.overline.copyWith(color: color ?? context.c.tertiary),
    );
  }
}
