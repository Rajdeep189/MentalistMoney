import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/settings_tiles.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const String version = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.x4,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                height: 84,
                width: 84,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[palette.accent, palette.accent.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.x3),
              Text('MoneyMan', style: context.h1),
              const SizedBox(height: 4),
              Text('Track every Money. Own your money.', style: context.bodyMuted),
              const SizedBox(height: 6),
              Text('Version $version', style: context.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          const SettingsSectionTitle('Principles'),
          AppCard(
            child: Column(
              children: <Widget>[
                _bullet(context, Icons.wifi_off_rounded, 'Fully offline',
                    'Every number comes from a local SQLite ledger. Nothing is uploaded.'),
                _bullet(context, Icons.lock_outline_rounded, 'No login',
                    'No email, no phone, no OTP. Open the app and start tracking.'),
                _bullet(context, Icons.receipt_long_outlined, 'Your data, your file',
                    'Export CSV, PDF or a complete JSON backup whenever you want.'),
                _bullet(context, Icons.favorite_outline_rounded, 'Made for India',
                    'Rupee-first formatting, UPI, UPI-lite and Indian payment methods.'),
              ],
            ),
          ),
          const SettingsSectionTitle('More'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Share MoneyMan',
                icon: Icons.ios_share_rounded,
                onTap: () => Share.share(
                  'I track my money with MoneyMan — offline, private and fast. '
                  'Track every Money. Own your money.',
                ),
              ),
              SettingsTile(
                title: 'Rate this app',
                subtitle: 'Tell us how it is working for you',
                icon: Icons.star_border_rounded,
                onTap: () => Share.share(
                  'Loving MoneyMan v$version. Track every Money. Own your money.',
                ),
              ),
              SettingsTile(
                title: 'Open source licences',
                icon: Icons.description_outlined,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'MoneyMan',
                  applicationVersion: version,
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CategoryIcon(
                      icon: Icons.account_balance_wallet_rounded,
                      color: palette.accent,
                      size: 46,
                      rounded: true,
                    ),
                  ),
                ),
              ),
              SettingsTile(
                title: 'Privacy policy',
                subtitle: 'Short version: nothing leaves your phone',
                icon: Icons.privacy_tip_outlined,
                onTap: () => _showPrivacy(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          Center(
            child: Text(
              settings.isPremium ? 'Premium unlocked — thank you!' : 'Free plan',
              style: AppTextStyles.caption(palette.accent),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          SecondaryButton(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, IconData icon, String title, String body) {
    final palette = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CategoryIcon(icon: icon, color: palette.accent, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyles.label(palette.ink)),
                const SizedBox(height: 2),
                Text(body,
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'MoneyMan stores everything in a database file inside the app\'s private storage '
            'on your device.\n\n'
            '• No account or sign-in is required.\n'
            '• No analytics, ads or crash reporting SDKs are included.\n'
            '• No bank connections are made.\n'
            '• Data only leaves the device when you export a file and share it.\n'
            '• Deleting the app removes the database permanently.\n\n'
            'Contact: privacy@moneyman.app',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
