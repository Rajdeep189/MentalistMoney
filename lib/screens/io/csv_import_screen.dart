import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';
import '../../data/repositories/import_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fields.dart';
import '../../widgets/illustration.dart';
import '../../widgets/pickers.dart';
import '../../widgets/settings_tiles.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  CsvPreview? _preview;
  CsvMapping _mapping = const CsvMapping();
  String _defaultType = kTypeExpense;
  int? _defaultAccountId;
  String? _fileName;
  bool _busy = false;
  ImportResult? _result;

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'txt'],
      withData: false,
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final preview = await ref.read(importRepositoryProvider).readCsv(File(path));
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _mapping = CsvMapping.autoDetect(preview.headers);
        _fileName = path.split('/').last;
        _result = null;
      });
    } catch (error) {
      if (mounted) showSnack(context, 'Could not read that file', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null) return;
    if (!_mapping.isValid) {
      showSnack(context, 'Map the date and amount columns first', error: true);
      return;
    }
    if (_defaultAccountId == null) {
      showSnack(context, 'Choose the account to import into', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref.read(importRepositoryProvider).import(
            preview: preview,
            mapping: _mapping,
            defaultType: _defaultType,
            defaultAccountId: _defaultAccountId!,
          );
      if (!mounted) return;
      setState(() => _result = result);
      showSnack(context, result.summary, error: result.failed > 0 && result.imported == 0);
    } catch (error) {
      if (mounted) showSnack(context, 'Import failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() => _busy = true);
    try {
      final dir = await Directory.systemTemp.createTemp('moneyman_template');
      final file = await ref.read(importRepositoryProvider).templateFile(dir);
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: 'MoneyMan CSV import template',
      );
    } catch (error) {
      if (mounted) showSnack(context, 'Could not create template: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    _defaultAccountId ??= accounts.isEmpty ? null : accounts.first.id;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('Import from CSV')),
      body: _preview == null
          ? EmptyState(
              title: 'Bring your history in',
              message:
                  'Pick a bank statement or spreadsheet export. moneyMan detects the columns and lets you map them before importing.',
              illustration: IllustrationKind.backup,
              actionLabel: _busy ? 'Reading…' : 'Choose a CSV file',
              onAction: _busy ? null : _pickFile,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.x2,
                AppSpacing.screen,
                AppSpacing.x10,
              ),
              children: <Widget>[
                AppCard(
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.insert_drive_file_outlined,
                          size: 20, color: palette.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(_fileName ?? 'file.csv',
                                style: context.bodyL),
                            Text(
                              '${_preview!.rowCount} rows · ${_preview!.headers.length} columns',
                              style: context.caption,
                            ),
                          ],
                        ),
                      ),
                      TextButton(onPressed: _busy ? null : _pickFile, child: const Text('Change')),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                const SettingsSectionTitle('Column mapping'),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.x4),
                  child: Column(
                    children: <Widget>[
                      _columnPicker('Date', _mapping.dateColumn,
                          (value) => setState(() => _mapping = _mapping.copyWith(dateColumn: value))),
                      const SizedBox(height: 10),
                      _columnPicker('Amount', _mapping.amountColumn,
                          (value) => setState(() => _mapping = _mapping.copyWith(amountColumn: value))),
                      const SizedBox(height: 10),
                      _columnPicker('Type', _mapping.typeColumn,
                          (value) => setState(() => _mapping = _mapping.copyWith(typeColumn: value))),
                      const SizedBox(height: 10),
                      _columnPicker('Category', _mapping.categoryColumn,
                          (value) => setState(() => _mapping = _mapping.copyWith(categoryColumn: value))),
                      const SizedBox(height: 10),
                      _columnPicker('Account', _mapping.accountColumn,
                          (value) => setState(() => _mapping = _mapping.copyWith(accountColumn: value))),
                      const SizedBox(height: 10),
                      _columnPicker('Note', _mapping.noteColumn,
                          (value) => setState(() => _mapping = _mapping.copyWith(noteColumn: value))),
                      const SizedBox(height: 10),
                      _columnPicker('Tags', _mapping.tagsColumn,
                          (value) => setState(() => _mapping = _mapping.copyWith(tagsColumn: value))),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                const SettingsSectionTitle('Defaults'),
                AppDropdown<String>(
                  label: 'Type when not in file',
                  items: const <String>[kTypeExpense, kTypeIncome],
                  value: _defaultType,
                  itemLabel: (value) => value == kTypeExpense ? 'Expense' : 'Income',
                  onChanged: (value) => setState(() => _defaultType = value),
                ),
                const SizedBox(height: AppSpacing.x3),
                AppDropdown<Account>(
                  label: 'Import into account',
                  items: accounts,
                  value: accounts
                      .cast<Account?>()
                      .firstWhere((a) => a?.id == _defaultAccountId, orElse: () => null),
                  itemLabel: (account) => account.name,
                  onChanged: (account) => setState(() => _defaultAccountId = account.id),
                ),
                const SizedBox(height: AppSpacing.x4),
                const SettingsSectionTitle('Preview'),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.x3),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 18,
                      headingRowHeight: 34,
                      dataRowMinHeight: 30,
                      dataRowMaxHeight: 38,
                      columns: _preview!.headers
                          .take(6)
                          .map((header) => DataColumn(
                                label: Text(header,
                                    style: AppTextStyles.caption(palette.tertiary)),
                              ))
                          .toList(),
                      rows: _preview!.rows
                          .take(5)
                          .map((row) => DataRow(
                                cells: row
                                    .take(6)
                                    .map((cell) => DataCell(Text(cell,
                                        style: AppTextStyles.caption(palette.ink))))
                                    .toList(),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                if (_result != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.x4),
                  AppCard(
                    color: _result!.imported > 0 ? palette.incomeBg : palette.expenseBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(_result!.summary, style: context.bodyL),
                        if (_result!.errors.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          ..._result!.errors
                              .take(5)
                              .map((error) => Text(error, style: context.caption)),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x5),
                PrimaryButton(
                  label: 'Import ${_preview!.rowCount} rows',
                  icon: Icons.download_rounded,
                  loading: _busy,
                  onPressed: _busy ? null : _import,
                ),
                const SizedBox(height: AppSpacing.x2),
                SecondaryButton(
                  label: 'Download CSV template',
                  icon: Icons.description_outlined,
                  onPressed: _busy ? null : _downloadTemplate,
                ),
                const SizedBox(height: AppSpacing.x4),
                Text(
                  'Duplicates are detected by date, amount and note. Rows that fail are skipped and listed above.',
                  style: context.caption,
                ),
              ],
            ),
    );
  }

  Widget _columnPicker(String label, int? value, ValueChanged<int?> onChanged) {
    final headers = _preview?.headers ?? const <String>[];
    return Row(
      children: <Widget>[
        SizedBox(
          width: 78,
          child: Text(label, style: AppTextStyles.label(context.c.sub)),
        ),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: value,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            hint: const Text('Not mapped'),
            items: <DropdownMenuItem<int>>[
              const DropdownMenuItem<int>(value: -1, child: Text('Not mapped')),
              ...List<DropdownMenuItem<int>>.generate(
                headers.length,
                (index) => DropdownMenuItem<int>(
                  value: index,
                  child: Text(headers[index], overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (index) => onChanged(index == null || index < 0 ? null : index),
          ),
        ),
      ],
    );
  }
}
