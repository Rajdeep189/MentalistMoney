import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'app_card.dart';
import 'category_icon.dart';
import 'premium_badge.dart';

/// Rounded section label used across settings screens.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.x5,
        bottom: AppSpacing.x2,
        left: 4,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Text(
                  title.toUpperCase(),
                  style: AppTextStyles.overline(context.c.tertiary)
                      .copyWith(letterSpacing: 1.8, fontSize: 9.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 1,
                    color: context.c.divider,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Grouped card that hosts a list of tiles.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return AppCard(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            children[i],
            if (i != children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Divider(color: palette.divider, height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

/// Navigation / action tile with an icon, title, subtitle and trailing value.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.premium = false,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool premium;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: dense ? 8 : 11,
        ),
        child: Row(
          children: <Widget>[
            if (icon != null)
              Container(
                height: dense ? 30 : 34,
                width: dense ? 30 : 34,
                decoration: BoxDecoration(
                  color: (iconColor ?? (palette.isDark
                          ? palette.accent
                          : palette.ink))
                      .withOpacity(palette.isDark ? 0.20 : 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: dense ? 15 : 17,
                  color: iconColor ??
                      (palette.isDark ? palette.accent : palette.ink),
                ),
              ),
            if (icon != null) const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          title,
                          style: AppTextStyles.label(palette.ink)
                              .copyWith(fontSize: 13.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (premium) ...<Widget>[
                        const SizedBox(width: 8),
                        const PremiumBadge(dense: true),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: AppTextStyles.caption(palette.tertiary),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 20, color: palette.tertiary),
          ],
        ),
      ),
    );
  }
}

/// Row of selectable choice pills used in settings.
class SettingsChoiceRow<T> extends StatelessWidget {
  const SettingsChoiceRow({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.labelOf,
  });

  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T option)? labelOf;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final selected = option == value;
          return GestureDetector(
            onTap: () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? (palette.isDark ? palette.accent : palette.ink)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected
                      ? (palette.isDark ? palette.accent : palette.ink)
                      : palette.divider,
                ),
              ),
              child: Text(
                labelOf?.call(option) ?? '$option',
                style: AppTextStyles.caption(
                  selected ? palette.onAccent : palette.sub,
                ).copyWith(fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Colour swatch row used by the accent picker.
class AccentSwatches extends StatelessWidget {
  const AccentSwatches({
    super.key,
    required this.selectedHex,
    required this.onChanged,
    required this.palette,
  });

  final String selectedHex;
  final ValueChanged<String> onChanged;
  final Map<String, Color> palette;

  @override
  Widget build(BuildContext context) {
    final theme = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: palette.entries.map((entry) {
          final selected = AppColors.toHex(entry.value) == selectedHex.toUpperCase();
          return GestureDetector(
            onTap: () => onChanged(AppColors.toHex(entry.value)),
            child: Column(
              children: <Widget>[
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? theme.ink : theme.divider,
                      width: selected ? 2.2 : 1,
                    ),
                    boxShadow: selected
                        ? <BoxShadow>[
                            BoxShadow(
                              color: entry.value.withOpacity(0.45),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: entry.value.computeLuminance() > 0.6
                              ? theme.ink
                              : Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.key,
                  style: AppTextStyles.caption(theme.tertiary).copyWith(fontSize: 9.5),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
