import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/biometric_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/pickers.dart';

/// First-launch setup: currency, week start, theme, language, first account,
/// biometric lock and optional demo data.
class FirstRunSetupScreen extends ConsumerStatefulWidget {
  const FirstRunSetupScreen({super.key});

  @override
  ConsumerState<FirstRunSetupScreen> createState() => _FirstRunSetupScreenState();
}

class _FirstRunSetupScreenState extends ConsumerState<FirstRunSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountNameController =
      TextEditingController(text: 'Cash');
  int _openingBalance = 0;
  String _currency = 'INR';
  String _symbol = '₹';
  int _firstDay = 7;
  String _theme = 'system';
  String _language = 'en';
  String _accountType = kAccountCash;
  bool _biometric = false;
  bool _demoData = true;
  bool _biometricAvailable = false;
  bool _saving = false;

  static const Map<String, String> _currencies = <String, String>{
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
    'SGD': 'S\$',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  @override
  void initState() {
    super.initState();
    BiometricService.instance.isAvailable().then((available) {
      if (mounted) setState(() => _biometricAvailable = available);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _complete({bool createAccount = true}) async {
    if (createAccount && _accountNameController.text.trim().isEmpty) {
      showSnack(context, 'Give your first account a name', error: true);
      return;
    }
    setState(() => _saving = true);
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final accountsRepo = ref.read(accountRepositoryProvider);

    await settingsRepo.setMany(<String, String>{
      SettingsKeys.userName:
          _nameController.text.trim().isEmpty ? 'there' : _nameController.text.trim(),
      SettingsKeys.currencyCode: _currency,
      SettingsKeys.currencySymbol: _symbol,
      SettingsKeys.firstDayOfWeek: '$_firstDay',
      SettingsKeys.themeMode: _theme,
      SettingsKeys.language: _language,
      SettingsKeys.biometricLock: _biometric ? 'true' : 'false',
      SettingsKeys.onboardingDone: 'true',
    });

    if (createAccount) {
      final id = await accountsRepo.create(Account(
        name: _accountNameController.text.trim(),
        type: _accountType,
        icon: _accountType == kAccountBank ? 'account_balance' : 'wallet',
        color: '#916CFF',
        openingBalance: _openingBalance,
        currency: _currency,
      ));
      await settingsRepo.setInt(SettingsKeys.defaultAccountId, id);
    }

    if (_demoData) {
      await ref.read(settingsRepositoryProvider).setBool(SettingsKeys.demoData, true);
      await ref.read(databaseProvider).seedDemoData();
    }

    await settingsRepo.setBool(SettingsKeys.onboardingDone, true);
    ref.invalidate(settingsProvider);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.x4,
            AppSpacing.screen,
            AppSpacing.x10,
          ),
          children: <Widget>[
            Text('Let\'s set up MoneyMan', style: context.displayL),
            const SizedBox(height: 4),
            Text(
              'Everything stays on this device. You can change any of this later.',
              style: AppTextStyles.body(palette.sub),
            ),
            const SizedBox(height: AppSpacing.x6),
            AppTextField(
              controller: _nameController,
              label: 'What should we call you?',
              hint: 'Your name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.x4),
            Text('Currency', style: AppTextStyles.label(palette.sub)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currencies.entries.map((entry) {
                return AppChip(
                  label: '${entry.value} ${entry.key}',
                  selected: _currency == entry.key,
                  onTap: () => setState(() {
                    _currency = entry.key;
                    _symbol = entry.value;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.x5),
            SegmentedControl<int>(
              options: const <SegmentOption<int>>[
                SegmentOption(value: 7, label: 'Sunday first'),
                SegmentOption(value: 1, label: 'Monday first'),
              ],
              value: _firstDay,
              onChanged: (value) => setState(() => _firstDay = value),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text('Theme', style: AppTextStyles.label(palette.sub)),
            const SizedBox(height: 8),
            SegmentedControl<String>(
              options: const <SegmentOption<String>>[
                SegmentOption(value: 'light', label: 'Light'),
                SegmentOption(value: 'dark', label: 'Dark'),
                SegmentOption(value: 'system', label: 'System'),
              ],
              value: _theme,
              onChanged: (value) => setState(() => _theme = value),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text('Language', style: AppTextStyles.label(palette.sub)),
            const SizedBox(height: 8),
            SegmentedControl<String>(
              options: const <SegmentOption<String>>[
                SegmentOption(value: 'en', label: 'English'),
                SegmentOption(value: 'hi', label: 'हिन्दी'),
              ],
              value: _language,
              onChanged: (value) => setState(() => _language = value),
            ),
            const SizedBox(height: AppSpacing.x6),
            Text('First account', style: context.h3),
            const SizedBox(height: AppSpacing.x2),
            AppTextField(
              controller: _accountNameController,
              label: 'Account name',
              hint: 'Cash, HDFC Savings, Paytm…',
              prefixIcon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: AppSpacing.x3),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <String>[
                kAccountCash,
                kAccountBank,
                kAccountCredit,
                kAccountWallet,
              ].map((type) {
                return AppChip(
                  label: accountTypeLabel(type),
                  selected: _accountType == type,
                  onTap: () => setState(() => _accountType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.x4),
            AmountField(
              paise: _openingBalance,
              onChanged: (value) => setState(() => _openingBalance = value),
              label: 'Opening balance (${Fmt.symbol})',
            ),
            const SizedBox(height: AppSpacing.x5),
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x4,
                vertical: 4,
              ),
              child: Column(
                children: <Widget>[
                  SwitchRow(
                    title: 'Enable biometric lock',
                    subtitle: _biometricAvailable
                        ? 'Lock MoneyMan with your fingerprint or face'
                        : 'No biometric hardware detected on this device',
                    value: _biometric && _biometricAvailable,
                    onChanged: _biometricAvailable
                        ? (value) => setState(() => _biometric = value)
                        : (_) {},
                    icon: Icons.fingerprint_rounded,
                  ),
                  Divider(color: palette.divider, height: 1),
                  SwitchRow(
                    title: 'Start with demo data',
                    subtitle: 'Sample accounts, budgets and transactions to explore',
                    value: _demoData,
                    onChanged: (value) => setState(() => _demoData = value),
                    icon: Icons.auto_awesome_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            PrimaryButton(
              label: 'Start using MoneyMan',
              icon: Icons.arrow_forward_rounded,
              loading: _saving,
              onPressed: _saving ? null : () => _complete(),
            ),
            const SizedBox(height: AppSpacing.x2),
            TextButton(
              onPressed: _saving ? null : () => _complete(createAccount: false),
              child: Text(
                'Skip — I will add an account later',
                style: AppTextStyles.label(palette.sub),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
