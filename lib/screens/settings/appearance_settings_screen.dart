import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/fields.dart';
import '../../widgets/premium_badge.dart';
import '../../widgets/settings_tiles.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  static const Map<String, Color> _accents = <String, Color>{
    'Violet': Color(0xFF916CFF),
    'Indigo': Color(0xFF5B6BFF),
    'Ocean': Color(0xFF2E90FA),
    'Forest': Color(0xFF12B76A),
    'Amber': Color(0xFFF79009),
    'Rose': Color(0xFFF04438),
    'Graphite': Color(0xFF3A3A44),
  };

  Future<void> _save(String key, String value) async {
    await ref.read(settingsRepositoryProvider).set(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          const SettingsSectionTitle('Theme'),
          SettingsGroup(
            children: <Widget>[
              SettingsChoiceRow<String>(
                options: const <String>['system', 'light', 'dark'],
                value: settings.themeModeName,
                labelOf: (value) => value == 'system'
                    ? 'System'
                    : value == 'light'
                        ? 'Light'
                        : 'Dark',
                onChanged: (value) => _save(SettingsKeys.themeMode, value),
              ),
            ],
          ),
          const SettingsSectionTitle('Accent colour'),
          SettingsGroup(
            children: <Widget>[
              AccentSwatches(
                selectedHex: AppColors.toHex(settings.accentColor),
                palette: _accents,
                onChanged: (hex) => _save(SettingsKeys.accentColor, hex),
              ),
            ],
          ),
          const SettingsSectionTitle('Theme packs'),
          ...ThemePack.packs.map((pack) {
            final selected = settings.themePack == pack.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x2),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.x4),
                onTap: () async {
                  if (pack.premium && !settings.isPremium) {
                    await ensurePremium(
                      context,
                      ref,
                      feature: '${pack.name} theme pack',
                      description:
                          'Premium unlocks every theme pack, including Midnight, Ocean and Forest.',
                    );
                    return;
                  }
                  await ref
                      .read(settingsRepositoryProvider)
                      .setMany(<String, String>{
                    SettingsKeys.themePack: pack.id,
                    SettingsKeys.accentColor: AppColors.toHex(pack.accent),
                  });
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[pack.accent, pack.accent.withOpacity(0.55)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Text(pack.name, style: AppTextStyles.label(palette.ink)),
                          if (pack.premium) ...<Widget>[
                            const SizedBox(width: 6),
                            const PremiumBadge(dense: true),
                          ],
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_rounded, size: 18, color: palette.accent),
                  ],
                ),
              ),
            );
          }),
          const SettingsSectionTitle('Type'),
          SettingsGroup(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.x3, 8, AppSpacing.x3, 4),
                child: Row(
                  children: <Widget>[
                    Text('Text size', style: AppTextStyles.body(palette.ink)),
                    const Spacer(),
                    Text('${(settings.fontScale * 100).round()}%',
                        style: context.caption),
                  ],
                ),
              ),
              Slider(
                value: settings.fontScale.clamp(0.85, 1.35).toDouble(),
                min: 0.85,
                max: 1.35,
                divisions: 5,
                activeColor: palette.accent,
                label: '${(settings.fontScale * 100).round()}%',
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .set(SettingsKeys.fontScale, value.toStringAsFixed(2)),
              ),
              SettingsChoiceRow<String>(
                options: const <String>['comfortable', 'compact'],
                value: settings.compactDensity ? 'compact' : 'comfortable',
                labelOf: (value) => value == 'compact' ? 'Compact' : 'Comfortable',
                onChanged: (value) => _save(SettingsKeys.density, value),
              ),
              SettingsChoiceRow<String>(
                options: const <String>['full', 'compact_amount', 'hidden'],
                value: settings.amountStyle,
                labelOf: (value) => value == 'full'
                    ? 'Full amounts'
                    : value == 'compact_amount'
                        ? 'Short (12.4K)'
                        : 'Hidden',
                onChanged: (value) => _save(SettingsKeys.amountStyle, value),
              ),
            ],
          ),
          const SettingsSectionTitle('Dashboard'),
          SettingsGroup(
            children: <Widget>[
              SwitchRow(
                title: 'Category colours',
                subtitle: 'Tint icons with category colours',
                value: settings.showCategoryColors,
                icon: Icons.palette_rounded,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .setBool(SettingsKeys.showCategoryColors, value),
              ),
              SwitchRow(
                title: 'Account colours',
                value: settings.showAccountColors,
                icon: Icons.account_balance_wallet_rounded,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .setBool(SettingsKeys.showAccountColors, value),
              ),
              SettingsTile(
                title: 'Dashboard cards',
                subtitle:
                    '${settings.visibleCards.length} of ${DashboardCard.all.length} visible',
                icon: Icons.dashboard_customize_outlined,
                onTap: () => _editDashboard(context, ref, settings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
        ],
      ),
    );
  }

  Future<void> _editDashboard(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final order = List<String>.from(settings.dashboardOrder);
    final hidden = Set<String>.from(settings.hiddenCards);

    await showAppSheet<void>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SheetHeader(title: 'Dashboard cards'),
            Flexible(
              child: ReorderableListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = order.removeAt(oldIndex);
                  order.insert(newIndex, item);
                  setSheetState(() {});
                },
                children: order
                    .map(
                      (id) => SwitchListTile(
                        key: ValueKey<String>(id),
                        contentPadding: EdgeInsets.zero,
                        title: Text(DashboardCard.label(id)),
                        value: !hidden.contains(id),
                        activeColor: context.c.accent,
                        onChanged: (value) => setSheetState(() {
                          if (value) {
                            hidden.remove(id);
                          } else {
                            hidden.add(id);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x3,
                AppSpacing.x5,
                AppSpacing.x6,
              ),
              child: PrimaryButton(
                label: 'Save layout',
                onPressed: () async {
                  await ref.read(settingsRepositoryProvider).setMany(<String, String>{
                    SettingsKeys.dashboardOrder: order.join(','),
                    SettingsKeys.dashboardCards: hidden.join(','),
                  });
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
