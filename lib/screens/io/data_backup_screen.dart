import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/settings_tiles.dart';
import 'csv_import_screen.dart';
import 'export_screen.dart';

class DataBackupScreen extends ConsumerStatefulWidget {
  const DataBackupScreen({super.key});

  @override
  ConsumerState<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends ConsumerState<DataBackupScreen> {
  bool _busy = false;
  String? _lastBackupPath;

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      final file = await ref.read(exportRepositoryProvider).exportBackupJson();
      await ref.read(settingsRepositoryProvider).setInt(
            SettingsKeys.lastBackupAt,
            DateTime.now().millisecondsSinceEpoch,
          );
      if (!mounted) return;
      setState(() => _lastBackupPath = file.path);
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        subject: 'MoneyMan backup',
        text: 'MoneyMan backup — keep it somewhere safe.',
      );
      if (mounted) showSnack(context, 'Backup created');
    } catch (error) {
      if (mounted) showSnack(context, 'Backup failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    if (!mounted) return;

    final mode = await showAppSheet<String>(
      context,
      (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SheetHeader(title: 'Restore backup'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
            child: Column(
              children: <Widget>[
                _restoreOption(
                  context,
                  icon: Icons.merge_type_rounded,
                  title: 'Merge with current data',
                  body: 'Keeps everything you have now and adds missing rows.',
                  onTap: () => Navigator.of(sheetContext).pop('merge'),
                ),
                const SizedBox(height: AppSpacing.x2),
                _restoreOption(
                  context,
                  icon: Icons.restore_rounded,
                  title: 'Replace everything',
                  body: 'Wipes the current database and restores the file exactly.',
                  onTap: () => Navigator.of(sheetContext).pop('replace'),
                ),
                const SizedBox(height: AppSpacing.x6),
              ],
            ),
          ),
        ],
      ),
    );
    if (mode == null) return;

    setState(() => _busy = true);
    try {
      final message = await ref
          .read(exportRepositoryProvider)
          .restoreBackupJson(File(path), merge: mode == 'merge');
      if (!mounted) return;
      showSnack(context, message);
    } catch (error) {
      if (mounted) showSnack(context, 'Restore failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearData() async {
    final ok = await confirmAction(
      context,
      title: 'Delete all data?',
      message:
          'Every transaction, account, budget, goal, bill and split will be erased. This cannot be undone.',
      confirmLabel: 'Delete everything',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(databaseProvider).wipeData();
      await ref.read(settingsRepositoryProvider).setBool(SettingsKeys.demoData, false);
      if (mounted) showSnack(context, 'All data deleted');
    } catch (error) {
      if (mounted) showSnack(context, 'Could not clear data: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadDemo() async {
    final ok = await confirmAction(
      context,
      title: 'Load demo data?',
      message:
          'Adds a realistic sample ledger so you can explore charts. You can delete it later by clearing all data.',
      confirmLabel: 'Load demo',
      destructive: false,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(databaseProvider).seedDemoData();
      await ref.read(settingsRepositoryProvider).setBool(SettingsKeys.demoData, true);
      if (mounted) showSnack(context, 'Demo data loaded');
    } catch (error) {
      if (mounted) showSnack(context, 'Could not load demo data: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);
    final last = settings.lastBackupAt;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('Data & backup')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.x2,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          AppCard(
            color: palette.accentSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.cloud_off_rounded, size: 18, color: palette.accent),
                    const SizedBox(width: 8),
                    Text('Local-only storage',
                        style: AppTextStyles.label(palette.onSoft)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your ledger lives in a SQLite file inside the app. A backup is a single JSON file you control.',
                  style: AppTextStyles.caption(palette.onSoft).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          const SettingsSectionTitle('Backup'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Create backup now',
                subtitle: last == null
                    ? 'No backup yet'
                    : 'Last backup ${Fmt.date(last)} · ${Fmt.time(last)}',
                icon: Icons.backup_rounded,
                trailing: _busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _busy ? null : _backup,
              ),
              if (_lastBackupPath != null)
                SettingsTile(
                  title: 'Share last backup again',
                  subtitle: _lastBackupPath!.split('/').last,
                  icon: Icons.ios_share_rounded,
                  onTap: () => Share.shareXFiles(
                    <XFile>[XFile(_lastBackupPath!)],
                    subject: 'MoneyMan backup',
                  ),
                ),
              SettingsTile(
                title: 'Restore from backup',
                subtitle: 'Merge or replace your current data',
                icon: Icons.restore_rounded,
                onTap: _busy ? null : _restore,
              ),
              SettingsTile(
                title: 'Automatic backup reminder',
                subtitle: settings.autoBackupFrequency == 'manual'
                    ? 'Manual only'
                    : 'Every ${settings.autoBackupFrequency}',
                icon: Icons.schedule_rounded,
                onTap: () async {
                  final selected = await showAppSelectionSheet<String>(
                    context,
                    title: 'Remind me to back up',
                    items: const <String>['manual', 'week', 'month'],
                    labelOf: (value) => value == 'manual'
                        ? 'Manual only'
                        : value == 'week'
                            ? 'Every week'
                            : 'Every month',
                    selected: settings.autoBackupFrequency,
                  );
                  if (selected == null) return;
                  await ref
                      .read(settingsRepositoryProvider)
                      .set(SettingsKeys.autoBackupFrequency, selected);
                },
              ),
            ],
          ),
          const SettingsSectionTitle('Export'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'PDF report',
                subtitle: 'Branded, print-ready summary',
                icon: Icons.picture_as_pdf_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ExportScreen()),
                ),
              ),
              SettingsTile(
                title: 'CSV export',
                subtitle: 'Spreadsheet friendly',
                icon: Icons.table_chart_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ExportScreen()),
                ),
              ),
              SettingsTile(
                title: 'Import from CSV',
                subtitle: 'Bring in a bank statement',
                icon: Icons.upload_file_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CsvImportScreen()),
                ),
              ),
            ],
          ),
          const SettingsSectionTitle('Danger zone'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Load demo data',
                subtitle: 'Sample accounts, transactions, budgets and goals',
                icon: Icons.auto_awesome_rounded,
                onTap: _busy ? null : _loadDemo,
              ),
              SettingsTile(
                title: 'Delete all data',
                subtitle: 'Cannot be undone',
                icon: Icons.delete_forever_rounded,
                iconColor: palette.expense,
                onTap: _busy ? null : _clearData,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          SecondaryButton(
            label: 'Create backup',
            icon: Icons.backup_rounded,
            onPressed: _busy ? null : _backup,
          ),
        ],
      ),
    );
  }

  Widget _restoreOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required VoidCallback onTap,
  }) {
    final palette = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: palette.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: AppTextStyles.label(palette.ink)),
                  const SizedBox(height: 2),
                  Text(body, style: context.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
