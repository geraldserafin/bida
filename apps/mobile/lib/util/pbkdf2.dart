import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 key derivation (RFC 2898).
///
/// Used both to hash the unlock PIN and (later) to derive the AES key for
/// encrypted sync, so a short PIN still costs real work to brute-force.
Uint8List pbkdf2({
  required List<int> password,
  required List<int> salt,
  int iterations = 120000,
  int derivedKeyLength = 32,
}) {
  final prf = Hmac(sha256, password);
  const hashLen = 32; // sha256 output size
  final numBlocks = (derivedKeyLength / hashLen).ceil();
  final output = BytesBuilder();

  for (var block = 1; block <= numBlocks; block++) {
    // U1 = PRF(password, salt || INT_32_BE(block))
    final blockIndex = Uint8List(4)
      ..[0] = (block >> 24) & 0xff
      ..[1] = (block >> 16) & 0xff
      ..[2] = (block >> 8) & 0xff
      ..[3] = block & 0xff;

    var u = prf.convert([...salt, ...blockIndex]).bytes;
    final t = List<int>.from(u);

    for (var i = 1; i < iterations; i++) {
      u = prf.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    output.add(t);
  }

  return output.toBytes().sublist(0, derivedKeyLength);
}
