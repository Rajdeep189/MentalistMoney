import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/illustration.dart';
import '../../widgets/premium_badge.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/section_header.dart';

class PremiumPlan {
  const PremiumPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.cadence,
    this.badge,
    this.highlight = false,
  });

  final String id;
  final String name;
  final int price;
  final String cadence;
  final String? badge;
  final bool highlight;
}

const List<PremiumPlan> kPremiumPlans = <PremiumPlan>[
  PremiumPlan(
    id: 'monthly',
    name: 'Monthly',
    price: 14900,
    cadence: 'per month',
  ),
  PremiumPlan(
    id: 'yearly',
    name: 'Yearly',
    price: 99900,
    cadence: 'per year',
    badge: 'Save 44%',
    highlight: true,
  ),
  PremiumPlan(
    id: 'lifetime',
    name: 'Lifetime',
    price: 249900,
    cadence: 'one time',
    badge: 'Best value',
  ),
];

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String _selectedPlan = 'yearly';
  bool _busy = false;

  Future<void> _activate() async {
    final plan = kPremiumPlans.firstWhere((p) => p.id == _selectedPlan);
    final ok = await confirmAction(
      context,
      title: 'Unlock ${plan.name} Premium?',
      message:
          'MoneyMan is fully offline, so purchases are activated locally on this device. '
          'Everything unlocks immediately and permanently stays on your phone.',
      confirmLabel: 'Unlock Premium',
      destructive: false,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(settingsRepositoryProvider).setMany(<String, String>{
        SettingsKeys.premium: 'true',
        'premium_plan': plan.id,
        'premium_since': '${DateTime.now().millisecondsSinceEpoch}',
      });
      if (!mounted) return;
      showSnack(context, 'Premium unlocked — enjoy!');
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deactivate() async {
    final ok = await confirmAction(
      context,
      title: 'Turn off Premium?',
      message:
          'This device will return to the free plan. Your data stays untouched, but premium-only screens lock again.',
    );
    if (!ok) return;
    await ref.read(settingsRepositoryProvider).setBool(SettingsKeys.premium, false);
    if (mounted) showSnack(context, 'Premium deactivated');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final premium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Premium'),
        actions: <Widget>[
          if (premium)
            TextButton(
              onPressed: _deactivate,
              child: Text('Deactivate',
                  style: AppTextStyles.caption(palette.tertiary)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          const SizedBox(height: AppSpacing.x2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[palette.accent, palette.accentPressed],
              ),
              borderRadius: BorderRadius.circular(AppRadius.card + 4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const PremiumBadge(dense: true),
                    const Spacer(),
                    if (premium)
                      Row(
                        children: <Widget>[
                          const Icon(Icons.verified_rounded,
                              size: 15, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Active', style: AppTextStyles.caption(Colors.white)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  premium ? 'You have everything' : 'Own your money, completely',
                  style: AppTextStyles.h1(Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  premium
                      ? 'Unlimited budgets, goals, splits, advanced analytics and every theme.'
                      : 'Unlimited budgets and goals, advanced analytics, bill splitting and premium themes.',
                  style: AppTextStyles.body(Colors.white.withOpacity(0.82))
                      .copyWith(height: 1.45),
                ),
                const SizedBox(height: AppSpacing.x4),
                const AppIllustration(kind: IllustrationKind.premium, size: 96),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          SectionHeader(title: 'What you get', padding: EdgeInsets.zero),
          AppCard(
            child: Column(
              children: <Widget>[
                _featureRow(context, Icons.pie_chart_rounded, 'Unlimited budgets',
                    'Free plan stops at 3 active budgets.'),
                _featureRow(context, Icons.flag_rounded, 'Unlimited goals',
                    'Free plan stops at 2 active goals.'),
                _featureRow(context, Icons.groups_rounded, 'Unlimited split groups',
                    'Free plan includes a single group.'),
                _featureRow(context, Icons.insights_rounded, 'Advanced analytics',
                    'Forecasts, year-over-year and custom reports.'),
                _featureRow(context, Icons.emoji_events_rounded, 'All achievements',
                    'Trophy case plus milestone celebrations.'),
                _featureRow(context, Icons.palette_rounded, 'Premium themes',
                    'Midnight, Ocean and Forest packs.'),
                _featureRow(context, Icons.picture_as_pdf_rounded, 'Branded PDF reports',
                    'Violet accents and custom footers.'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          SectionHeader(title: 'Free vs Premium', padding: EdgeInsets.zero),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _matrixHeader(context),
                _matrixRow(context, 'Accounts', 'Unlimited', 'Unlimited'),
                _matrixRow(context, 'Transactions', 'Unlimited', 'Unlimited'),
                _matrixRow(context, 'Budgets', '3', 'Unlimited'),
                _matrixRow(context, 'Goals', '2', 'Unlimited'),
                _matrixRow(context, 'Split groups', '1', 'Unlimited'),
                _matrixRow(context, 'Charts', 'Core', 'All 14+'),
                _matrixRow(context, 'Custom reports', '—', 'Included'),
                _matrixRow(context, 'Achievements', 'Progress only', 'All'),
                _matrixRow(context, 'Theme packs', 'Default, Mono', 'All'),
                _matrixRow(context, 'CSV & PDF', 'Yes', 'Yes + branding'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          if (!premium) ...<Widget>[
            SectionHeader(title: 'Choose a plan', padding: EdgeInsets.zero),
            ...kPremiumPlans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                child: _PlanTile(
                  plan: plan,
                  selected: _selectedPlan == plan.id,
                  onTap: () => setState(() => _selectedPlan = plan.id),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            PrimaryButton(
              label: 'Unlock Premium',
              icon: Icons.lock_open_rounded,
              loading: _busy,
              onPressed: _busy ? null : _activate,
            ),
            const SizedBox(height: AppSpacing.x3),
            Text(
              'No account needed. Purchases are tied to this device only — '
              'restore by keeping your JSON backup safe.',
              style: context.caption,
              textAlign: TextAlign.center,
            ),
          ] else ...<Widget>[
            AppCard(
              child: Row(
                children: <Widget>[
                  CategoryIcon(
                    icon: Icons.verified_rounded,
                    color: palette.income,
                    size: 40,
                    rounded: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Premium is active', style: context.bodyL),
                        Text('Thank you for supporting the app',
                            style: context.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x5),
          Center(
            child: Text(
              'Prices are shown for reference. This build unlocks features locally '
              'without charging you.',
              style: AppTextStyles.caption(palette.tertiary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(BuildContext context, IconData icon, String title, String body) {
    final palette = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CategoryIcon(icon: icon, color: palette.accent, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyles.label(palette.ink)),
                Text(body, style: context.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _matrixHeader(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 10),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.cardAlt : palette.surfaceAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text('Feature', style: context.overline)),
          SizedBox(
            width: 68,
            child: Text('Free', style: context.overline, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 84,
            child: Text('Premium',
                style: AppTextStyles.overline(palette.accent),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _matrixRow(BuildContext context, String feature, String free, String premium) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(feature, style: AppTextStyles.body(palette.ink))),
          SizedBox(
            width: 68,
            child: Text(free,
                style: AppTextStyles.caption(palette.tertiary),
                textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 84,
            child: Text(premium,
                style: AppTextStyles.caption(palette.accent),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.selected, required this.onTap});

  final PremiumPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSpacing.x4),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? palette.accent : palette.divider,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? palette.accent : palette.divider,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(plan.name, style: AppTextStyles.label(palette.ink)),
                      if (plan.badge != null) ...<Widget>[
                        const SizedBox(width: 8),
                        TintChip(label: plan.badge!, dense: true),
                      ],
                    ],
                  ),
                  Text(plan.cadence, style: context.caption),
                ],
              ),
            ),
            Text(
              '₹${(plan.price / 100).toStringAsFixed(0)}',
              style: AppTextStyles.money(16, color: palette.ink, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
