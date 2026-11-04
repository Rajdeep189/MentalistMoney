import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/illustration.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.kind,
    required this.bullets,
  });

  final String title;
  final String body;
  final IllustrationKind kind;
  final List<String> bullets;
}

const List<_OnboardingPage> _pages = <_OnboardingPage>[
  _OnboardingPage(
    title: 'Track every expense',
    body: 'Log expenses and income in seconds.',
    kind: IllustrationKind.onboardingTrack,
    bullets: <String>[
      'Add expenses, income and transfers',
      'Use the calculator while entering amounts',
      'Attach notes, tags and receipts',
    ],
  ),
  _OnboardingPage(
    title: 'All your accounts',
    body: 'Manage cash, bank, cards and wallets in one place.',
    kind: IllustrationKind.onboardingAccounts,
    bullets: <String>[
      'Create unlimited accounts',
      'Transfer money between accounts',
      'Always know your net worth',
    ],
  ),
  _OnboardingPage(
    title: 'Budgets and goals',
    body: 'Stay within budget and reach your goals faster.',
    kind: IllustrationKind.onboardingGoals,
    bullets: <String>[
      'Weekly, monthly and custom budgets',
      'Savings goals with progress rings',
      'Smart alerts before you overspend',
    ],
  ),
  _OnboardingPage(
    title: 'Private and customisable',
    body: 'Your data stays on your device. Always.',
    kind: IllustrationKind.onboardingPrivate,
    bullets: <String>[
      'Offline-first and private',
      'Biometric or PIN lock',
      'Themes, currencies and custom dashboard',
    ],
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
    await ref.read(settingsRepositoryProvider).setBool(SettingsKeys.onboardingDone, true);
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.x3,
                AppSpacing.x3,
                0,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'M',
                      style: AppTextStyles.money(16, color: Colors.white, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('MoneyMan', style: context.h3),
                  const Spacer(),
                  if (!isLast)
                    TextButton(
                      onPressed: _finish,
                      child: Text('Skip', style: AppTextStyles.label(palette.sub)),
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Spacer(flex: 2),
                        Center(child: OnboardingArt(kind: page.kind, size: 210)),
                        const Spacer(flex: 2),
                        Text(page.title, style: context.displayL),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          page.body,
                          style: AppTextStyles.bodyLarge(palette.sub).copyWith(height: 1.5),
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        ...page.bullets.map(
                          (bullet) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  height: 18,
                                  width: 18,
                                  decoration: BoxDecoration(
                                    color: palette.accentSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: palette.accent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: AppTextStyles.body(palette.sub),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 1),
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
                AppSpacing.x5,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(_pages.length, (index) {
                      final active = index == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        width: active ? 22 : 6,
                        decoration: BoxDecoration(
                          color: active ? palette.accent : palette.divider,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  PrimaryButton(
                    label: isLast ? 'Get started' : 'Next',
                    icon: isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    isLast
                        ? 'Next: choose your currency and first account'
                        : 'Takes less than a minute to set up',
                    style: AppTextStyles.caption(palette.tertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
