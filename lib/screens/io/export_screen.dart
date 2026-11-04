import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/pickers.dart';
import '../../widgets/settings_tiles.dart';
import 'data_backup_screen.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, this.isBudgetReport = false});

  final bool isBudgetReport;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late StatsRange _range = defaultStatsRange();
  bool _includeTransactions = true;
  bool _premiumBranding = false;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) showSnack(context, 'Export failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv() async {
    await _run(() async {
      final file = await ref.read(exportRepositoryProvider).exportCsv(
            start: _range.start,
            end: _range.end,
          );
      await Share.shareXFiles(<XFile>[XFile(file.path)], text: 'MoneyMan CSV export');
      if (mounted) showSnack(context, 'CSV exported: ${file.path.split('/').last}');
    });
  }

  Future<void> _exportPdf() async {
    await _run(() async {
      final budgets = ref.read(budgetsProvider).valueOrNull ?? const <BudgetProgress>[];
      final file = await ref.read(exportRepositoryProvider).exportPdf(
            start: _range.start,
            end: _range.end,
            title: widget.isBudgetReport ? 'Budget report' : 'MoneyMan report',
            includeTransactions: _includeTransactions,
            premiumBranding: _premiumBranding,
            budgets: widget.isBudgetReport ? budgets : const <BudgetProgress>[],
          );
      await Share.shareXFiles(<XFile>[XFile(file.path)], text: 'MoneyMan PDF report');
      if (mounted) showSnack(context, 'PDF ready: ${file.path.split('/').last}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const <BudgetProgress>[];
    final settings = ref.watch(settingsSnapshotProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: Text(widget.isBudgetReport ? 'Budget report' : 'Export')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.x2,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          if (widget.isBudgetReport) ...<Widget>[
            AppCard(
              color: palette.accentSoft,
              child: Row(
                children: <Widget>[
                  Icon(Icons.pie_chart_rounded, size: 18, color: palette.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${budgets.length} budgets will be included with a spent vs limit breakdown.',
                      style: AppTextStyles.caption(palette.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
          ],
          const SettingsSectionTitle('Date range'),
          DateRangeChips(
            ranges: buildDateRanges(firstDayOfWeek: settings.firstDayOfWeek),
            selectedLabel: _range.label,
            onSelected: (value) => setState(() {
              _range = StatsRange(label: value.label, start: value.start, end: value.end);
            }),
            onCustom: () async {
              final custom = await pickCustomRange(context, start: _range.start);
              if (custom == null) return;
              setState(() {
                _range = StatsRange(label: 'Custom', start: custom.start, end: custom.end);
              });
            },
          ),
          const SizedBox(height: AppSpacing.x4),
          const SettingsSectionTitle('Options'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 4),
            child: Column(
              children: <Widget>[
                SwitchRow(
                  title: 'Include transactions',
                  subtitle: 'Adds a transaction table to the PDF',
                  value: _includeTransactions,
                  icon: Icons.receipt_long_outlined,
                  onChanged: (value) => setState(() => _includeTransactions = value),
                ),
                Divider(color: palette.divider, height: 1),
                SwitchRow(
                  title: 'Premium branding',
                  subtitle: 'Violet accents on the PDF',
                  value: _premiumBranding,
                  icon: Icons.workspace_premium_outlined,
                  onChanged: (value) => setState(() => _premiumBranding = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          const SettingsSectionTitle('Export'),
          PrimaryButton(
            label: 'Export PDF',
            icon: Icons.picture_as_pdf_rounded,
            loading: _busy,
            onPressed: _busy ? null : _exportPdf,
          ),
          const SizedBox(height: AppSpacing.x2),
          SecondaryButton(
            label: 'Export CSV',
            icon: Icons.table_chart_rounded,
            onPressed: _busy ? null : _exportCsv,
          ),
          const SizedBox(height: AppSpacing.x2),
          SecondaryButton(
            label: 'Full JSON backup',
            icon: Icons.backup_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DataBackupScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            'Files are written to the app documents folder and then handed to the '
            'system share sheet — choose Gmail, Drive, WhatsApp or Save to device.',
            style: context.caption,
          ),
          const SizedBox(height: AppSpacing.x6),
          Center(
            child: Text(
              'Range: ${Fmt.date(_range.start.millisecondsSinceEpoch)} → '
              '${Fmt.date(_range.end.millisecondsSinceEpoch)}',
              style: AppTextStyles.caption(palette.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}
