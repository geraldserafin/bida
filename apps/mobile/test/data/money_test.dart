import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/money.dart';

void main() {
  group('money', () {
    test('amounts go between złoty and grosze', () {
      expect(toMinor(12.34), 1234);
      expect(fromMinor(1234), 12.34);
      expect(toMinor(0.05), 5);
    });

    test('floating point noise is rounded away', () {
      // 12.34 * 100 is 1233.9999999999998 as a double
      expect(toMinor(12.34), 1234);
      expect(toMinor(0.1 + 0.2), 30);
    });

    test('negative amounts keep their sign', () {
      expect(toMinor(-5.5), -550);
      expect(fromMinor(-550), -5.5);
    });
  });
}
