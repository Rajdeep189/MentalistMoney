import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/app_provider.dart';

/// Step 2 — Transaction engine (income / expense / transfer) with
/// circular category icons, tags, account picker and a Bill Splitter toggle.
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TxnType _type = TxnType.expense;
  String _category = Categories.expense.first.key;
  int _accountId = 1;
  final Set<String> _tags = {};
  bool _split = false;
  final Set<String> _people = {};
  String? _error;

  static const _tagOptions = ['Work', 'Personal', 'Fun', 'Urgent'];
  static const _contacts = ['Aarav', 'Priya', 'Rahul', 'Sara'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save(AppProvider p) {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero');
      return;
    }
    final t = Transaction(
      amount: amount,
      type: _type,
      category: _category,
      note: _noteCtrl.text.trim(),
      accountId: _accountId,
      tags: _tags.toList(),
      splitWith: _split ? _people.toList() : const [],
      date: DateTime.now(),
    );
    p.addTransaction(t);
    Navigator.of(context).pop();
    final label = _type.name[0].toUpperCase() + _type.name.substring(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label of ${formatMoneyShort(amount)} added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final cats = _type == TxnType.income ? Categories.income : Categories.expense;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final perPerson = (_split && _people.isNotEmpty && amount > 0) ? amount / _people.length : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.ink.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('New transaction', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // type segmented control
              Row(
                children: [
                  _seg(TxnType.expense, 'Expense', Icons.arrow_downward_rounded, AppColors.red),
                  _seg(TxnType.income, 'Income', Icons.arrow_upward_rounded, AppColors.green),
                  _seg(TxnType.transfer, 'Transfer', Icons.swap_horiz_rounded, AppColors.blue),
                ],
              ),
              const SizedBox(height: 20),
              // amount
              Center(
                child: SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.inkSoft),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              if (_error != null)
                Center(
                  child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(height: 18),
              _label('CATEGORY'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.92,
                ),
                itemCount: cats.length,
                itemBuilder: (ctx, i) {
                  final c = cats[i];
                  final sel = _category == c.key;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c.key),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: sel ? LinearGradient(colors: [c.color, c.color2]) : null,
                            color: sel ? null : c.color.withOpacity(0.12),
                            border: sel ? Border.all(color: c.color, width: 2.5) : null,
                            boxShadow: sel ? [BoxShadow(color: c.color.withOpacity(0.4), blurRadius: 10)] : null,
                          ),
                          child: Icon(c.icon, color: sel ? Colors.white : c.color, size: 24),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          c.label.split(' ').first,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                            color: sel ? AppColors.ink : AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _label('ACCOUNT'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: p.accounts.map((a) {
                  final sel = _accountId == a.id;
                  return GestureDetector(
                    onTap: () => setState(() => _accountId = a.id ?? 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.ink : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel ? AppColors.ink : AppColors.line),
                      ),
                      child: Text(
                        a.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              _label('NOTE'),
              const SizedBox(height: 10),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(hintText: 'Add a note…'),
                maxLines: 1,
              ),
              const SizedBox(height: 18),
              _label('TAGS'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _tagOptions.map((t) {
                  final sel = _tags.contains(t);
                  return GestureDetector(
                    onTap: () => setState(() => sel ? _tags.remove(t) : _tags.add(t)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.orange.withOpacity(0.15) : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? AppColors.orange : AppColors.line),
                      ),
                      child: Text(
                        t.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: sel ? AppColors.orange : AppColors.inkSoft,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // Bill splitter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded, color: AppColors.inkSoft, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Split this bill', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    Switch(value: _split, onChanged: (v) => setState(() => _split = v)),
                  ],
                ),
              ),
              if (_split) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _contacts.map((c) {
                    final sel = _people.contains(c);
                    return GestureDetector(
                      onTap: () => setState(() => sel ? _people.remove(c) : _people.add(c)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.neon : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? AppColors.neonInk : AppColors.line),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel ? AppColors.neonInk : AppColors.ink,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (perPerson > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${formatMoney(perPerson, digits: 0)} per person (${_people.length})',
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _save(p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neon,
                    foregroundColor: AppColors.neonInk,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 6,
                    shadowColor: AppColors.neon.withOpacity(0.5),
                  ),
                  child: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seg(TxnType t, String label, IconData icon, Color c) {
    final active = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = t;
          _category = (t == TxnType.income ? Categories.income : Categories.expense).first.key;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? c : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 12)]
                : [
                    BoxShadow(color: AppColors.neoShadowDark.withOpacity(0.35), offset: const Offset(3, 3), blurRadius: 6),
                    BoxShadow(color: Colors.white.withOpacity(0.9), offset: const Offset(-3, -3), blurRadius: 6),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : AppColors.inkSoft),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.inkSoft),
    );
  }
}
