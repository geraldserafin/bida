import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/services/crypto_service.dart';

void main() {
  final crypto = CryptoService();

  group('CryptoService', () {
    test('round-trips plaintext with the right passphrase', () {
      const plaintext = '{"periods":[{"id":1,"income":5000}]}';
      final envelope = crypto.encryptToEnvelope(plaintext, 'correct horse');
      expect(crypto.decryptFromEnvelope(envelope, 'correct horse'), plaintext);
    });

    test('produces a different envelope each time (random salt/IV)', () {
      final a = crypto.encryptToEnvelope('same', 'pw');
      final b = crypto.encryptToEnvelope('same', 'pw');
      expect(a, isNot(b));
    });

    test('throws on the wrong passphrase', () {
      final envelope = crypto.encryptToEnvelope('secret', 'right');
      expect(
        () => crypto.decryptFromEnvelope(envelope, 'wrong'),
        throwsA(isA<DecryptionException>()),
      );
    });
  });
}
