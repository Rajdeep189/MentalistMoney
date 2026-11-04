import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

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
      backgroundColor: const Color(0xFF0B0B0F),
      body: Stack(
        children: <Widget>[
          // Soft violet glow
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.accent.withOpacity(0.35),
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
                    child: Container(
                      height: 96,
                      width: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[Color(0xFFA78BFF), Color(0xFF7A55F0)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.45),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'M',
                        style: AppTextStyles.money(
                          44,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ).copyWith(height: 1.1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                FadeTransition(
                  opacity: fade,
                  child: Column(
                    children: <Widget>[
                      Text(
                        'MoneyMan',
                        style: AppTextStyles.displayL(Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track every Money. Own your money.',
                        style: AppTextStyles.caption(AppColors.darkSub),
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
                      gradient: const LinearGradient(
                        colors: <Color>[AppColors.accent, Color(0xFFA78BFF)],
                      ),
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
