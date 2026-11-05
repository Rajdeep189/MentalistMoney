import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'data/models/app_settings.dart';
import 'providers/app_providers.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/setup/first_run_setup_screen.dart';
import 'screens/shell/main_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'services/secure_screen_service.dart';

class MoneyManApp extends ConsumerWidget {
  const MoneyManApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return settings.when(
      loading: () => const _BootSplash(),
      error: (error, _) => _BootError(message: '$error'),
      data: (value) {
        applyFormatting(value);
        SecureScreenService.instance.setSecure(value.blockScreenshots);
        final pack = value.pack;
        final accent = pack.id == 'default' ? value.accentColor : pack.accent;

        return MaterialApp(
          title: 'MoneyMan',
          debugShowCheckedModeBanner: false,
          themeMode: value.themeMode,
          theme: AppTheme.light(accent: accent, pack: pack),
          darkTheme: AppTheme.dark(accent: accent, pack: pack),
          themeAnimationDuration: const Duration(milliseconds: 420),
          themeAnimationCurve: Curves.easeInOutCubic,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final scale = value.fontScale;
            final palette = Theme.of(context).extension<AppPalette>()!;
            SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayFor(palette));
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(scale.clamp(0.85, 1.35).toDouble()),
                viewPadding: media.viewPadding,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: AppBoot(settings: value),
        );
      },
    );
  }
}

/// Decides which root screen to show: onboarding, first-run setup or the app.
class AppBoot extends ConsumerStatefulWidget {
  const AppBoot({super.key, required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<AppBoot> createState() => _AppBootState();
}

class _AppBootState extends ConsumerState<AppBoot> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) return const SplashScreen();

    if (!widget.settings.onboardingDone) {
      return const OnboardingScreen();
    }

    final accounts = ref.watch(accountsProvider);
    return accounts.when(
      loading: () => const SplashScreen(showProgress: false),
      error: (error, _) => _BootError(message: '$error'),
      data: (list) {
        if (list.isEmpty) return const FirstRunSetupScreen();
        return const MainShell();
      },
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 40),
              const SizedBox(height: 16),
              Text(
                'MoneyMan could not start',
                style: AppTextStyles.h2(Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.body(AppColors.darkSub),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
