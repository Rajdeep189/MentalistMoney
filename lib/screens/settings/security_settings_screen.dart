import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../services/biometric_service.dart';
import '../../services/secure_screen_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/settings_tiles.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  Future<void> _toggleBiometric(bool value) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (value) {
      final available = await BiometricService.instance.isAvailable();
      if (!available) {
        if (mounted) {
          showSnack(context, 'No biometric hardware is set up on this device',
              error: true);
        }
        return;
      }
      final ok = await BiometricService.instance
          .authenticate(reason: 'Confirm it is you to enable biometric lock');
      if (!ok) return;
    }
    await repo.setBool(SettingsKeys.biometricLock, value);
    if (mounted) {
      showSnack(context, value ? 'Biometric lock enabled' : 'Biometric lock off');
    }
  }

  Future<void> _setPin() async {
    final controller = TextEditingController();
    final confirm = TextEditingController();
    final result = await showAppSheet<bool>(
      context,
      (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SheetHeader(title: 'Set a 4-digit PIN'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
              child: Column(
                children: <Widget>[
                  AppTextField(
                    controller: controller,
                    label: 'PIN',
                    hint: '••••',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  AppTextField(
                    controller: confirm,
                    label: 'Confirm PIN',
                    hint: '••••',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Text(
                    'The PIN is stored locally on this device only. If you forget it you will have to reset the app.',
                    style: context.caption,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  PrimaryButton(
                    label: 'Save PIN',
                    onPressed: () {
                      final pin = controller.text.trim();
                      if (pin.length != 4 || int.tryParse(pin) == null) {
                        showSnack(sheetContext, 'Enter exactly 4 digits', error: true);
                        return;
                      }
                      if (pin != confirm.text.trim()) {
                        showSnack(sheetContext, 'PINs do not match', error: true);
                        return;
                      }
                      Navigator.of(sheetContext).pop(true);
                    },
                  ),
                  const SizedBox(height: AppSpacing.x6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      await ref.read(settingsRepositoryProvider).set(SettingsKeys.pinLock, controller.text.trim());
      if (mounted) showSnack(context, 'PIN lock enabled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);
    final repo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('Privacy & security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          const SettingsSectionTitle('Unlock'),
          SettingsGroup(
            children: <Widget>[
              SwitchRow(
                title: 'Biometric unlock',
                subtitle: 'Fingerprint or face to open MoneyMan',
                value: settings.biometricLock,
                icon: Icons.fingerprint_rounded,
                onChanged: _toggleBiometric,
              ),
              SettingsTile(
                title: settings.pinLock == null ? 'Set PIN lock' : 'Change PIN',
                subtitle: settings.pinLock == null
                    ? 'Fallback when biometrics fail'
                    : 'PIN lock is active',
                icon: Icons.pin_rounded,
                onTap: _setPin,
              ),
              if (settings.pinLock != null)
                SettingsTile(
                  title: 'Remove PIN',
                  icon: Icons.lock_open_rounded,
                  onTap: () async {
                    final ok = await confirmAction(
                      context,
                      title: 'Remove PIN lock?',
                      message: 'MoneyMan will open without asking for a PIN.',
                    );
                    if (!ok) return;
                    await repo.set(SettingsKeys.pinLock, '');
                    if (mounted) showSnack(context, 'PIN removed');
                  },
                ),
              SettingsChoiceRow<int>(
                options: const <int>[0, 1, 5, 15],
                value: settings.autoLockMinutes,
                labelOf: (value) => value == 0 ? 'Immediately' : '$value min',
                onChanged: (value) => repo.setInt(SettingsKeys.autoLockMinutes, value),
              ),
            ],
          ),
          const SettingsSectionTitle('Privacy'),
          SettingsGroup(
            children: <Widget>[
              SwitchRow(
                title: 'Hide balances on dashboard',
                subtitle: 'Reveal with a tap',
                value: settings.privacyHideBalances,
                icon: Icons.visibility_off_outlined,
                onChanged: (value) =>
                    repo.setBool(SettingsKeys.privacyHideBalances, value),
              ),
              SwitchRow(
                title: 'Hide dashboard amounts',
                subtitle: 'Show dots instead of money',
                value: settings.privacyHideDashboard,
                icon: Icons.blur_on_rounded,
                onChanged: (value) =>
                    repo.setBool(SettingsKeys.privacyHideDashboard, value),
              ),
              SwitchRow(
                title: 'Hide all amounts',
                subtitle: 'Useful in public',
                value: settings.hideAmountsGlobal,
                icon: Icons.money_off_rounded,
                onChanged: (value) =>
                    repo.setBool(SettingsKeys.hideAmountsGlobal, value),
              ),
              SwitchRow(
                title: 'Block screenshots',
                subtitle: 'Adds FLAG_SECURE while the app is open',
                value: settings.blockScreenshots,
                icon: Icons.screenshot_monitor_outlined,
                onChanged: (value) async {
                  await repo.setBool(SettingsKeys.blockScreenshots, value);
                  await SecureScreenService.instance.setSecure(value);
                },
              ),
            ],
          ),
          const SettingsSectionTitle('Storage'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Offline by design',
                subtitle: 'No accounts, no servers, no trackers',
                icon: Icons.cloud_off_rounded,
                dense: true,
              ),
              SettingsTile(
                title: 'Data ownership',
                subtitle: 'Export a JSON backup any time from Data & backup',
                icon: Icons.verified_user_outlined,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          AppCard(
            color: palette.accentSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.shield_rounded, size: 18, color: palette.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your database never leaves this device unless you explicitly export it. Locking the app adds a second layer on top of Android\'s own screen lock.',
                    style: AppTextStyles.caption(palette.accent).copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
