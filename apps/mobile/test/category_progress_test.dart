import 'package:flutter_test/flutter_test.dart';

import 'package:money_planner/models/models.dart';
import 'package:money_planner/models/category_progress.dart';

CategoryProgress build({required double planned, required double spent}) {
  return CategoryProgress(
    category: const Category(name: 'Food', color: '#66BB6A'),
    split: Split(periodId: 1, categoryId: 1, plannedAmount: planned),
    spent: spent,
  );
}

void main() {
  group('CategoryProgress', () {
    test('remaining is planned minus spent', () {
      expect(build(planned: 500, spent: 120).remaining, 380);
    });

    test('fraction is the used portion, clamped to 0..1', () {
      expect(build(planned: 200, spent: 50).fraction, 0.25);
      expect(build(planned: 200, spent: 300).fraction, 1.0);
    });

    test('fraction is 0 when nothing was planned (no divide-by-zero)', () {
      expect(build(planned: 0, spent: 40).fraction, 0);
    });

    test('isOverspent flips once spent exceeds planned', () {
      expect(build(planned: 100, spent: 100).isOverspent, isFalse);
      expect(build(planned: 100, spent: 100.01).isOverspent, isTrue);
    });
  });
}
