import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/money.dart';
import '../data/models/models.dart';
import 'luxe.dart';

/// A preloaded card finish. `hex` is what gets saved on `Account.color`, so the
/// finish survives restarts, backups and restores.
class LuxeCardStyle {
  const LuxeCardStyle({
    required this.hex,
    required this.name,
    required this.colors,
    required this.ink,
    this.light = false,
    this.pattern = _CardPattern.metal,
  });

  final String hex;
  final String name;
  final List<Color> colors;
  final Color ink;
  final bool light;
  final _CardPattern pattern;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );

  Color get muted => ink.withOpacity(light ? 0.55 : 0.62);

  static const LuxeCardStyle obsidian = LuxeCardStyle(
    hex: '#141418',
    name: 'Obsidian',
    colors: <Color>[Color(0xFF2C2D34), Color(0xFF16161A), Color(0xFF08080A)],
    ink: Color(0xFFF4F2ED),
  );

  static const LuxeCardStyle champagne = LuxeCardStyle(
    hex: '#C9A96A',
    name: 'Champagne',
    colors: <Color>[Color(0xFFF6E3B8), Color(0xFFC9A96A), Color(0xFF8A6E3D)],
    ink: Color(0xFF1A1408),
    light: true,
    pattern: _CardPattern.orbit,
  );

  static const LuxeCardStyle lime = LuxeCardStyle(
    hex: '#C9F24C',
    name: 'Lime Pulse',
    colors: <Color>[Color(0xFFE6FF9A), Color(0xFFC9F24C), Color(0xFF86C625)],
    ink: Color(0xFF10220A),
    light: true,
    pattern: _CardPattern.waves,
  );

  static const LuxeCardStyle azurite = LuxeCardStyle(
    hex: '#2E5BFF',
    name: 'Azurite',
    colors: <Color>[Color(0xFF5C8CFF), Color(0xFF2E5BFF), Color(0xFF10205C)],
    ink: Color(0xFFFFFFFF),
    pattern: _CardPattern.grid,
  );

  static const LuxeCardStyle aurora = LuxeCardStyle(
    hex: '#8B5CF6',
    name: 'Aurora',
    colors: <Color>[Color(0xFFB79CFF), Color(0xFF8B5CF6), Color(0xFF3B1E75)],
    ink: Color(0xFFFFFFFF),
    pattern: _CardPattern.orbit,
  );

  static const LuxeCardStyle sunset = LuxeCardStyle(
    hex: '#FF6A3D',
    name: 'Sunset',
    colors: <Color>[Color(0xFFFFC7A3), Color(0xFFFF6A3D), Color(0xFFB32718)],
    ink: Color(0xFFFFFFFF),
    pattern: _CardPattern.waves,
  );

  static const LuxeCardStyle bone = LuxeCardStyle(
    hex: '#F4F2ED',
    name: 'Bone Metal',
    colors: <Color>[Color(0xFFFFFFFF), Color(0xFFEDEAE2), Color(0xFFCFCABE)],
    ink: Color(0xFF0C0C0E),
    light: true,
    pattern: _CardPattern.metal,
  );

  static const LuxeCardStyle copper = LuxeCardStyle(
    hex: '#B87333',
    name: 'Copper',
    colors: <Color>[Color(0xFFE9B58A), Color(0xFFB87333), Color(0xFF6B3A12)],
    ink: Color(0xFFFFF7EF),
    pattern: _CardPattern.grid,
  );

  static const List<LuxeCardStyle> presets = <LuxeCardStyle>[
    obsidian,
    champagne,
    lime,
    azurite,
    aurora,
    sunset,
    copper,
    bone,
  ];

  static LuxeCardStyle forAccount(Account account) {
    final hex = account.color.toUpperCase();
    for (final style in presets) {
      if (style.hex.toUpperCase() == hex) return style;
    }
    switch (account.type) {
      case kAccountCash:
        return lime;
      case kAccountBank:
        return obsidian;
      case kAccountCredit:
        return azurite;
      case kAccountInvestment:
        return aurora;
      default:
        return champagne;
    }
  }

  static LuxeCardStyle byHex(String hex) {
    for (final style in presets) {
      if (style.hex.toUpperCase() == hex.toUpperCase()) return style;
    }
    return obsidian;
  }
}

enum _CardPattern { metal, orbit, waves, grid }

