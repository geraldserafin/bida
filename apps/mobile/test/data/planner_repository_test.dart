import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/api_exception.dart';
import 'package:money_planner/models/models.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  group('categories', () {
    test('lists and maps them', () async {
      backend.on(
        'GET /categories',
        (_) => Reply([categoryJson('c1', 'Food', icon: 'restaurant')]),
      );

      final categories = await backend.repository().categories();

      expect(categories.single.id, 'c1');
      expect(categories.single.name, 'Food');
      expect(categories.single.icon, 'restaurant');
    });

    test('deleting reports whether it happened', () async {
      backend.on(
        'DELETE /categories/free',
        (_) => const Reply(null, status: 204),
      );
      backend.on(
        'DELETE /categories/used',
        (_) => Reply.error(409, 'CategoryInUse', {'id': 'used'}),
      );
      backend.on(
        'DELETE /categories/gone',
        (_) => Reply.error(404, 'CategoryNotFound'),
      );
      final repository = backend.repository();

      expect(await repository.deleteCategory('free'), isTrue);
      expect(await repository.deleteCategory('used'), isFalse);
      // anything else is a real failure
      expect(
        repository.deleteCategory('gone'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            ApiFailure.notFound,
          ),
        ),
      );
    });
  });

  group('periods', () {
    test('creating sends minor units, the currency and the plan', () async {
      backend.on(
        'POST /periods',
        (_) => Reply(
          periodDetailJson(periodJson('p1', 'July', incomeMinor: 500050)),
          status: 201,
        ),
      );

      final period = await backend.repository().createPeriod(
        name: 'July',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        income: 5000.5,
        plannedByCategory: {'c1': 1200.25, 'c2': 0},
      );

      expect(period.id, 'p1');
      expect(period.income, 5000.5);
      expect(period.currency, 'PLN');
      expect(period.startDate, DateTime(2026, 7, 1));
      expect(backend.sent('POST /periods').single.body, {
        'name': 'July',
        'startDate': '2026-07-01',
        'endDate': '2026-07-31',
        'incomeMinor': 500050,
        'currency': 'PLN',
        'envelopes': [
          {'categoryId': 'c1', 'plannedMinor': 120025},
          {'categoryId': 'c2', 'plannedMinor': 0},
        ],
      });
    });

    test('editing the plan uses the currency of the period', () async {
      backend.on(
        'PUT /periods/p1/plan',
        (_) => Reply(
          periodDetailJson(
            periodJson('p1', 'Tokyo', incomeMinor: 90000, currency: 'JPY'),
          ),
        ),
      );
      final period = Period(
        id: 'p1',
        name: 'Tokyo',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        income: 0,
        currency: 'JPY',
      );

      final updated = await backend.repository().setPlan(
        period,
        income: 90000,
        plannedByCategory: {'c1': 5000},
      );

      expect(updated.income, 90000);
      expect(backend.sent('PUT /periods/p1/plan').single.body, {
        'version': 1,
        'incomeMinor': 90000, // yen have no minor unit
        'envelopes': [
          {'categoryId': 'c1', 'plannedMinor': 5000},
        ],
      });
    });

    test('summaries turn minor units into whole units', () async {
      backend.on(
        'GET /periods/summaries',
        (_) => Reply([
          {
            'period': periodJson('p1', 'July'),
            'plannedMinor': 40000,
            'spentMinor': 3550,
            'contributedMinor': 25000,
          },
        ]),
      );

      final summary = (await backend.repository().periodSummaries()).single;

      expect(summary.period.name, 'July');
      expect(summary.planned, 400);
      expect(summary.spent, 35.5);
      expect(summary.contributed, 250);
    });
  });

  group('progress', () {
    final period = Period(
      id: 'p1',
      name: 'July',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
      income: 5000,
    );

    test('joins the envelopes with their categories', () async {
      backend.on(
        'GET /periods/p1/progress',
        (_) => Reply(
          progressJson('p1', [
            envelopeProgressJson(
              'e1',
              'c1',
              plannedMinor: 10000,
              spentMinor: 12500,
            ),
            envelopeProgressJson('e2', 'ghost', plannedMinor: 1, spentMinor: 0),
          ]),
        ),
      );

      final progress = await backend.repository().categoryProgress(period, {
        'c1': const Category(id: 'c1', name: 'Food', color: '#22C55E'),
      });

      // the envelope of an unknown category is left out
      expect(progress, hasLength(1));
      expect(progress.single.category.name, 'Food');
      expect(progress.single.envelope.id, 'e1');
      expect(progress.single.planned, 100);
      expect(progress.single.spent, 125);
      expect(progress.single.isOverspent, isTrue);
    });

    test('adding an envelope plans nothing', () async {
      backend.on(
        'POST /periods/p1/envelopes',
        (_) => Reply({
          'id': 'e9',
          'periodId': 'p1',
          'categoryId': 'c9',
          'plannedMinor': 0,
          'createdAt': '2026-07-01T00:00:00.000Z',
          'updatedAt': '2026-07-01T00:00:00.000Z',
        }, status: 201),
      );

      final envelope = await backend.repository().addEnvelope(period, 'c9');

      expect(envelope.id, 'e9');
      expect(envelope.plannedAmount, 0);
      expect(backend.sent('POST /periods/p1/envelopes').single.body, {
        'categoryId': 'c9',
        'plannedMinor': 0,
      });
    });
  });

  group('expenses', () {
    final period = Period(
      id: 'p1',
      name: 'July',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
      income: 5000,
    );

    test('are read page by page until the last one', () async {
      final all = [
        for (var i = 0; i < 5; i++) expenseJson('x$i', 'e1', 100 + i),
      ];
      backend.on('GET /periods/p1/expenses', (request) {
        final offset = int.parse(request.query['offset']!);
        final limit = int.parse(request.query['limit']!);
        return Reply(all.skip(offset).take(limit).toList());
      });

      final expenses = await backend.repository(pageSize: 2).expenses(period);

      expect(expenses.map((e) => e.id), ['x0', 'x1', 'x2', 'x3', 'x4']);
      expect(backend.sent('GET /periods/p1/expenses'), hasLength(3));
    });

    test('can be narrowed to one envelope', () async {
      backend.on('GET /periods/p1/expenses', (_) => const Reply([]));

      await backend.repository().expenses(period, envelopeId: 'e7');

      expect(
        backend.sent('GET /periods/p1/expenses').single.query['envelopeId'],
        'e7',
      );
    });

    test(
      'become transactions with their category, others are dropped',
      () async {
        backend.on(
          'GET /periods/p1/expenses',
          (_) => Reply([
            expenseJson('x1', 'e1', 4599, note: 'Biedronka'),
            expenseJson('x2', 'gone', 100),
          ]),
        );

        final transactions = await backend.repository().transactions(period, {
          'e1': const Category(id: 'c1', name: 'Food', color: '#22C55E'),
        });

        expect(transactions, hasLength(1));
        expect(transactions.single.id, 'x1');
        expect(transactions.single.amount, 45.99);
        expect(transactions.single.note, 'Biedronka');
        expect(transactions.single.category.name, 'Food');
      },
    );

    test(
      'are created in the currency of the period, as a UTC instant',
      () async {
        backend.on(
          'POST /expenses',
          (_) => Reply(expenseJson('x1', 'e1', 4599), status: 201),
        );
        final date = DateTime.utc(2026, 7, 3, 10, 30);

        final created = await backend.repository().createExpense(
          Expense(envelopeId: 'e1', amount: 45.99, date: date, note: 'lunch'),
          'PLN',
        );

        expect(created.id, 'x1');
        expect(backend.sent('POST /expenses').single.body, {
          'envelopeId': 'e1',
          'amountMinor': 4599,
          'spentAt': '2026-07-03T10:30:00.000Z',
          'note': 'lunch',
        });
      },
    );

    test('keep what was paid in another currency when edited', () async {
      backend.on(
        'PUT /expenses/x1',
        (_) => Reply(expenseJson('x1', 'e1', 2000)),
      );
      final dollars = Expense(
        id: 'x1',
        envelopeId: 'e1',
        amount: 20,
        date: DateTime.utc(2026, 7, 3),
        originalAmount: 5,
        originalCurrency: 'USD',
      );

      await backend.repository().updateExpense(
        dollars.copyWith(note: 'changed'),
        'PLN',
      );

      final body = backend.sent('PUT /expenses/x1').single.body as Map;
      expect(body['original'], {'amountMinor': 500, 'currency': 'USD'});
      expect(body['note'], 'changed');
    });
  });

  group('recurring rules', () {
    test('a rule without an id is created, one with an id updated', () async {
      Map<String, Object?> ruleJson(String id) => {
        'id': id,
        'categoryId': 'c1',
        'amountMinor': 200000,
        'currency': 'PLN',
        'frequency': 'monthly',
        'note': 'Rent',
        'active': true,
        'createdAt': '2026-07-01T00:00:00.000Z',
        'updatedAt': '2026-07-01T00:00:00.000Z',
      };
      backend.on(
        'POST /recurring-rules',
        (_) => Reply(ruleJson('r1'), status: 201),
      );
      backend.on('PUT /recurring-rules/r1', (_) => Reply(ruleJson('r1')));
      final repository = backend.repository();

      final created = await repository.saveRecurringRule(
        const RecurringRule(
          categoryId: 'c1',
          amount: 2000,
          frequency: RecurrenceFrequency.monthly,
          note: 'Rent',
        ),
      );
      await repository.saveRecurringRule(created);

      expect(created.id, 'r1');
      expect(created.amount, 2000);
      expect(created.frequency, RecurrenceFrequency.monthly);
      expect(backend.sent('POST /recurring-rules'), hasLength(1));
      expect(backend.sent('PUT /recurring-rules/r1'), hasLength(1));
    });

    test('applying returns how many expenses were added', () async {
      backend.on(
        'POST /periods/p1/recurring/apply',
        (_) => const Reply({'added': 3}),
      );
      final period = Period(
        id: 'p1',
        name: 'July',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        income: 0,
      );

      expect(await backend.repository().applyRecurringRules(period), 3);
    });
  });

  group('csv', () {
    test('is exported as text', () async {
      backend.on(
        'GET /export.csv',
        (_) => const Reply('Period,Category\nJuly,Food\n'),
      );

      expect(
        await backend.repository().exportCsv(),
        'Period,Category\nJuly,Food\n',
      );
    });

    test('is imported as the raw file, not as JSON', () async {
      backend.on(
        'POST /import/csv',
        (_) => const Reply({'imported': 2, 'skipped': 1}),
      );
      const csv =
          'Period,Category,Amount,Date,Note\nJuly,Food,1.5,2026-07-03,"a, b"\n';

      final result = await backend.repository().importCsv(csv);

      expect(result, (imported: 2, skipped: 1));
      final sent = backend.sent('POST /import/csv').single;
      expect(sent.contentType, contains('text/csv'));
      expect(sent.body, csv);
    });
  });

  group('failures', () {
    test('each status says what went wrong', () async {
      final cases = {
        400: ApiFailure.invalid,
        404: ApiFailure.notFound,
        409: ApiFailure.conflict,
        422: ApiFailure.invalid,
        500: ApiFailure.server,
        503: ApiFailure.server,
      };
      for (final MapEntry(key: status, value: failure) in cases.entries) {
        backend.on('GET /categories', (_) => Reply(null, status: status));
        await expectLater(
          backend.repository().categories(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.failure, 'failure', failure)
                .having((e) => e.status, 'status', status),
          ),
          reason: 'status $status',
        );
      }
    });

    test('an unreachable server is its own failure', () async {
      backend.on('GET /categories', (_) => const Reply.unreachable());

      await expectLater(
        backend.repository().categories(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            ApiFailure.unreachable,
          ),
        ),
      );
    });

    test('the error tag is kept', () async {
      backend.on('GET /categories', (_) => Reply.error(409, 'SomethingElse'));

      await expectLater(
        backend.repository().categories(),
        throwsA(
          isA<ApiException>().having((e) => e.tag, 'tag', 'SomethingElse'),
        ),
      );
    });
  });
}
