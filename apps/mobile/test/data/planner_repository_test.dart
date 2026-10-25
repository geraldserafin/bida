import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/api_exception.dart';
import 'package:money_planner/models/models.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  final august = BudgetMonth(DateTime(2026, 8, 1), DateTime(2026, 8, 31));

  group('envelopes', () {
    test('lists and maps them, sub-envelopes with their parent', () async {
      backend.on(
        'GET /envelopes',
        (_) => Reply([
          envelopeJson('e1', 'Home', icon: 'home'),
          envelopeJson('e2', 'Rent', parentId: 'e1'),
        ]),
      );

      final envelopes = await backend.repository().envelopes();

      expect(envelopes.map((e) => e.name), ['Home', 'Rent']);
      expect(envelopes.first.icon, 'home');
      expect(envelopes.first.isTopLevel, isTrue);
      expect(envelopes.last.parentId, 'e1');
    });

    test('creating sends the look and the parent', () async {
      backend.on(
        'POST /envelopes',
        (_) => Reply(envelopeJson('e2', 'Rent', parentId: 'e1'), status: 201),
      );

      final created = await backend.repository().createEnvelope(
        const Envelope(
          parentId: 'e1',
          name: 'Rent',
          color: '#22C55E',
          icon: 'home',
        ),
      );

      expect(created.id, 'e2');
      expect(backend.sent('POST /envelopes').single.body, {
        'parentId': 'e1',
        'name': 'Rent',
        'color': '#22C55E',
        'icon': 'home',
      });
    });

    test('updating changes only how it looks', () async {
      backend.on(
        'PUT /envelopes/e1',
        (_) => Reply(envelopeJson('e1', 'House')),
      );

      await backend.repository().updateEnvelope(
        const Envelope(id: 'e1', name: 'House', color: '#22C55E'),
      );

      expect(backend.sent('PUT /envelopes/e1').single.body, {
        'name': 'House',
        'color': '#22C55E',
        'icon': null,
      });
    });

    test('deleting one that is gone is a failure', () async {
      backend.on(
        'DELETE /envelopes/e1',
        (_) => Reply.error(404, 'EnvelopeNotFound', {'id': 'e1'}),
      );

      expect(
        backend.repository().deleteEnvelope('e1'),
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

  group('overview', () {
    test('asks for the days of the month and converts to złoty', () async {
      backend.on(
        'GET /overview',
        (_) => Reply(
          overviewJson(
            income: 500000,
            allocated: 300000,
            spent: 4599,
            pool: 200000,
            envelopes: [
              figuresJson('e1', opening: 1000, allocated: 10000, spent: 4599),
            ],
          ),
        ),
      );
      const envelope = Envelope(id: 'e1', name: 'Food', color: '#22C55E');

      final overview = await backend.repository().overview(august, {
        'e1': envelope,
      });

      expect(backend.sent('GET /overview').single.query, {
        'from': '2026-08-01',
        'to': '2026-08-31',
      });
      expect(overview.income, 5000);
      expect(overview.allocated, 3000);
      expect(overview.spent, 45.99);
      expect(overview.pool, 2000);
      final food = overview.envelopes.single;
      expect(food.envelope, envelope);
      expect([food.opening, food.allocated, food.spent], [10, 100, 45.99]);
      expect(food.balance, closeTo(64.01, 0.001));
    });

    test('leaves out figures of envelopes it does not know', () async {
      backend.on(
        'GET /overview',
        (_) => Reply(overviewJson(envelopes: [figuresJson('gone')])),
      );

      final overview = await backend.repository().overview(august, {});

      expect(overview.envelopes, isEmpty);
    });

    test('the history lists the months with their totals', () async {
      backend.on(
        'GET /overview/months',
        (_) => Reply([
          monthSummaryJson(
            '2026-08-10',
            '2026-09-09',
            income: 100000,
            allocated: 60000,
            spent: 5000,
          ),
        ]),
      );

      final months = await backend.repository().months(firstDay: 10);

      expect(backend.sent('GET /overview/months').single.query, {
        'startDay': '10',
      });
      expect(months.single.month.from, DateTime(2026, 8, 10));
      expect(months.single.month.to, DateTime(2026, 9, 9));
      expect([months.single.income, months.single.allocated], [1000, 600]);
      expect(months.single.spent, 50);
    });
  });

  group('incomes', () {
    test('lists them newest first', () async {
      backend.on(
        'GET /incomes',
        (_) => Reply([incomeJson('i1', 500050, note: 'salary')]),
      );

      final incomes = await backend.repository().incomes();

      expect(incomes.single.amount, 5000.5);
      expect(incomes.single.receivedOn, DateTime(2026, 8, 1));
      expect(incomes.single.note, 'salary');
    });

    test('a new income is created, an existing one updated', () async {
      backend
        ..on('POST /incomes', (_) => Reply(incomeJson('i1', 100), status: 201))
        ..on('PUT /incomes/i1', (_) => Reply(incomeJson('i1', 250)));
      final repository = backend.repository();

      await repository.saveIncome(
        Income(amount: 1, receivedOn: DateTime(2026, 8, 1), note: 'x'),
      );
      await repository.saveIncome(
        Income(id: 'i1', amount: 2.5, receivedOn: DateTime(2026, 8, 2)),
      );

      expect(backend.sent('POST /incomes').single.body, {
        'amountMinor': 100,
        'receivedOn': '2026-08-01',
        'note': 'x',
      });
      expect(backend.sent('PUT /incomes/i1').single.body, {
        'amountMinor': 250,
        'receivedOn': '2026-08-02',
        'note': null,
      });
    });
  });

  group('allocations', () {
    test('lists what went into an envelope', () async {
      backend.on(
        'GET /allocations',
        (_) => Reply([
          allocationJson('a1', 'e1', 10000),
          allocationJson('a2', 'e1', -2500),
        ]),
      );

      final all = await backend.repository().allocations(envelopeId: 'e1');

      expect(backend.sent('GET /allocations').single.query, {
        'envelopeId': 'e1',
      });
      expect(all.map((a) => a.amount), [100, -25]);
    });

    test('taking money back sends a negative amount', () async {
      backend.on(
        'POST /allocations',
        (_) => Reply(allocationJson('a1', 'e1', -2500), status: 201),
      );

      await backend.repository().saveAllocation(
        Allocation(
          envelopeId: 'e1',
          amount: -25,
          madeOn: DateTime(2026, 8, 2),
          note: 'oops',
        ),
      );

      expect(backend.sent('POST /allocations').single.body, {
        'envelopeId': 'e1',
        'amountMinor': -2500,
        'madeOn': '2026-08-02',
        'note': 'oops',
      });
    });

    test('an envelope that does not have the money says how much it has', () {
      backend.on(
        'POST /allocations',
        (_) => Reply.error(409, 'NotEnoughMoney', {
          'envelopeId': 'e1',
          'availableMinor': 5000,
        }),
      );

      expect(
        backend.repository().saveAllocation(
          Allocation(
            envelopeId: 'e1',
            amount: -100,
            madeOn: DateTime(2026, 8, 2),
          ),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.failure, 'failure', ApiFailure.conflict)
              .having((e) => e.tag, 'tag', 'NotEnoughMoney')
              .having((e) => e.availableMinor, 'available', 5000),
        ),
      );
    });

    test('an existing allocation is updated by id', () async {
      backend.on(
        'PUT /allocations/a1',
        (_) => Reply(allocationJson('a1', 'e1', 3000)),
      );

      await backend.repository().saveAllocation(
        Allocation(
          id: 'a1',
          envelopeId: 'e1',
          amount: 30,
          madeOn: DateTime(2026, 8, 3),
        ),
      );

      expect(backend.sent('PUT /allocations/a1').single.body, {
        'amountMinor': 3000,
        'madeOn': '2026-08-03',
        'note': null,
      });
    });
  });

  group('expenses', () {
    test('lists the month by instants, from the first day to the day after '
        'the last', () async {
      backend.on(
        'GET /expenses',
        (_) => Reply([
          expenseJson('x1', 'e1', 4599, note: 'bread', recurringId: 'r1'),
        ]),
      );

      final expenses = await backend.repository().expenses(
        month: august,
        envelopeId: 'e1',
      );

      final query = backend.sent('GET /expenses').single.query;
      expect(query['envelopeId'], 'e1');
      expect(query['from'], DateTime(2026, 8, 1).toUtc().toIso8601String());
      expect(query['to'], DateTime(2026, 9, 1).toUtc().toIso8601String());
      expect(expenses.single.amount, 45.99);
      expect(expenses.single.note, 'bread');
      expect(expenses.single.recurringId, 'r1');
      expect(expenses.single.createdBy, 'u1');
      expect(expenses.single.date, DateTime.utc(2026, 8, 3, 10, 30).toLocal());
    });

    test('reads every page', () async {
      backend.on('GET /expenses', (request) {
        final offset = int.parse(request.query['offset']!);
        return Reply([
          for (var i = offset; i < (offset == 0 ? 2 : 3); i++)
            expenseJson('x$i', 'e1', 100),
        ]);
      });

      final all = await backend.repository(pageSize: 2).expenses();

      expect(all.map((e) => e.id), ['x0', 'x1', 'x2']);
      expect(backend.sent('GET /expenses'), hasLength(2));
    });

    test('transactions carry their envelope, unknown ones are left out', () {
      backend.on(
        'GET /expenses',
        (_) =>
            Reply([expenseJson('x1', 'e1', 100), expenseJson('x2', 'e9', 5)]),
      );
      const food = Envelope(id: 'e1', name: 'Food', color: '#22C55E');

      return backend.repository().transactions(august, {'e1': food}).then((t) {
        expect(t.map((x) => x.id), ['x1']);
        expect(t.single.envelope, food);
      });
    });

    test('creating and updating send grosze and an instant', () async {
      backend
        ..on(
          'POST /expenses',
          (_) => Reply(expenseJson('x1', 'e1', 4599), status: 201),
        )
        ..on('PUT /expenses/x1', (_) => Reply(expenseJson('x1', 'e2', 100)));
      final repository = backend.repository();
      final date = DateTime.utc(2026, 8, 3, 10, 30);

      await repository.createExpense(
        Expense(envelopeId: 'e1', amount: 45.99, date: date, note: 'bread'),
      );
      await repository.updateExpense(
        Expense(id: 'x1', envelopeId: 'e2', amount: 1, date: date),
      );

      expect(backend.sent('POST /expenses').single.body, {
        'envelopeId': 'e1',
        'amountMinor': 4599,
        'spentAt': '2026-08-03T10:30:00.000Z',
        'note': 'bread',
      });
      expect(backend.sent('PUT /expenses/x1').single.body, {
        'envelopeId': 'e2',
        'amountMinor': 100,
        'spentAt': '2026-08-03T10:30:00.000Z',
        'note': null,
      });
    });
  });

  group('recurring', () {
    test('rules are saved on an envelope', () async {
      backend
        ..on(
          'GET /recurring-rules',
          (_) => Reply([ruleJson('r1', 'e1', 99999)]),
        )
        ..on(
          'POST /recurring-rules',
          (_) => Reply(
            ruleJson('r2', 'e1', 5000, frequency: 'weekly'),
            status: 201,
          ),
        );
      final repository = backend.repository();

      final rules = await repository.recurringRules();
      await repository.saveRecurringRule(
        const RecurringRule(
          envelopeId: 'e1',
          amount: 50,
          frequency: RecurrenceFrequency.weekly,
        ),
      );

      expect(rules.single.amount, 999.99);
      expect(rules.single.envelopeId, 'e1');
      expect(backend.sent('POST /recurring-rules').single.body, {
        'envelopeId': 'e1',
        'amountMinor': 5000,
        'frequency': 'weekly',
        'note': null,
        'active': true,
      });
    });

    test('applying names the days of the month', () async {
      backend.on(
        'POST /recurring-rules/apply',
        (_) => const Reply({'added': 3}),
      );

      final added = await backend.repository().applyRecurringRules(august);

      expect(added, 3);
      expect(backend.sent('POST /recurring-rules/apply').single.body, {
        'from': '2026-08-01',
        'to': '2026-08-31',
      });
    });
  });

  group('data exchange', () {
    test('exports CSV as text and imports it as text', () async {
      backend
        ..on('GET /export.csv', (_) => const Reply('Envelope,Subenvelope\n'))
        ..on(
          'POST /import/csv',
          (_) => const Reply({'imported': 2, 'skipped': 1}),
        );
      final repository = backend.repository();

      expect(await repository.exportCsv(), contains('Envelope'));
      final result = await repository.importCsv('Envelope,Subenvelope\nA,\n');

      expect(result, (imported: 2, skipped: 1));
      expect(
        backend.sent('POST /import/csv').single.contentType,
        contains('text/csv'),
      );
    });

    test('the server is empty only without envelopes and income', () async {
      backend
        ..on('GET /envelopes', (_) => const Reply([]))
        ..on('GET /incomes', (_) => const Reply([]));
      expect(await backend.repository().isEmpty(), isTrue);

      backend.on('GET /incomes', (_) => Reply([incomeJson('i1', 100)]));
      expect(await backend.repository().isEmpty(), isFalse);
    });
  });
}