/// A bank-grade payment card for an account. Cash accounts render as a
/// currency card, bank accounts as a debit card, credit accounts with an
/// expiry + network badge.
class LuxeAccountCard extends StatefulWidget {
  const LuxeAccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.holder,
    this.style,
    this.compact = false,
    this.showBalance = true,
    this.animate = true,
  });

  final Account account;
  final VoidCallback? onTap;

  /// Live holder name (e.g. bound to the name field in the form).
  final String? holder;
  final LuxeCardStyle? style;
  final bool compact;
  final bool showBalance;
  final bool animate;

  @override
  State<LuxeAccountCard> createState() => _LuxeAccountCardState();
}

class _LuxeAccountCardState extends State<LuxeAccountCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _entrance.forward();
    } else {
      _entrance.value = 1;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  String get _masked {
    final seed = (widget.account.id ?? widget.account.name.hashCode).abs();
    final last4 = (seed % 9000 + 1000).toString();
    return '••••  ••••  ••••  $last4';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final style = widget.style ?? LuxeCardStyle.forAccount(widget.account);
    final account = widget.account;
    final isCash = account.type == kAccountCash;
    final isCredit = account.type == kAccountCredit;
    final isBank = account.type == kAccountBank;
    final holder = (widget.holder ?? account.name).trim();
    final holderLabel =
        holder.isEmpty ? 'YOUR NAME' : holder.toUpperCase();
    final height = widget.compact ? 148.0 : 212.0;

    final card = AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_entrance.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - t)),
            child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 140),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: style.gradient,
              borderRadius: BorderRadius.circular(AppRadius.cardLarge + 2),
              border: Border.all(
                color: style.light
                    ? Colors.white.withOpacity(0.85)
                    : Colors.white.withOpacity(0.16),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: style.colors.last.withOpacity(0.45),
                  blurRadius: 26,
                  spreadRadius: -8,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(palette.isDark ? 0.5 : 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.cardLarge + 2),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CardPatternPainter(
                        style: style,
                        pattern: style.pattern,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ShineSweep(
                      period: const Duration(milliseconds: 4600),
                      opacity: style.light ? 0.7 : 0.35,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(widget.compact ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _Chip(
                              text: isCash
                                  ? 'CASH'
                                  : isBank
                                      ? 'DEBIT'
                                      : isCredit
                                          ? 'CREDIT'
                                          : accountTypeLabel(account.type)
                                              .toUpperCase(),
                              style: style,
                            ),
                            const Spacer(),
                            if (!isCash)
                              Icon(
                                Icons.contactless_rounded,
                                size: 22,
                                color: style.muted,
                              ),
                            const SizedBox(width: 8),
                            _StarBadge(style: style),
                          ],
                        ),
                        const Spacer(),
                        if (widget.showBalance) ...<Widget>[
                          Text(
                            isCredit ? 'Outstanding' : 'Balance',
                            style: AppTextStyles.caption(style.muted)
                                .copyWith(fontSize: 10, letterSpacing: 0.6),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              Fmt.money(account.balance),
                              style: AppTextStyles.serif(
                                size: widget.compact ? 24 : 29,
                                color: style.ink,
                                tabularFigures: true,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: widget.compact ? 10 : 14),
                        Text(
                          isCash
                              ? '₹  ₹  ₹  ₹  ₹  ₹'
                              : _masked,
                          style: AppTextStyles.label(style.muted).copyWith(
                            fontSize: widget.compact ? 11 : 12.5,
                            letterSpacing: isCash ? 3 : 2.4,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    isCredit ? 'CARD HOLDER' : 'ACCOUNT NAME',
                                    style: AppTextStyles.caption(style.muted)
                                        .copyWith(
                                      fontSize: 8,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    holderLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.serif(
                                      size: widget.compact ? 12 : 14,
                                      color: style.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCredit)
                              Text(
                                '09/29',
                                style: AppTextStyles.label(style.muted)
                                    .copyWith(fontSize: 11),
                              )
                            else
                              Text(
                                isCash ? 'WALLET' : 'INDIA',
                                style: AppTextStyles.caption(style.muted)
                                    .copyWith(
                                  fontSize: 9,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              'MoneyMan',
                              style: AppTextStyles.serif(
                                size: widget.compact ? 11 : 12.5,
                                color: style.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: card,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.style});

  final String text;
  final LuxeCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: style.ink.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: style.ink.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: AppTextStyles.overline(style.ink)
            .copyWith(fontSize: 8.5, letterSpacing: 1.2),
      ),
    );
  }
}

class _StarBadge extends StatelessWidget {
  const _StarBadge({required this.style});

  final LuxeCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      width: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.ink.withOpacity(0.10),
        border: Border.all(color: style.ink.withOpacity(0.22)),
      ),
      child: Icon(Icons.star_rounded, size: 14, color: style.ink),
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  _CardPatternPainter({required this.style, required this.pattern});

  final LuxeCardStyle style;
  final _CardPattern pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = style.ink.withOpacity(0.10);

    switch (pattern) {
      case _CardPattern.metal:
        final g = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              style.ink.withOpacity(0.10),
              Colors.transparent,
              style.ink.withOpacity(0.06),
            ],
            stops: const <double>[0, 0.45, 1],
          ).createShader(Offset.zero & size);
        canvas.drawRect(Offset.zero & size, g);
        for (var i = -2; i < 8; i++) {
          final y = size.height * i / 5;
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y + size.height * 0.25),
            Paint()
              ..strokeWidth = 0.6
              ..color = style.ink.withOpacity(0.05),
          );
        }
        break;
      case _CardPattern.orbit:
        final center = Offset(size.width * 0.92, size.height * 0.12);
        for (var i = 1; i <= 4; i++) {
          canvas.drawCircle(center, size.width * 0.16 * i, line);
        }
        canvas.drawCircle(
          Offset(size.width * 0.08, size.height * 0.95),
          size.width * 0.34,
          Paint()..color = style.ink.withOpacity(0.05),
        );
        break;
      case _CardPattern.waves:
        for (var i = 0; i < 4; i++) {
          final path = Path();
          final baseY = size.height * (0.55 + i * 0.16);
          path.moveTo(-10, baseY);
          for (var x = 0.0; x < size.width + 20; x += 12) {
            path.quadraticBezierTo(
              x + 6,
              baseY + (i.isEven ? -9 : 9),
              x + 12,
              baseY,
            );
          }
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = style.ink.withOpacity(0.10),
          );
        }
        break;
      case _CardPattern.grid:
        for (var x = 0.0; x < size.width; x += 22) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line..color = style.ink.withOpacity(0.06));
        }
        for (var y = 0.0; y < size.height; y += 22) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line..color = style.ink.withOpacity(0.06));
        }
        canvas.drawCircle(
          Offset(size.width * 0.86, size.height * 0.30),
          math.min(size.width, size.height) * 0.36,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                style.ink.withOpacity(0.16),
                style.ink.withOpacity(0),
              ],
            ).createShader(Offset.zero & size),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter old) =>
      old.pattern != pattern || old.style != style;
}

