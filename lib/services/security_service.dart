import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _twoFaEnabledKey    = 'security_two_fa_enabled';
  static const String _twoFaSecretKey     = 'security_two_fa_secret';
  static const String _pendingTwoFaKey    = 'security_pending_two_fa_secret';
  static const String _deviceTokenKey     = 'tajir_device_token';
  static const String _pinEnabledKey      = 'security_pin_enabled';
  static const String _biometricEnabledKey = 'security_biometric_enabled';
  static const String _tradeTokenKey      = 'security_trade_token';

  Future<bool> isTwoFaEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_twoFaEnabledKey) ?? false;
  }

  Future<bool> isBiometricEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_biometricEnabledKey) ?? false;
  }

  Future<bool> isPinEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_pinEnabledKey) ?? false;
  }

  Future<void> enableBiometric() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_biometricEnabledKey, true);
  }

  Future<void> disableBiometric() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_biometricEnabledKey, false);
  }

  Future<void> enablePin(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_pinEnabledKey, true);
    await p.setString('security_pin_hash', pin.hashCode.toString());
  }

  Future<void> disablePin() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_pinEnabledKey, false);
  }

  Future<bool> verifyPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString('security_pin_hash');
    return stored == pin.hashCode.toString();
  }

  Future<String?> getTwoFaSecret() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_twoFaSecretKey);
  }

  Future<void> setTwoFaSecret(String secret) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_twoFaSecretKey, secret);
    await p.setBool(_twoFaEnabledKey, true);
  }

  Future<void> saveTradePin(String pin) => enablePin(pin);

  Future<void> disableTwoFa() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_twoFaEnabledKey, false);
    await p.remove(_twoFaSecretKey);
  }

  Future<String> getOrCreateDeviceToken() async {
    final p = await SharedPreferences.getInstance();
    var token = p.getString(_deviceTokenKey);
    if (token == null) {
      token = DateTime.now().millisecondsSinceEpoch.toString();
      await p.setString(_deviceTokenKey, token);
    }
    return token;
  }
}

