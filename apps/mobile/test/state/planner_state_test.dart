import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/api_exception.dart';
import 'package:money_planner/models/models.dart';
import 'package:money_planner/state/planner_state.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;

  // "today" for every test: the middle of August 2026
  DateTime clock() => DateTime(2026, 8, 15, 12);

  setUp(() {
    backend = FakeBackend()
      ..on(
        'GET /envelopes',
        (_) => Reply([
          envelopeJson('e1', 'Home'),
          envelopeJson('e2', 'Rent', parentId: 'e1'),
          envelopeJson('e3', 'Food'),
        ]),
      )
      ..noRules()
      ..on(
        'GET /overview',
        (_) => Reply(
          overviewJson(
            income: 600000,
            allocated: 300000,
            spent: 225000,
            pool: 300000,
            envelopes: [
              figuresJson('e1', opening: 0, allocated: 200000, spent: 200000),
              figuresJson(
                'e2',
                parentId: 'e1',
                allocated: 150000,
                spent: 150000,
              ),
              figuresJson('e3', opening: 5000, allocated: 100000, spent: 25000),
            ],
          ),
        ),
      );
  });

  PlannerState newState({Future<void> Function()? beforeLoad}) => PlannerState(
    repository: backend.repository(),
    beforeLoad: beforeLoad,
    clock: clock,
  );

  test('starts in the loading state without asking the server', () {
    final state = newState();

    expect(state.isLoading, isTrue);
    expect(backend.requests, isEmpty);
  });

  test(
    'loads when somebody signs in and forgets everything on sign-out',
    () async {
      final state = newState();

      state.signedIn(true);
      await Future<void>.delayed(Duration.zero);
      await state.load(); // wait for the load the sign-in started
      expect(state.envelopes, isNotEmpty);
      final asked = backend.requests.length;

      state.signedIn(true); // already signed in: nothing more is asked
      await Future<void>.delayed(Duration.zero);
      expect(backend.requests.length, asked);

      state.signedIn(false);
      await Future<void>.delayed(Duration.zero);
      expect(state.envelopes, isEmpty);
      expect(state.progress, isEmpty);
      expect(state.isLoading, isTrue);
    },
  );

  test('load shows the month of today and derives the totals', () async {
    final state = newState();

    await state.load();

    expect(state.isLoading, isFalse);
    expect(state.loadError, isNull);
    expect(state.month.from, DateTime(2026, 8, 1));
    expect(state.month.to, DateTime(2026, 8, 31));
    expect(state.isCurrentMonth, isTrue);
    expect(backend.sent('GET /overview').single.query, {
      'from': '2026-08-01',
      'to': '2026-08-31',
    });
    expect(state.envelopes.map((e) => e.name), ['Home', 'Rent', 'Food']);
    expect(state.income, 6000);
    expect(state.allocated, 3000);
    expect(state.spent, 2250);
    expect(state.pool, 3000);
    expect(state.isOverAllocated, isFalse);
  });

  test('top-level envelopes and their children are told apart', () async {
    final state = newState();
    await state.load();

    expect(state.topLevel.map((e) => e.name), ['Home', 'Food']);
    expect(state.childrenOf('e1').map((e) => e.name), ['Rent']);
    expect(state.topLevelProgress.map((p) => p.envelope.id), ['e1', 'e3']);
    expect(state.childrenProgressOf('e1').single.envelope.id, 'e2');
    final food = state.progressOf('e3')!;
    expect([food.opening, food.available, food.balance], [50, 1050, 800]);
    expect(state.progressOf('missing'), isNull);
  });

  test('a pool below zero is over-allocation', () async {
    backend.on('GET /overview', (_) => Reply(overviewJson(pool: -1000)));
    final state = newState();

    await state.load();

    expect(state.pool, -10);
    expect(state.isOverAllocated, isTrue);
  });

  test('a user with nothing yet has an empty dashboard', () async {
    backend
      ..on('GET /envelopes', (_) => const Reply([]))
      ..on('GET /overview', (_) => Reply(overviewJson()));
    final state = newState();

    await state.load();

    expect(state.isEmpty, isTrue);
  });

  test('moving between months asks for the figures of that month', () async {
    final state = newState();
    await state.load();

    await state.previousMonth();
    expect(state.month.from, DateTime(2026, 7, 1));
    expect(state.isCurrentMonth, isFalse);
    expect(backend.sent('GET /overview').last.query, {
      'from': '2026-07-01',
      'to': '2026-07-31',
    });

    await state.nextMonth();
    await state.nextMonth();
    expect(state.month.from, DateTime(2026, 9, 1));

    await state.goToCurrentMonth();
    expect(state.isCurrentMonth, isTrue);
  });

  test('a failed switch of month keeps the one on screen', () async {
    final state = newState();
    await state.load();
    backend.on('GET /overview', (_) => const Reply.unreachable());

    await expectLater(state.previousMonth(), throwsA(isA<ApiException>()));

    expect(state.month.from, DateTime(2026, 8, 1));
    expect(state.spent, 2250);
  });

  test('months can start on another day', () async {
    final state = newState()..useFirstDay(10);
    await state.load();

    expect(state.month.from, DateTime(2026, 8, 10));
    expect(state.month.to, DateTime(2026, 9, 9));
    expect(backend.sent('GET /overview').single.query['from'], '2026-08-10');
  });

  test('the history of months uses the first day too', () async {
    backend.on(
      'GET /overview/months',
      (_) => Reply([monthSummaryJson('2026-08-10', '2026-09-09')]),
    );
    final state = newState()..useFirstDay(10);

    final months = await state.monthSummaries();

    expect(months.single.month.from, DateTime(2026, 8, 10));
    expect(backend.sent('GET /overview/months').single.query, {
      'startDay': '10',
    });
  });

  test('a failed load keeps the reason and a retry recovers', () async {
    backend.on('GET /envelopes', (_) => const Reply.unreachable());
    final state = newState();

    await state.load();

    expect(state.isLoading, isFalse);
    expect(state.loadError?.failure, ApiFailure.unreachable);
    expect(state.envelopes, isEmpty);

    backend.on('GET /envelopes', (_) => Reply([envelopeJson('e1', 'Home')]));
    await state.load();

    expect(state.loadError, isNull);
    expect(state.envelopes.single.name, 'Home');
  });

  test('load first runs the hook that moves old data to the server', () async {
    var ran = false;
    final state = newState(
      beforeLoad: () async {
        // nothing may be fetched before the old data is on the server
        expect(backend.requests, isEmpty);
        ran = true;
      },
    );

    await state.load();

    expect(ran, isTrue);
    expect(state.envelopes, isNotEmpty);
  });

  test('a failing hook is a failed load too', () async {
    final state = newState(
      beforeLoad: () async => throw const ApiException(ApiFailure.unreachable),
    );

    await state.load();

    expect(state.loadError?.failure, ApiFailure.unreachable);
    expect(backend.requests, isEmpty);
  });

  test('adding an expense refreshes the figures', () async {
    backend.on(
      'POST /expenses',
      (_) => Reply(expenseJson('x1', 'e3', 1000), status: 201),
    );
    final state = newState();
    await state.load();
    backend.on(
      'GET /overview',
      (_) => Reply(
        overviewJson(
          spent: 226000,
          envelopes: [figuresJson('e3', allocated: 100000, spent: 26000)],
        ),
      ),
    );

    await state.addExpense(
      envelopeId: 'e3',
      amount: 10,
      date: DateTime.utc(2026, 8, 3),
    );

    expect(state.spent, 2260);
    expect(state.progressOf('e3')!.spent, 260);
    expect(
      backend.sent('POST /expenses').single.body,
      containsPair('amountMinor', 1000),
    );
  });

  test('a failed change is thrown to the caller and changes nothing', () async {
    backend.on(
      'POST /expenses',
      (_) => Reply.error(404, 'EnvelopeNotFound', {'id': 'e3'}),
    );
    final state = newState();
    await state.load();

    await expectLater(
      state.addExpense(
        envelopeId: 'e3',
        amount: 10,
        date: DateTime.utc(2026, 8, 3),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(state.spent, 2250);
  });

  test('putting money into an envelope refreshes the pool', () async {
    backend.on(
      'POST /allocations',
      (_) => Reply(allocationJson('a1', 'e3', 5000), status: 201),
    );
    final state = newState();
    await state.load();
    backend.on('GET /overview', (_) => Reply(overviewJson(pool: 250000)));

    await state.saveAllocation(
      Allocation(envelopeId: 'e3', amount: 50, madeOn: DateTime(2026, 8, 15)),
    );

    expect(state.pool, 2500);
  });

  test(
    'an envelope without the money is refused and nothing is reloaded',
    () async {
      backend.on(
        'POST /allocations',
        (_) => Reply.error(409, 'NotEnoughMoney', {
          'envelopeId': 'e3',
          'availableMinor': 1000,
        }),
      );
      final state = newState();
      await state.load();
      final before = backend.sent('GET /overview').length;

      await expectLater(
        state.saveAllocation(
          Allocation(
            envelopeId: 'e3',
            amount: -500,
            madeOn: DateTime(2026, 8, 15),
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.availableMinor,
            'available',
            1000,
          ),
        ),
      );
      expect(backend.sent('GET /overview'), hasLength(before));
    },
  );

  test('adding an envelope reloads the envelopes and the figures', () async {
    backend.on(
      'POST /envelopes',
      (_) => Reply(envelopeJson('e4', 'Fun'), status: 201),
    );
    final state = newState();
    await state.load();
    backend.on(
      'GET /envelopes',
      (_) => Reply([envelopeJson('e1', 'Home'), envelopeJson('e4', 'Fun')]),
    );

    final created = await state.addEnvelope(
      const Envelope(name: 'Fun', color: '#22C55E'),
    );

    expect(created.id, 'e4');
    expect(state.envelopes.map((e) => e.name), ['Home', 'Fun']);
  });

  test('load asks what the recurring rules would add', () async {
    backend.on(
      'GET /recurring-rules/pending',
      (_) => const Reply({
        'incomes': 1,
        'allocations': 2,
        'expenses': 0,
        'skipped': 0,
      }),
    );
    final state = newState();

    await state.load();

    expect(state.pending.incomes, 1);
    expect(state.pending.allocations, 2);
    expect(state.pending.added, 3);
    expect(backend.sent('GET /recurring-rules/pending').single.query, {
      'from': '2026-08-01',
      'to': '2026-08-31',
    });
  });

  test('the pending rules are asked again for another month', () async {
    final state = newState();
    await state.load();
    final before = backend.sent('GET /recurring-rules/pending').length;

    await state.nextMonth();

    expect(backend.sent('GET /recurring-rules/pending'), hasLength(before + 1));
    expect(
      backend.sent('GET /recurring-rules/pending').last.query['from'],
      '2026-09-01',
    );
  });

  test('applying reloads the figures only when something was added', () async {
    backend.on(
      'POST /recurring-rules/apply',
      (_) => const Reply({
        'incomes': 0,
        'allocations': 0,
        'expenses': 0,
        'skipped': 0,
      }),
    );
    final state = newState();
    await state.load();
    final before = backend.sent('GET /overview').length;

    expect((await state.applyRecurringToMonth()).isEmpty, isTrue);
    expect(backend.sent('GET /overview'), hasLength(before));

    backend.on(
      'POST /recurring-rules/apply',
      (_) => const Reply({
        'incomes': 1,
        'allocations': 1,
        'expenses': 2,
        'skipped': 1,
      }),
    );
    final outcome = await state.applyRecurringToMonth();
    expect(
      [outcome.incomes, outcome.allocations, outcome.expenses, outcome.skipped],
      [1, 1, 2, 1],
    );
    expect(backend.sent('GET /overview'), hasLength(before + 1));
    expect(backend.sent('POST /recurring-rules/apply').last.body, {
      'from': '2026-08-01',
      'to': '2026-08-31',
    });
  });

  test(
    'saving and deleting the rules refreshes them and the pending ones',
    () async {
      backend
        ..on(
          'POST /recurring-incomes',
          (_) => Reply(recurringIncomeJson('r1', 500000, 10), status: 201),
        )
        ..on(
          'DELETE /allocation-rules/a1',
          (_) => const Reply(null, status: 204),
        );
      final state = newState();
      await state.load();
      backend.on(
        'GET /recurring-incomes',
        (_) => Reply([recurringIncomeJson('r1', 500000, 10)]),
      );
      final pending = backend.sent('GET /recurring-rules/pending').length;

      await state.saveRecurringIncome(
        const RecurringIncome(amount: 5000, dayOfMonth: 10),
      );
      await state.deleteAllocationRule('a1');

      expect(state.recurringIncomes.single.amount, 5000);
      expect(
        backend.sent('GET /recurring-rules/pending'),
        hasLength(pending + 2),
      );
      expect(backend.sent('POST /recurring-incomes').single.body, {
        'amountMinor': 500000,
        'dayOfMonth': 10,
        'note': null,
        'active': true,
      });
    },
  );

  group('sharing', () {
    test('load fetches the invitations waiting for the user', () async {
      backend.on(
        'GET /invitations',
        (_) => Reply([invitationJson('i1', 'e9', 'me@example.com')]),
      );
      final state = newState();

      await state.load();

      expect(state.invitations.single.envelopeName, 'Home');
    });

    test('accepting an invitation asks again what is left', () async {
      var open = [invitationJson('i1', 'e9', 'me@example.com')];
      backend
        ..on('GET /invitations', (_) => Reply(open))
        ..on(
          'POST /invitations/i1/accept',
          (_) => Reply(
            invitationJson('i1', 'e9', 'me@example.com', status: 'accepted'),
          ),
        );
      final state = newState();
      await state.load();

      open = [];
      await state.acceptInvitation('i1');

      expect(state.invitations, isEmpty);
    });

    test('declining works the same way', () async {
      var open = [invitationJson('i1', 'e9', 'me@example.com')];
      backend
        ..on('GET /invitations', (_) => Reply(open))
        ..on(
          'POST /invitations/i1/decline',
          (_) => const Reply(null, status: 204),
        );
      final state = newState();
      await state.load();

      open = [];
      await state.declineInvitation('i1');

      expect(state.invitations, isEmpty);
      expect(backend.sent('POST /invitations/i1/decline'), hasLength(1));
    });

    test('leaving drops the envelope from the user', () async {
      backend.on(
        'DELETE /envelopes/e1/members/u1',
        (_) => const Reply(null, status: 204),
      );
      final state = newState();
      await state.load();
      backend.on('GET /envelopes', (_) => Reply([envelopeJson('e3', 'Food')]));

      await state.removeMember('e1', 'u1', leaving: true);

      expect(state.envelopes.map((e) => e.name), ['Food']);
    });

    test(
      'approving somebody asks again for the people in the envelope',
      () async {
        backend.on(
          'POST /envelopes/e1/invitations/i1/approve',
          (_) => Reply(memberJson('u2', 'bob@example.com')),
        );
        final state = newState();
        await state.load();
        final before = backend.sent('GET /overview').length;

        await state.approveInvitation('e1', 'i1');

        expect(backend.sent('GET /overview'), hasLength(before + 1));
      },
    );
  });
}
