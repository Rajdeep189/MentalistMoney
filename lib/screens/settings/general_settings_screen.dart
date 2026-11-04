import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/fields.dart';
import '../../widgets/settings_tiles.dart';

class GeneralSettingsScreen extends ConsumerWidget {
  const GeneralSettingsScreen({super.key});

  static const List<MapEntry<String, String>> _currencies =
      <MapEntry<String, String>>[
    MapEntry<String, String>('INR', '₹'),
    MapEntry<String, String>('USD', '\$'),
    MapEntry<String, String>('EUR', '€'),
    MapEntry<String, String>('GBP', '£'),
    MapEntry<String, String>('AED', 'د.إ'),
    MapEntry<String, String>('SGD', 'S\$'),
    MapEntry<String, String>('AUD', 'A\$'),
    MapEntry<String, String>('CAD', 'C\$'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final repo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('General')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          const SettingsSectionTitle('Region'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Currency',
                subtitle: '${settings.currencyCode} · ${settings.currencySymbol}',
                icon: Icons.currency_rupee_rounded,
                onTap: () async {
                  final selected = await showAppSelectionSheet<MapEntry<String, String>>(
                    context,
                    title: 'Currency',
                    items: _currencies,
                    labelOf: (entry) => '${entry.key} (${entry.value})',
                    selected: _currencies.firstWhere(
                      (entry) => entry.key == settings.currencyCode,
                      orElse: () => _currencies.first,
                    ),
                  );
                  if (selected == null) return;
                  await repo.setMany(<String, String>{
                    SettingsKeys.currencyCode: selected.key,
                    SettingsKeys.currencySymbol: selected.value,
                  });
                },
              ),
              SettingsTile(
                title: 'Language',
                subtitle: settings.language == 'hi' ? 'हिन्दी' : 'English',
                icon: Icons.translate_rounded,
                onTap: () async {
                  final selected = await showAppSelectionSheet<String>(
                    context,
                    title: 'Language',
                    items: const <String>['en', 'hi'],
                    labelOf: (value) => value == 'hi' ? 'हिन्दी' : 'English',
                    selected: settings.language,
                  );
                  if (selected == null) return;
                  await repo.set(SettingsKeys.language, selected);
                },
              ),
              SettingsTile(
                title: 'Date format',
                subtitle: settings.dateFormat,
                icon: Icons.event_outlined,
                onTap: () async {
                  final selected = await showAppSelectionSheet<String>(
                    context,
                    title: 'Date format',
                    items: const <String>[
                      'dd/MM/yyyy',
                      'MM/dd/yyyy',
                      'dd MMM yyyy',
                      'yyyy-MM-dd',
                    ],
                    labelOf: (value) => value,
                    selected: settings.dateFormat,
                  );
                  if (selected == null) return;
                  await repo.set(SettingsKeys.dateFormat, selected);
                },
              ),
              SettingsTile(
                title: 'First day of week',
                subtitle: settings.firstDayOfWeek == 1 ? 'Monday' : 'Sunday',
                icon: Icons.view_week_outlined,
                onTap: () async {
                  final selected = await showAppSelectionSheet<int>(
                    context,
                    title: 'First day of week',
                    items: const <int>[1, 7],
                    labelOf: (value) => value == 1 ? 'Monday' : 'Sunday',
                    selected: settings.firstDayOfWeek,
                  );
                  if (selected == null) return;
                  await repo.setInt(SettingsKeys.firstDayOfWeek, selected);
                },
              ),
              SettingsTile(
                title: 'Month starts on',
                subtitle: 'Day ${settings.startOfMonth}',
                icon: Icons.calendar_today_outlined,
                onTap: () async {
                  final selected = await showAppSelectionSheet<int>(
                    context,
                    title: 'Budget month starts on',
                    items: List<int>.generate(28, (index) => index + 1),
                    labelOf: (value) => 'Day $value',
                    selected: settings.startOfMonth,
                  );
                  if (selected == null) return;
                  await repo.setInt(SettingsKeys.startOfMonth, selected);
                },
              ),
            ],
          ),
          const SettingsSectionTitle('Numbers'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Decimal digits',
                subtitle: '${settings.decimalDigits} places',
                icon: Icons.pin_outlined,
                onTap: () async {
                  final selected = await showAppSelectionSheet<int>(
                    context,
                    title: 'Decimal digits',
                    items: const <int>[0, 2],
                    labelOf: (value) => value == 0 ? 'None' : '2 places',
                    selected: settings.decimalDigits,
                  );
                  if (selected == null) return;
                  await repo.setInt(SettingsKeys.decimalDigits, selected);
                },
              ),
              SwitchRow(
                title: 'Symbol before amount',
                subtitle: settings.symbolBefore ? '₹1,200' : '1,200 ₹',
                value: settings.symbolBefore,
                icon: Icons.text_fields_rounded,
                onChanged: (value) =>
                    repo.setBool(SettingsKeys.symbolBefore, value),
              ),
            ],
          ),
          const SettingsSectionTitle('Defaults for new transactions'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Default account',
                subtitle: accounts
                    .where((account) => account.id == settings.defaultAccountId)
                    .map((account) => account.name)
                    .join(),
                icon: Icons.account_balance_wallet_outlined,
                onTap: () async {
                  final selected = await showAppSelectionSheet<Account>(
                    context,
                    title: 'Default account',
                    items: accounts,
                    labelOf: (account) => account.name,
                    selected: accounts
                        .cast<Account?>()
                        .firstWhere((a) => a?.id == settings.defaultAccountId,
                            orElse: () => null),
                  );
                  if (selected?.id == null) return;
                  await repo.setInt(SettingsKeys.defaultAccountId, selected!.id!);
                },
              ),
              SettingsTile(
                title: 'Default category',
                subtitle: categories
                    .where((category) => category.id == settings.defaultCategoryId)
                    .map((category) => category.name)
                    .join(),
                icon: Icons.category_outlined,
                onTap: () async {
                  final selected = await showAppSelectionSheet<Category>(
                    context,
                    title: 'Default category',
                    items: categories,
                    labelOf: (category) => category.name,
                    selected: categories
                        .cast<Category?>()
                        .firstWhere((c) => c?.id == settings.defaultCategoryId,
                            orElse: () => null),
                  );
                  if (selected?.id == null) return;
                  await repo.setInt(SettingsKeys.defaultCategoryId, selected!.id!);
                },
              ),
              SettingsChoiceRow<String>(
                options: const <String>[kTypeExpense, kTypeIncome, kTypeTransfer],
                value: settings.defaultTxnType,
                labelOf: (value) => value == kTypeExpense
                    ? 'Expense'
                    : value == kTypeIncome
                        ? 'Income'
                        : 'Transfer',
                onChanged: (value) => repo.set(SettingsKeys.defaultTxnType, value),
              ),
              SettingsChoiceRow<String>(
                options: kPaymentMethods,
                value: settings.defaultPaymentMethod,
                onChanged: (value) =>
                    repo.set(SettingsKeys.defaultPaymentMethod, value),
              ),
            ],
          ),
          const SettingsSectionTitle('Feedback'),
          SettingsGroup(
            children: <Widget>[
              SwitchRow(
                title: 'Haptic feedback',
                value: settings.haptics,
                icon: Icons.vibration_rounded,
                onChanged: (value) => repo.setBool(SettingsKeys.haptics, value),
              ),
              SwitchRow(
                title: 'Sounds',
                subtitle: 'Play a soft tone when adding transactions',
                value: settings.sounds,
                icon: Icons.volume_up_outlined,
                onChanged: (value) => repo.setBool(SettingsKeys.sounds, value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Changing the currency only changes formatting — existing amounts are not converted.',
            style: AppTextStyles.caption(palette.tertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
