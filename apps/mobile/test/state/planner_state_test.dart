import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/api_exception.dart';
import 'package:money_planner/state/planner_state.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    backend = FakeBackend()
      ..on(
        'GET /categories',
        (_) => Reply([categoryJson('c1', 'Food'), categoryJson('c2', 'Rent')]),
      )
      ..on('GET /recurring-rules', (_) => const Reply([]))
      ..on(
        'GET /periods',
        (_) => Reply([
          periodJson(
            'p2',
            'August',
            incomeMinor: 600000,
            start: '2026-08-01',
            end: '2026-08-31',
          ),
          periodJson('p1', 'July'),
        ]),
      )
      ..on(
        'GET /periods/p2/progress',
        (_) => Reply(
          progressJson('p2', [
            envelopeProgressJson(
              'e1',
              'c1',
              plannedMinor: 100000,
              spentMinor: 25000,
            ),
            envelopeProgressJson(
              'e2',
              'c2',
              plannedMinor: 200000,
              spentMinor: 200000,
            ),
          ]),
        ),
      )
      ..on(
        'GET /periods/p1/progress',
        (_) => Reply(
          progressJson('p1', [
            envelopeProgressJson(
              'e3',
              'c1',
              plannedMinor: 50000,
              spentMinor: 0,
            ),
          ]),
        ),
      );
  });

  PlannerState newState({Future<void> Function()? beforeLoad}) =>
      PlannerState(repository: backend.repository(), beforeLoad: beforeLoad);

  test('starts in the loading state without asking the server', () {
    final state = newState();

    expect(state.isLoading, isTrue);
    expect(backend.requests, isEmpty);
  });

  test(
    'loads the budget it is told to use and forgets it on a change',
    () async {
      final state = newState();

      state.useSpace('home');
      await Future<void>.delayed(Duration.zero);
      await state.load(); // wait for the load that started
      expect(state.categories, isNotEmpty);
      final asked = backend.requests.length;

      state.useSpace('home'); // the same budget: nothing more is asked
      await Future<void>.delayed(Duration.zero);
      expect(backend.requests.length, asked);

      state.useSpace(null); // nobody is signed in
      await Future<void>.delayed(Duration.zero);
      expect(state.categories, isEmpty);
      expect(state.currentPeriod, isNull);
      expect(state.isLoading, isTrue);
    },
  );

  test('shows what was paid into the period next to the income', () async {
    backend.on(
      'GET /periods/p2/progress',
      (_) => Reply({...progressJson('p2', []), 'contributedMinor': 450000}),
    );
    final state = newState();

    await state.load();

    expect(state.contributed, 4500);
  });

  test('remembers the period per budget', () async {
    final state = newState();
    state.useSpace('home');
    await Future<void>.delayed(Duration.zero);
    await state.load();
    await state.selectPeriod('p1');

    final other = newState();
    other.useSpace('work');
    await Future<void>.delayed(Duration.zero);
    await other.load();
    // 'work' never chose, so it starts at the newest period
    expect(other.currentPeriod?.id, 'p2');

    final again = newState();
    again.useSpace('home');
    await Future<void>.delayed(Duration.zero);
    await again.load();
    expect(again.currentPeriod?.id, 'p1');
  });

  test('a plan edit on stale data reloads the plan and is refused', () async {
    backend.on(
      'PUT /periods/p2/plan',
      (_) => Reply.error(409, 'PeriodChanged', {'id': 'p2'}),
    );
    final state = newState();
    await state.load();
    // somebody else saved a new income in the meantime
    backend.on(
      'GET /periods',
      (_) => Reply([
        periodJson(
          'p2',
          'August',
          incomeMinor: 650000,
          start: '2026-08-01',
          end: '2026-08-31',
          version: 2,
        ),
        periodJson('p1', 'July'),
      ]),
    );

    await expectLater(
      state.editCurrentPeriodPlan(income: 7000, plannedByCategory: {'c1': 1}),
      throwsA(isA<ApiException>().having((e) => e.tag, 'tag', 'PeriodChanged')),
    );

    expect(state.currentPeriod?.id, 'p2');
    expect(state.currentPeriod?.income, 6500);
    expect(state.currentPeriod?.version, 2);
  });

  test('load picks the newest period and derives the totals', () async {
    final state = newState();

    await state.load();

    expect(state.isLoading, isFalse);
    expect(state.loadError, isNull);
    expect(state.currentPeriod!.name, 'August');
    expect(state.categories.map((c) => c.name), ['Food', 'Rent']);
    expect(state.income, 6000);
    expect(state.totalPlanned, 3000);
    expect(state.totalSpent, 2250);
    expect(state.totalRemaining, 750);
    expect(state.unallocated, 3000);
    expect(state.isOverAllocated, isFalse);
  });

  test('load remembers the chosen period for next time', () async {
    final first = newState();
    await first.load();
    await first.selectPeriod('p1');
    expect(first.currentPeriod!.name, 'July');
    expect(first.progress.single.planned, 500);

    final second = newState();
    await second.load();

    expect(second.currentPeriod!.name, 'July');
  });

  test('a failed load keeps the reason and a retry recovers', () async {
    backend.on('GET /periods', (_) => const Reply.unreachable());
    final state = newState();

    await state.load();

    expect(state.isLoading, isFalse);
    expect(state.loadError?.failure, ApiFailure.unreachable);
    expect(state.currentPeriod, isNull);

    backend.on('GET /periods', (_) => Reply([periodJson('p1', 'July')]));
    backend.on(
      'GET /periods/p1/progress',
      (_) => Reply(progressJson('p1', [])),
    );
    await state.load();

    expect(state.loadError, isNull);
    expect(state.currentPeriod!.name, 'July');
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
    expect(state.currentPeriod, isNotNull);
  });

  test('a failing hook is a failed load too', () async {
    final state = newState(
      beforeLoad: () async => throw const ApiException(ApiFailure.unreachable),
    );

    await state.load();

    expect(state.loadError?.failure, ApiFailure.unreachable);
    expect(backend.requests, isEmpty);
  });

  test('deleting a category in use is refused without a reload', () async {
    backend.on(
      'DELETE /categories/c1',
      (_) => Reply.error(409, 'CategoryInUse', {'id': 'c1'}),
    );
    final state = newState();
    await state.load();
    final before = backend.sent('GET /categories').length;

    final deleted = await state.deleteCategory('c1');

    expect(deleted, isFalse);
    expect(backend.sent('GET /categories'), hasLength(before));
  });

  test('adding an expense refreshes the progress', () async {
    backend.on(
      'POST /expenses',
      (_) => Reply(expenseJson('x1', 'e1', 1000, periodId: 'p2'), status: 201),
    );
    final state = newState();
    await state.load();
    backend.on(
      'GET /periods/p2/progress',
      (_) => Reply(
        progressJson('p2', [
          envelopeProgressJson(
            'e1',
            'c1',
            plannedMinor: 100000,
            spentMinor: 26000,
          ),
          envelopeProgressJson(
            'e2',
            'c2',
            plannedMinor: 200000,
            spentMinor: 200000,
          ),
        ]),
      ),
    );

    await state.addExpense(
      envelopeId: 'e1',
      amount: 10,
      date: DateTime.utc(2026, 8, 3),
    );

    expect(state.totalSpent, 2260);
    expect(
      backend.sent('POST /expenses').single.body,
      containsPair('amountMinor', 1000),
    );
  });

  test('a failed change is thrown to the caller and changes nothing', () async {
    backend.on(
      'POST /expenses',
      (_) => Reply.error(404, 'EnvelopeNotFound', {'id': 'e1'}),
    );
    final state = newState();
    await state.load();

    await expectLater(
      state.addExpense(
        envelopeId: 'e1',
        amount: 10,
        date: DateTime.utc(2026, 8, 3),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(state.totalSpent, 2250);
  });

  test('creating a period makes it the current one', () async {
    backend.on(
      'POST /periods',
      (_) => Reply(
        periodDetailJson(
          periodJson('p3', 'September', start: '2026-09-01', end: '2026-09-30'),
        ),
        status: 201,
      ),
    );
    final state = newState();
    await state.load();
    backend.on(
      'GET /periods',
      (_) => Reply([
        periodJson('p3', 'September', start: '2026-09-01', end: '2026-09-30'),
        periodJson('p2', 'August'),
      ]),
    );
    backend.on(
      'GET /periods/p3/progress',
      (_) => Reply(progressJson('p3', [])),
    );

    await state.createPeriod(
      name: 'September',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 30),
      income: 5000,
      plannedByCategory: {'c1': 100},
    );

    expect(state.currentPeriod!.id, 'p3');
    expect(state.progress, isEmpty);
    expect(state.periods.map((p) => p.name), ['September', 'August']);
  });

  test(
    'recurring rules pre-fill the plan with the active ones in złoty',
    () async {
      Map<String, Object?> rule(
        String id,
        String categoryId,
        int minor, {
        String currency = 'PLN',
        bool active = true,
      }) => {
        'id': id,
        'categoryId': categoryId,
        'amountMinor': minor,
        'currency': currency,
        'frequency': 'monthly',
        'note': null,
        'active': active,
        'createdAt': '2026-07-01T00:00:00.000Z',
        'updatedAt': '2026-07-01T00:00:00.000Z',
      };
      backend.on(
        'GET /recurring-rules',
        (_) => Reply([
          rule('r1', 'c1', 10000),
          rule('r2', 'c1', 5000),
          rule('r3', 'c2', 99900, active: false),
          rule('r4', 'c2', 1000, currency: 'EUR'),
        ]),
      );
      final state = newState();
      await state.load();

      expect(state.plannedFromRecurring(), {'c1': 150});
    },
  );
}
