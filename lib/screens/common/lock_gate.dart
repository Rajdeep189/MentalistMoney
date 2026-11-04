import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../services/biometric_service.dart';
import '../../widgets/buttons.dart';

/// Biometric / PIN lock overlay. Locks again after the configured timeout.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  bool _locked = false;
  DateTime? _backgroundedAt;
  bool _triedBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = ref.read(settingsSnapshotProvider);
    _locked = settings.biometricLock || settings.pinLock != null;
    if (_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(settingsSnapshotProvider);
    if (!settings.biometricLock && settings.pinLock == null) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
    }
    if (state == AppLifecycleState.resumed && _backgroundedAt != null) {
      final elapsed = DateTime.now().difference(_backgroundedAt!);
      final timeout = Duration(minutes: settings.autoLockMinutes);
      if (elapsed >= timeout) {
        setState(() {
          _locked = true;
          _triedBiometric = false;
        });
      }
      _backgroundedAt = null;
    }
  }

  Future<void> _unlock() async {
    final settings = ref.read(settingsSnapshotProvider);
    if (settings.biometricLock && !_triedBiometric) {
      _triedBiometric = true;
      final ok = await BiometricService.instance.authenticate();
      if (ok && mounted) {
        setState(() => _locked = false);
        return;
      }
    }
  }

  Future<void> _verifyPin() async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (context) => const _PinSheet(),
    );
    final settings = ref.read(settingsSnapshotProvider);
    if (pin != null && pin == settings.pinLock) {
      setState(() => _locked = false);
    } else if (pin != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);

    return Scaffold(
      backgroundColor: palette.isDark ? palette.surface : Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  height: 84,
                  width: 84,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.lock_rounded, size: 36, color: palette.accent),
                ),
                const SizedBox(height: AppSpacing.x5),
                Text('MoneyMan is locked', style: context.h2),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Unlock to view your money.',
                  style: AppTextStyles.body(palette.sub),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.x8),
                if (settings.biometricLock)
                  PrimaryButton(
                    label: 'Unlock with biometrics',
                    icon: Icons.fingerprint_rounded,
                    onPressed: () {
                      _triedBiometric = false;
                      _unlock();
                    },
                  ),
                if (settings.pinLock != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.x3),
                  SecondaryButton(
                    label: 'Use PIN',
                    icon: Icons.pin_rounded,
                    onPressed: _verifyPin,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinSheet extends StatefulWidget {
  const _PinSheet();

  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x2,
        AppSpacing.x5,
        AppSpacing.x5 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Enter your PIN', style: context.h2),
          const SizedBox(height: AppSpacing.x4),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            autofocus: true,
            textAlign: TextAlign.center,
            style: AppTextStyles.money(26, color: palette.ink, weight: FontWeight.w600),
            decoration: const InputDecoration(counterText: '', hintText: '••••'),
          ),
          const SizedBox(height: AppSpacing.x4),
          PrimaryButton(
            label: 'Unlock',
            onPressed: () => Navigator.of(context).pop(_controller.text),
          ),
        ],
      ),
    );
  }
}