/// Horizontal finish picker used on the account form. Shows every preloaded
/// card so the chosen finish is visible before saving.
class CardStylePicker extends StatelessWidget {
  const CardStylePicker({
    super.key,
    required this.selectedHex,
    required this.onSelected,
    this.holder,
  });

  final String selectedHex;
  final ValueChanged<LuxeCardStyle> onSelected;
  final String? holder;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Card finish', style: AppTextStyles.label(palette.sub)),
        const SizedBox(height: 8),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 6),
            itemCount: LuxeCardStyle.presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x3),
            itemBuilder: (context, i) {
              final style = LuxeCardStyle.presets[i];
              final selected =
                  style.hex.toUpperCase() == selectedHex.toUpperCase();
              return GestureDetector(
                onTap: () => onSelected(style),
                child: AspectRatio(
                  aspectRatio: 1.586,
                  child: Stack(
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                          border: Border.all(
                            color: selected ? palette.ink : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: LuxeAccountCard(
                          account: Account(
                            name: holder == null || holder!.trim().isEmpty
                                ? 'Preview'
                                : holder!,
                            type: kAccountBank,
                            color: style.hex,
                            balance: 0,
                          ),
                          style: style,
                          showBalance: false,
                          compact: true,
                          animate: false,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Text(
                          style.name,
                          style: AppTextStyles.caption(
                            Colors.white.withOpacity(0.9),
                          ).copyWith(fontSize: 9.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The live card preview shown while typing a name in the account form.
class LiveCardPreview extends StatelessWidget {
  const LiveCardPreview({
    super.key,
    required this.name,
    required this.type,
    required this.hex,
    this.balance = 0,
    this.creditLimit,
  });

  final String name;
  final String type;
  final String hex;
  final int balance;
  final int? creditLimit;

  @override
  Widget build(BuildContext context) {
    final style = LuxeCardStyle.byHex(hex);
    return LuxeAccountCard(
      account: Account(
        name: name.trim().isEmpty ? 'Account' : name.trim(),
        type: type,
        color: hex,
        balance: balance,
        creditLimit: creditLimit,
      ),
      style: style,
      holder: name,
      animate: true,
    );
  }
}
