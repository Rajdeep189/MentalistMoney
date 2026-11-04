import 'package:flutter/services.dart';

/// Toggles FLAG_SECURE (blocks screenshots & screen recording).
class SecureScreenService {
  SecureScreenService._();

  static final SecureScreenService instance = SecureScreenService._();

  static const MethodChannel _channel = MethodChannel('moneyman/secure');

  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> setSecure(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    try {
      await _channel.invokeMethod<bool>('setSecure', enabled);
    } on MissingPluginException {
      // Desktop / tests: nothing to do.
    } on PlatformException {
      // Ignore – the flag is best effort.
    }
  }
}
