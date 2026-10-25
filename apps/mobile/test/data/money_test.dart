import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/money.dart';

void main() {
  group('money', () {
    test('amounts go between whole units and minor units', () {
      expect(toMinor(12.34, 'PLN'), 1234);
      expect(fromMinor(1234, 'PLN'), 12.34);
      expect(toMinor(0.05, 'EUR'), 5);
    });

    test('floating point noise is rounded away', () {
      // 12.34 * 100 is 1233.9999999999998 as a double
      expect(toMinor(12.34, 'PLN'), 1234);
      expect(toMinor(0.1 + 0.2, 'PLN'), 30);
    });

    test('a currency without decimals keeps whole numbers', () {
      expect(exponentOf('JPY'), 0);
      expect(toMinor(500, 'JPY'), 500);
      expect(fromMinor(500, 'JPY'), 500);
    });

    test('an unknown currency falls back to two decimals', () {
      expect(exponentOf('XYZ'), 2);
    });
  });
}
