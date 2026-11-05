import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../widgets/paisa.dart';

class _Page {
  const _Page({
    required this.title,
    required this.body,
    required this.art,
  });

  final String title;
  final String body;
  final _Art art;
}

enum _Art {
  overview,
  expenses,
  budgets,
  loans,
  goals,
  recurring,
  categories,
  accounts,
  reports,
  splits,
  languages,
  notifications,
  privacy,
}

const List<_Page> _pages = <_Page>[
  _Page(
    title: 'Everything at a glance',
    body:
        'Accounts, budgets, goals and reports in one calm overview built for your money.',
    art: _Art.overview,
  ),
  _Page(
    title: 'Track every expense in seconds',
    body:
        'Log spending, income and transfers with a calculator, notes, tags and receipts.',
    art: _Art.expenses,
  ),
  _Page(
    title: 'Budgets that keep you honest',
    body:
        'Set a limit per category or across everything and watch the wavy progress fill up.',
    art: _Art.budgets,
  ),
  _Page(
    title: 'Lending and borrowing, sorted',
    body:
        'Track money you have lent or owe, with a running net balance you can trust.',
    art: _Art.loans,
  ),
  _Page(
    title: 'Goals worth saving for',
    body:
        'From a rainy-day fund to your next trip — see daily pace, saved and remaining.',
    art: _Art.goals,
  ),
  _Page(
    title: 'Recurring made simple',
    body:
        'Rent, subscriptions and salary post themselves on time, on a calendar you can read.',
    art: _Art.recurring,
  ),
  _Page(
    title: 'Organise with categories',
    body:
        'Expense, income and transfer categories with emoji-tinted icons and counts.',
    art: _Art.categories,
  ),
  _Page(
    title: 'All accounts, one place',
    body:
        'Cash, bank, cards, wallets and investments roll up into a single net worth.',
    art: _Art.accounts,
  ),
  _Page(
    title: 'See exactly where it goes',
    body:
        'Weekly bars, 30-day trends and category rankings — no spreadsheet needed.',
    art: _Art.reports,
  ),
  _Page(
    title: 'Split bills without the maths',
    body:
        'Share a bill with friends, record who paid and settle up in a tap.',
    art: _Art.splits,
  ),
  _Page(
    title: 'Speak your language',
    body:
        'Paisa is built for India first — English and हिन्दी today, 35+ languages rolling out.',
    art: _Art.languages,
  ),
  _Page(
    title: 'Never miss a payment',
    body:
        'Gentle reminders for bills, budgets and recurring payments — only when it matters.',
    art: _Art.notifications,
  ),
  _Page(
    title: 'Your data, your rules',
    body:
        'Offline-first and private. Lock the app, export a backup and restore it any time.',
    art: _Art.privacy,
  ),
  _Page(
    title: 'Set up Paisa',
    body: 'Choose how you would like to start. You can change this later.',
    art: _Art.overview,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref
        .read(settingsRepositoryProvider)
        .setBool(SettingsKeys.onboardingDone, true);
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 10, AppSpacing.screen, 0),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: _openLanguages,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: palette.isDark ? palette.cardAlt : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'EN',
                            style: AppTextStyles.base(
                              size: 12,
                              weight: FontWeight.w700,
                              height: 1.1,
                            ).copyWith(color: palette.ink),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 15, color: palette.sub),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isLast)
                    GestureDetector(
                      onTap: _finish,
                      child: Text(
                        'Skip',
                        style: AppTextStyles.base(
                          size: 13,
                          weight: FontWeight.w600,
                          height: 1.1,
                        ).copyWith(color: palette.sub),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final last = index == _pages.length - 1;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      18,
                      AppSpacing.screen,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: last
                              ? _FinalArt(
                                  onFresh: _finish,
                                  onDemo: () async {
                                    await _finish();
                                  },
                                  onRestore: () => _snack(
                                      'Open Settings → Data to restore a backup.'),
                                  onDrive: () => _snack(
                                      'Google Drive backup is part of Premium.'),
                                )
                              : _PhonePreview(art: page.art),
                        ),
                        const SizedBox(height: 26),
                        Text(page.title,
                            style: AppTextStyles.serif(size: 25, color: palette.ink)),
                        const SizedBox(height: 8),
                        Text(
                          page.body,
                          style: AppTextStyles.body(palette.sub)
                              .copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 14),
                        if (last) ...<Widget>[
                          Text(
                            '14 days of Paisa Plus are included with every new account.',
                            style: AppTextStyles.caption(palette.tertiary),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                14,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.only(right: 4),
                          height: 4,
                          width: i == _index ? 22 : 9,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? palette.accent
                                : palette.divider,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${_index + 1}/${_pages.length}',
                        style: AppTextStyles.base(
                          size: 12,
                          weight: FontWeight.w600,
                          height: 1.1,
                        ).copyWith(color: palette.tertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PeachButton(
                    label: isLast
                        ? 'Start fresh'
                        : _index == 0
                            ? 'Get started'
                            : 'Next',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLanguages() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: sheetContext.c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  height: 4,
                  width: 44,
                  decoration: BoxDecoration(
                    color: sheetContext.c.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Language',
                  style: AppTextStyles.serif(
                      size: 21, color: sheetContext.c.ink)),
              const SizedBox(height: 4),
              Text(
                'English and हिन्दी are fully translated. More languages are on the way.',
                style: AppTextStyles.caption(sheetContext.c.sub),
              ),
              const SizedBox(height: 16),
              for (final language in const <String>[
                'English',
                'हिन्दी',
                'தமிழ்',
                'తెలుగు',
                'ಕನ್ನಡ',
                'मराठी',
                'ગુજરાતી',
                'বাংলা',
                'Español',
                'Français',
                'Deutsch',
                'العربية',
              ])
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    language,
                    style: AppTextStyles.base(
                      size: 14,
                      weight: FontWeight.w600,
                      height: 1.2,
                    ).copyWith(color: sheetContext.c.ink),
                  ),
                  trailing: language == 'English'
                      ? Icon(Icons.check_circle_rounded,
                          color: sheetContext.c.accent, size: 20)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Framed phone mockup rendered with real widgets at reduced scale.
class _PhonePreview extends StatelessWidget {
  const _PhonePreview({required this.art});

  final _Art art;

  @override
  Widget build(BuildContext context) {
    return PhoneMock(
      height: 452,
      width: 244,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('9:41',
                    style: AppTextStyles.base(
                      size: 8,
                      weight: FontWeight.w700,
                      height: 1,
                    ).copyWith(color: const Color(0xFF6B534A))),
                const Spacer(),
                const Icon(Icons.wifi_rounded, size: 8, color: Color(0xFF6B534A)),
                const SizedBox(width: 4),
                const Icon(Icons.battery_5_bar_rounded,
                    size: 8, color: Color(0xFF6B534A)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _artBody(art),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E2D8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Icon(Icons.home_rounded,
                      size: 13, color: AppColors.espresso),
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 13, color: const Color(0xFFB4A096)),
                  Icon(Icons.pie_chart_outline_rounded,
                      size: 13, color: const Color(0xFFB4A096)),
                  Icon(Icons.search_rounded,
                      size: 13, color: const Color(0xFFB4A096)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artBody(_Art art) {
    const ink = Color(0xFF2A1B16);
    const sub = Color(0xFF8A7266);
    switch (art) {
      case _Art.overview:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Good morning',
                style: TextStyle(
                    fontSize: 8, color: sub, fontFamily: AppTextStyles.family)),
            const SizedBox(height: 2),
            const Text('Aarav',
                style: TextStyle(
                    fontSize: 13,
                    color: ink,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTextStyles.family)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFFFD9C6), Color(0xFFFFC1A5)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Total balance',
                      style: TextStyle(
                          fontSize: 7,
                          color: Color(0xFF8A5540),
                          fontFamily: AppTextStyles.family)),
                  const SizedBox(height: 2),
                  Text(Fmt.money(6614329, forceCompact: true),
                      style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFF3A1B0E),
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTextStyles.family)),
                  const SizedBox(height: 6),
                  Row(
                    children: const <Widget>[
                      Text('Income  +12%',
                          style: TextStyle(
                              fontSize: 7,
                              color: Color(0xFF146B45),
                              fontFamily: AppTextStyles.family)),
                      SizedBox(width: 10),
                      Text('Expense  -4%',
                          style: TextStyle(
                              fontSize: 7,
                              color: Color(0xFFA52A22),
                              fontFamily: AppTextStyles.family)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(child: _miniTile('Accounts', '4 accounts')),
                const SizedBox(width: 6),
                Expanded(child: _miniTile('Budgets', '3 budgets')),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(child: _miniTile('Goals', '2 active')),
                const SizedBox(width: 6),
                Expanded(child: _miniTile('Reports', '13 txns')),
              ],
            ),
          ],
        );
      case _Art.expenses:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Add expense',
                style: TextStyle(
                    fontSize: 12, color: ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: AppColors.blush,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.local_cafe_rounded,
                        size: 12, color: AppColors.blushDeep),
                  ),
                  const SizedBox(width: 6),
                  const Text('Coffee',
                      style: TextStyle(fontSize: 8, color: ink)),
                  const Spacer(),
                  const Text('₹450',
                      style: TextStyle(
                          fontSize: 8,
                          color: ink,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.shopping_basket_rounded,
                        size: 12, color: AppColors.mintDeep),
                  ),
                  const SizedBox(width: 6),
                  const Text('Groceries',
                      style: TextStyle(fontSize: 8, color: ink)),
                  const Spacer(),
                  const Text('₹1,240',
                      style: TextStyle(
                          fontSize: 8,
                          color: ink,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('Add another',
                  style: TextStyle(
                      fontSize: 7.5,
                      color: AppColors.espresso,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        );
      case _Art.budgets:
        return Column(
          children: <Widget>[
            _miniPastel(
              AppColors.blush,
              'Groceries',
              AppColors.blushDeep,
              0.62,
              '₹4,300 / ₹7,000',
            ),
            const SizedBox(height: 8),
            _miniPastel(
              AppColors.mint,
              'Transport',
              AppColors.mintDeep,
              0.34,
              '₹1,200 / ₹3,500',
            ),
            const SizedBox(height: 8),
            _miniPastel(
              AppColors.periwinkle,
              'Dining',
              AppColors.periwinkleDeep,
              0.86,
              '₹6,000 / ₹7,000',
            ),
          ],
        );
      case _Art.loans:
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    child: _miniStat(AppColors.mint, 'Lent', '₹12,000',
                        AppColors.mintDeep)),
                const SizedBox(width: 6),
                Expanded(
                    child: _miniStat(AppColors.blush, 'Borrowed',
                        '₹4,500', AppColors.blushDeep)),
              ],
            ),
            const SizedBox(height: 8),
            _miniPastel(AppColors.butter, 'Rohan', AppColors.butterDeep, 0.4,
                '₹6,000 of ₹15,000'),
            const SizedBox(height: 8),
            _miniPastel(AppColors.lilac, 'Priya', AppColors.lilacDeep, 0.7,
                '₹3,500 of ₹5,000'),
          ],
        );
      case _Art.goals:
        return Column(
          children: <Widget>[
            _miniPastel(AppColors.lilac, 'Japan trip', AppColors.lilacDeep, 0.72,
                '₹1,80,000 saved'),
            const SizedBox(height: 8),
            _miniPastel(AppColors.tan, 'Emergency fund',
                AppColors.tanDeep, 0.35, '₹70,000 saved'),
          ],
        );
      case _Art.recurring:
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    child: _miniStat(AppColors.butter, 'Due', '₹12k',
                        AppColors.butterDeep)),
                const SizedBox(width: 6),
                Expanded(
                    child: _miniStat(AppColors.mint, 'Monthly', '₹18k',
                        AppColors.mintDeep)),
              ],
            ),
            const SizedBox(height: 8),
            _miniPastel(AppColors.blush, 'Netflix', AppColors.blushDeep, 0.5,
                'Monthly · next 12 Nov'),
            const SizedBox(height: 8),
            _miniPastel(AppColors.mint, 'Salary', AppColors.mintDeep, 1,
                'Monthly · next 1 Nov'),
          ],
        );
      case _Art.categories:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2EC),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: const <Widget>[
                  _MiniPill('Expense', true),
                  _MiniPill('Income', false),
                  _MiniPill('Transfer', false),
                ],
              ),
            ),
            const SizedBox(height: 10),
            for (final row in const <List<String>>[
              <String>['🍜', 'Food & Dining', '42'],
              <String>['🚌', 'Transport', '18'],
              <String>['🏠', 'Rent', '6'],
              <String>['🎬', 'Entertainment', '9'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 22,
                      width: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2EC),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(row[0],
                          style: const TextStyle(fontSize: 10)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(row[1],
                          style: const TextStyle(fontSize: 8, color: ink)),
                    ),
                    Text(row[2],
                        style: const TextStyle(fontSize: 8, color: sub)),
                  ],
                ),
              ),
          ],
        );
      case _Art.accounts:
        return Column(
          children: <Widget>[
            _miniPastel(AppColors.mint, 'HDFC Savings', AppColors.mintDeep, 0.8,
                '₹82,450'),
            const SizedBox(height: 8),
            _miniPastel(AppColors.periwinkle, 'HDFC Credit', AppColors.periwinkleDeep,
                0.4, '₹17,220 due'),
            const SizedBox(height: 8),
            _miniPastel(AppColors.butter, 'Cash', AppColors.butterDeep, 0.3,
                '₹3,100'),
          ],
        );
      case _Art.reports:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Last 30 days',
                style: TextStyle(
                    fontSize: 11, color: ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (final height in const <double>[10, 24, 18, 38, 30, 52, 44])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _miniPastel(AppColors.blush, 'Food & Dining', AppColors.blushDeep,
                0.55, '₹9,400 · 42 txns'),
          ],
        );
      case _Art.splits:
        return Column(
          children: <Widget>[
            _miniPastel(AppColors.butter, 'Dinner', AppColors.butterDeep, 0.6,
                '₹2,400 · 3 people'),
            const SizedBox(height: 8),
            _miniPastel(AppColors.mint, 'Cab', AppColors.mintDeep, 0.33,
                '₹600 · 2 people'),
            const SizedBox(height: 8),
            _miniPastel(AppColors.periwinkle, 'Stay', AppColors.periwinkleDeep,
                0.75, '₹8,000 · 4 people'),
          ],
        );
      case _Art.languages:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Choose language',
                style: TextStyle(
                    fontSize: 11, color: ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final language in const <String>[
                  'English', 'हिन्दी', 'தமிழ்', 'తెలుగు', 'ಕನ್ನಡ', 'मराठी',
                ])
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: language == 'English'
                          ? AppColors.accent
                          : const Color(0xFFFDF2EC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(language,
                        style: TextStyle(
                            fontSize: 7.5,
                            color: language == 'English'
                                ? AppColors.espresso
                                : ink,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
        );
      case _Art.notifications:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Reminders',
                style: TextStyle(
                    fontSize: 11, color: ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _miniNotification('Rent is due tomorrow', '₹18,000 · HDFC'),
            const SizedBox(height: 6),
            _miniNotification('Groceries budget at 86%', '₹6,000 of ₹7,000'),
            const SizedBox(height: 8),
            Container(
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('Enable notifications',
                  style: TextStyle(
                      fontSize: 7.5,
                      color: AppColors.espresso,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        );
      case _Art.privacy:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const <Widget>[
                  Icon(Icons.lock_outline_rounded,
                      size: 18, color: AppColors.espresso),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('On-device by default',
                        style: TextStyle(fontSize: 8, color: ink)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _miniNotification('App lock', 'PIN or biometrics'),
            const SizedBox(height: 6),
            _miniNotification('Export backup', 'CSV, JSON or SQLite'),
          ],
        );
    }
  }

  Widget _miniTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2EC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: const TextStyle(
                  fontSize: 6.5, color: Color(0xFF8A7266))),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 7.5,
                  color: Color(0xFF2A1B16),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _miniPastel(Color tint, String title, Color ink, double progress,
      String subtitle) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: TextStyle(
                  fontSize: 8.5, color: ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: <Widget>[
                Container(height: 4, color: Colors.white.withOpacity(0.6)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(height: 4, color: ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(fontSize: 6.5, color: ink)),
        ],
      ),
    );
  }

  Widget _miniStat(Color tint, String label, String value, Color ink) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 6.5, color: ink)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 10, color: ink, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _miniNotification(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 20,
            width: 20,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 11, color: AppColors.espresso),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: const TextStyle(
                        fontSize: 7.5,
                        color: Color(0xFF2A1B16),
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 6.5, color: Color(0xFF8A7266))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill(this.label, this.active);

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 7,
          color: active ? AppColors.espresso : const Color(0xFF8A7266),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Final page: backup, restore, demo and fresh start options.
