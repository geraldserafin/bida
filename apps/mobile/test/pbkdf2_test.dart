import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/util/pbkdf2.dart';

String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('pbkdf2 (HMAC-SHA256)', () {
    test('matches the standard c=1 test vector', () {
      // password="password", salt="salt", iterations=1, dkLen=32.
      final result = pbkdf2(
        password: utf8.encode('password'),
        salt: utf8.encode('salt'),
        iterations: 1,
        derivedKeyLength: 32,
      );
      expect(
        hex(result),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
    });

    test('matches the standard c=2 test vector', () {
      final result = pbkdf2(
        password: utf8.encode('password'),
        salt: utf8.encode('salt'),
        iterations: 2,
        derivedKeyLength: 32,
      );
      expect(
        hex(result),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });

    test('different salts produce different keys', () {
      final a = pbkdf2(
        password: utf8.encode('1234'),
        salt: utf8.encode('saltA'),
      );
      final b = pbkdf2(
        password: utf8.encode('1234'),
        salt: utf8.encode('saltB'),
      );
      expect(hex(a), isNot(hex(b)));
      expect(a.length, 32);
    });
  });
}
