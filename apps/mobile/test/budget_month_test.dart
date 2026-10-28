import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/models/models.dart';

void main() {
  group('BudgetMonth', () {
    test('a calendar month runs from the 1st to the last day', () {
      final month = BudgetMonth.containing(DateTime(2026, 2, 14));
      expect(month.from, DateTime(2026, 2, 1));
      expect(month.to, DateTime(2026, 2, 28));
    });

    test('a month can start on another day', () {
      final month = BudgetMonth.containing(DateTime(2026, 7, 5), firstDay: 10);
      expect(month.from, DateTime(2026, 6, 10));
      expect(month.to, DateTime(2026, 7, 9));
      expect(
        BudgetMonth.containing(DateTime(2026, 7, 10), firstDay: 10).from,
        DateTime(2026, 7, 10),
      );
    });

    test('the neighbours line up without gaps, also across years', () {
      final december = BudgetMonth.containing(DateTime(2026, 12, 20));
      expect(december.next.from, DateTime(2027, 1, 1));
      expect(december.next.previous, december);
      expect(december.previous.to, DateTime(2026, 11, 30));
      expect(december.previous.to.add(const Duration(days: 1)), december.from);
    });

    test('contains tells days of the month from others', () {
      final month = BudgetMonth.containing(DateTime(2026, 8, 15));
      expect(month.contains(DateTime(2026, 8, 1)), isTrue);
      expect(month.contains(DateTime(2026, 8, 31, 23, 59)), isTrue);
      expect(month.contains(DateTime(2026, 9, 1)), isFalse);
      expect(month.contains(DateTime(2026, 7, 31)), isFalse);
    });
  });
}