class _FinalArt extends StatelessWidget {
  const _FinalArt({
    required this.onFresh,
    required this.onDemo,
    required this.onRestore,
    required this.onDrive,
  });

  final VoidCallback onFresh;
  final VoidCallback onDemo;
  final VoidCallback onRestore;
  final VoidCallback onDrive;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      children: <Widget>[
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: palette.accent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.savings_rounded,
              size: 28, color: AppColors.espresso),
        ),
        const SizedBox(height: 18),
        _OptionRow(
          icon: Icons.cloud_upload_outlined,
          title: 'Google Drive Backup',
          subtitle: 'Encrypted, end-to-end',
          trailing: const Icon(Icons.lock_outline_rounded,
              size: 15, color: AppColors.accent),
          onTap: onDrive,
        ),
        const SizedBox(height: 10),
        _OptionRow(
          icon: Icons.restore_rounded,
          title: 'Restore Local Backup',
          subtitle: 'From a file on this device',
          onTap: onRestore,
        ),
        const SizedBox(height: 10),
        _OptionRow(
          icon: Icons.play_circle_outline_rounded,
          title: 'Try Demo Mode',
          subtitle: 'Explore with sample data',
          onTap: onDemo,
        ),
        const SizedBox(height: 10),
        _OptionRow(
          icon: Icons.auto_awesome_rounded,
          title: 'Start fresh',
          subtitle: 'Begin with your own numbers',
          onTap: onFresh,
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.divider.withOpacity(0.7)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: palette.isDark ? palette.cardAlt : palette.surfaceAlt,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 19, color: palette.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.base(
                      size: 14,
                      weight: FontWeight.w600,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption(palette.tertiary)
                          .copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: palette.tertiary),
          ],
        ),
      ),
    );
  }
}
