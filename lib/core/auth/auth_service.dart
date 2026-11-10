import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = LocalAuthentication();

  final isLocked = ValueNotifier<bool>(false);
  final privacyMode = ValueNotifier<bool>(false);
  final biometricEnabled = ValueNotifier<bool>(false);

  static const _keyBiometric = 'biometricEnabled';
  static const _keyPrivacy = 'privacyMode';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    biometricEnabled.value = prefs.getBool(_keyBiometric) ?? false;
    privacyMode.value = prefs.getBool(_keyPrivacy) ?? false;
    if (biometricEnabled.value) isLocked.value = true;
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Unlock Keel'}) async {
    try {
      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (result) isLocked.value = false;
      return result;
    } catch (_) {
      return false;
    }
  }

  void lock() {
    if (biometricEnabled.value) isLocked.value = true;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometric, enabled);
    biometricEnabled.value = enabled;
    if (!enabled) isLocked.value = false;
  }

  Future<void> setPrivacyMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrivacy, enabled);
    privacyMode.value = enabled;
  }
}
