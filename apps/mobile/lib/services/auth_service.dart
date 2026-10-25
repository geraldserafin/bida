import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../util/pbkdf2.dart';

/// Handles the local unlock: a PIN stored only as a salted PBKDF2 hash, plus
/// optional biometric unlock via the platform.
class AuthService {
  static const _kHash = 'pin_hash';
  static const _kSalt = 'pin_salt';
  static const _kBiometric = 'biometric_enabled';
  static const _iterations = 120000;

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  AuthService({FlutterSecureStorage? storage, LocalAuthentication? localAuth})
    : _storage = storage ?? const FlutterSecureStorage(),
      _localAuth = localAuth ?? LocalAuthentication();

  // ---- PIN ------------------------------------------------------------------

  Future<bool> hasPin() async => (await _storage.read(key: _kHash)) != null;

  Future<void> setPin(String pin) async {
    final salt = _randomBytes(16);
    final hash = pbkdf2(
      password: utf8.encode(pin),
      salt: salt,
      iterations: _iterations,
    );
    await _storage.write(key: _kSalt, value: base64Encode(salt));
    await _storage.write(key: _kHash, value: base64Encode(hash));
  }

  Future<bool> verifyPin(String pin) async {
    final saltB64 = await _storage.read(key: _kSalt);
    final hashB64 = await _storage.read(key: _kHash);
    if (saltB64 == null || hashB64 == null) return false;

    final expected = base64Decode(hashB64);
    final actual = pbkdf2(
      password: utf8.encode(pin),
      salt: base64Decode(saltB64),
      iterations: _iterations,
    );
    return _constantTimeEquals(expected, actual);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _kHash);
    await _storage.delete(key: _kSalt);
    await _storage.delete(key: _kBiometric);
  }

  // ---- biometrics -----------------------------------------------------------

  /// Whether the device exposes any biometric/credential check we can use.
  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _kBiometric)) == 'true';

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _kBiometric, value: enabled.toString());

  Future<bool> authenticateBiometric(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  // ---- helpers --------------------------------------------------------------

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
