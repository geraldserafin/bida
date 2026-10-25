import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/models/models.dart';

EnvelopeProgress build({
  double opening = 0,
  double allocated = 0,
  double spent = 0,
}) {
  final balance = opening + allocated - spent;
  return EnvelopeProgress(
    envelope: const Envelope(name: 'Food', color: '#66BB6A'),
    opening: opening,
    allocated: allocated,
    spent: spent,
    balance: balance,
    free: balance,
  );
}

void main() {
  group('EnvelopeProgress', () {
    test('what is available is the rest from before plus what came in', () {
      expect(build(opening: 100, allocated: 400).available, 500);
    });

    test('fraction is the used portion, clamped to 0..1', () {
      expect(build(allocated: 200, spent: 50).fraction, 0.25);
      expect(build(allocated: 200, spent: 300).fraction, 1.0);
    });

    test('fraction has no divide-by-zero when nothing was available', () {
      expect(build(spent: 0).fraction, 0);
      expect(build(spent: 40).fraction, 1);
    });

    test('isOverspent flips once the balance is below zero', () {
      expect(build(allocated: 100, spent: 100).isOverspent, isFalse);
      expect(build(allocated: 100, spent: 100.01).isOverspent, isTrue);
    });
  });
}
