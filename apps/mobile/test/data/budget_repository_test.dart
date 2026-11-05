import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/api_exception.dart';
import 'package:money_planner/models/models.dart';

import '../support/fake_backend.dart';

void main() {
  test('the app start reads the closed periods to show', () async {
    final backend = FakeBackend()
      ..on(
        'POST /sync',
        (_) => Reply(
          syncJson(
            summaries: [
              {
                'periodId': 'p0',
                'householdId': 'h1',
                'householdName': 'Dom',
                'startsOn': '2026-06-01',
                'endsOn': '2026-06-30',
                'transfersMinor': 100000,
                'withdrawalsMinor': 0,
                'carryInMinor': 0,
                'spentMinor': 70000,
                'carryOutMinor': 30000,
              },
            ],
          ),
        ),
      );
    final synced = await backend.repository().sync();
    expect(synced.summaries.single.carryOutMinor, 30000);
    expect(synced.summaries.single.endsOn, DateTime(2026, 6, 30));
  });

  test('an expense goes without a decision, then with the one made', () async {
    final backend = FakeBackend()
      ..on('POST /households/h1/expenses', (r) {
        final body = r.body! as Map;
        if (body['decision'] == null) {
          return Reply.error(409, 'PlanTooSmall', {
            'envelopeId': 'e1',
            'planShortMinor': 500,
            'freeMinor': 0,
            'balanceMinor': 0,
            'transferMinor': 500,
          });
        }
        return Reply(expenseResultJson(500), status: 201);
      });
    final repo = backend.repository();
    final draft = ExpenseDraft(
      envelopeId: 'e1',
      amountMinor: 500,
      spentAt: DateTime.utc(2026, 7, 3, 10),
    );

    final error = await repo
        .addExpense('h1', draft)
        .then<ApiException?>(
          (_) => null,
          onError: (Object e) => e as ApiException,
        );
    expect(error?.tag, 'PlanTooSmall');
    expect(error?.transferMinor, 500);
    expect(error?.planShortMinor, 500);

    final saved = await repo.addExpense(
      'h1',
      draft,
      decision: const Decision(raisePlan: true, transferMinor: 500),
    );
    expect(saved.expense.amountMinor, 500);
    final sent = backend.sent('POST /households/h1/expenses').last.body! as Map;
    expect(sent['spentAt'], '2026-07-03T10:00:00.000Z');
    expect(sent['decision'], {
      'raisePlan': true,
      'transferMinor': 500,
      'allowNegativeWallet': false,
    });
  });

  test('a recurring transfer goes to the current or the next period', () async {
    final backend = FakeBackend()
      ..on('POST /recurring-rules', (r) => Reply(r.body, status: 201));
    await backend
        .repository()
        .saveRule(
          const RecurringRule(
            kind: RuleKind.transfer,
            householdId: 'h1',
            name: 'Wypłata',
            amountMinor: 100000,
            dayOfMonth: 28,
            toNextPeriod: true,
            estimated: true,
          ),
        )
        .catchError((_) {});
    final body = backend.sent('POST /recurring-rules').single.body! as Map;
    expect(body['target'], 'next');
    expect(body['dayOfMonth'], 28);
    // only incomes and expenses are estimated
    expect(body['estimated'], false);
    expect(body['envelopeId'], isNull);
  });

  test('a household starts monthly from the day chosen', () async {
    final backend = FakeBackend()
      ..on('POST /households', (_) => Reply(householdJson(), status: 201));
    final h = await backend.repository().createHousehold(
      name: 'Dom',
      cycle: const Cycle.monthly(10),
      envelopes: ['Jedzenie'],
    );
    expect(h.current.startsOn, DateTime(2026, 7, 1));
    final body = backend.sent('POST /households').single.body! as Map;
    expect(body['cycle'], {
      'kind': 'monthly',
      'day': 10,
      'weeks': null,
      'anchorOn': null,
    });
    expect(body['envelopes'], ['Jedzenie']);
  });

  test('a negative share says who owes where', () async {
    final backend = FakeBackend()
      ..on(
        'POST /households/h1/leave',
        (_) => Reply.error(409, 'NegativeShare', {
          'entries': [
            {
              'householdId': 'h1',
              'householdName': 'Dom',
              'periodId': 'p1',
              'userId': 'u2',
              'name': 'Bob',
              'shareMinor': -3000,
            },
          ],
        }),
      );
    try {
      await backend.repository().leave('h1', withdraw: true);
      fail('should refuse');
    } on ApiException catch (error) {
      expect(error.failure, ApiFailure.conflict);
      expect(error.negativeShares.single.shareMinor, -3000);
      expect(error.negativeShares.single.name, 'Bob');
    }
  });
}
