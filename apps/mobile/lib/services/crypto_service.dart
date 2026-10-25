import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

import '../util/pbkdf2.dart';

/// Thrown when a blob can't be decrypted — almost always a wrong passphrase.
class DecryptionException implements Exception {
  const DecryptionException();
  @override
  String toString() => 'DecryptionException: wrong passphrase or corrupt data';
}

/// AES-256-CBC encryption with a PBKDF2-derived key.
///
/// Produces a self-describing JSON envelope (salt + IV + ciphertext + KDF
/// params) so the same passphrase can decrypt it later on any device. Only the
/// ciphertext is secret; the salt and IV are safe to store in the clear.
class CryptoService {
  static const _iterations = 120000;

  /// Encrypts [plaintext] with a key derived from [passphrase]. Returns the
  /// JSON envelope string that gets stored as `data.enc`.
  String encryptToEnvelope(String plaintext, String passphrase) {
    final salt = _randomBytes(16);
    final iv = enc.IV(_randomBytes(16));
    final key = enc.Key(
      pbkdf2(
        password: utf8.encode(passphrase),
        salt: salt,
        iterations: _iterations,
      ),
    );

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return jsonEncode({
      'v': 1,
      'kdf': 'pbkdf2-sha256',
      'iterations': _iterations,
      'salt': base64Encode(salt),
      'iv': base64Encode(iv.bytes),
      'ciphertext': encrypted.base64,
    });
  }

  /// Reverses [encryptToEnvelope]. Throws [DecryptionException] if the
  /// passphrase is wrong or the data is corrupt.
  String decryptFromEnvelope(String envelope, String passphrase) {
    try {
      final json = jsonDecode(envelope) as Map<String, Object?>;
      final salt = base64Decode(json['salt'] as String);
      final iv = enc.IV(base64Decode(json['iv'] as String));
      final iterations = (json['iterations'] as num).toInt();
      final key = enc.Key(
        pbkdf2(
          password: utf8.encode(passphrase),
          salt: salt,
          iterations: iterations,
        ),
      );

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(
        enc.Encrypted.fromBase64(json['ciphertext'] as String),
        iv: iv,
      );
    } catch (_) {
      throw const DecryptionException();
    }
  }

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }
}
