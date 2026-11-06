import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/luxe.dart';

/// Animated brand splash. Fades + scales the logo and expands the accent line.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.showProgress = true});

  final bool showProgress;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
    );
    final line = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
    );
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: AppColors.espresso,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: AuroraBackground(
              intensity: 1.2,
              child: SizedBox.expand(),
            ),
          ),
          // champagne halo
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            child: Container(
              height: 460,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.accent.withOpacity(0.24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1).animate(logoScale),
                  child: FadeTransition(
                    opacity: logoScale,
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 104,
                          width: 104,
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.savings_rounded,
                            size: 52,
                            color: AppColors.espresso,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                FadeTransition(
                  opacity: fade,
                  child: Column(
                    children: <Widget>[
                      ShineSweep(
                        period: const Duration(milliseconds: 4200),
                        opacity: 0.45,
                        child: Text(
                          'MoneyMan',
                          style: AppTextStyles.serif(
                            size: 34,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MONEY, MADE SIMPLE',
                        style: AppTextStyles.caption(AppColors.accent)
                            .copyWith(fontSize: 10, letterSpacing: 2.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x6),
                AnimatedBuilder(
                  animation: line,
                  builder: (context, _) => Container(
                    height: 3,
                    width: 120 * line.value,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (widget.showProgress) ...<Widget>[
                  const SizedBox(height: AppSpacing.x8),
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: fade,
              child: Text(
                'Offline-first · Private by design',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(Colors.white.withOpacity(0.35)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
