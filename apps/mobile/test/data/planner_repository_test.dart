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
            ruleJson('r2', 'e1', 5000),
            status: 201,
          ),
        );
      final repository = backend.repository();

      final rules = await repository.recurringRules();
      await repository.saveRecurringRule(
        const RecurringRule(envelopeId: 'e1', amount: 50),
      );

      expect(rules.single.amount, 999.99);
      expect(rules.single.envelopeId, 'e1');
      expect(backend.sent('POST /recurring-rules').single.body, {
        'envelopeId': 'e1',
        'amountMinor': 5000,
        'frequency': 'monthly',
        'note': null,
        'active': true,
      });
    });

    test(
      'applying names the days of the month and counts what it added',
      () async {
        backend.on(
          'POST /recurring-rules/apply',
          (_) => const Reply({
            'incomes': 1,
            'allocations': 2,
            'expenses': 3,
            'skipped': 1,
          }),
        );

        final outcome = await backend.repository().applyRecurringRules(august);

        expect(
          [
            outcome.incomes,
            outcome.allocations,
            outcome.expenses,
            outcome.skipped,
          ],
          [1, 2, 3, 1],
        );
        expect(outcome.added, 6);
        expect(backend.sent('POST /recurring-rules/apply').single.body, {
          'from': '2026-08-01',
          'to': '2026-08-31',
        });
      },
    );

    test('what is pending is asked by the same days', () async {
      backend.on(
        'GET /recurring-rules/pending',
        (_) => const Reply({
          'incomes': 1,
          'allocations': 0,
          'expenses': 0,
          'skipped': 0,
        }),
      );

      final pending = await backend.repository().pendingRecurring(august);

      expect(pending.incomes, 1);
      expect(backend.sent('GET /recurring-rules/pending').single.query, {
        'from': '2026-08-01',
        'to': '2026-08-31',
      });
    });

    test('recurring incomes are saved with their day', () async {
      backend
        ..on(
          'GET /recurring-incomes',
          (_) => Reply([recurringIncomeJson('r1', 500050, 10, note: 'salary')]),
        )
        ..on(
          'POST /recurring-incomes',
          (_) => Reply(recurringIncomeJson('r2', 100, 1), status: 201),
        )
        ..on(
          'PUT /recurring-incomes/r1',
          (_) => Reply(recurringIncomeJson('r1', 200, 2)),
        );
      final repository = backend.repository();

      final rules = await repository.recurringIncomes();
      await repository.saveRecurringIncome(
        const RecurringIncome(amount: 1, dayOfMonth: 1),
      );
      await repository.saveRecurringIncome(
        const RecurringIncome(
          id: 'r1',
          amount: 2,
          dayOfMonth: 2,
          active: false,
        ),
      );

      expect(rules.single.amount, 5000.5);
      expect(rules.single.dayOfMonth, 10);
      expect(backend.sent('POST /recurring-incomes').single.body, {
        'amountMinor': 100,
        'dayOfMonth': 1,
        'note': null,
        'active': true,
      });
      expect(backend.sent('PUT /recurring-incomes/r1').single.body, {
        'amountMinor': 200,
        'dayOfMonth': 2,
        'note': null,
        'active': false,
      });
    });

    test('allocation rules go to an envelope', () async {
      backend
        ..on(
          'GET /allocation-rules',
          (_) => Reply([allocationRuleJson('a1', 'e1', 100000, 5)]),
        )
        ..on(
          'POST /allocation-rules',
          (_) => Reply(allocationRuleJson('a2', 'e1', 100, 1), status: 201),
        )
        ..on(
          'DELETE /allocation-rules/a1',
          (_) => const Reply(null, status: 204),
        );
      final repository = backend.repository();

      final rules = await repository.allocationRules();
      await repository.saveAllocationRule(
        const AllocationRule(envelopeId: 'e1', amount: 1, dayOfMonth: 1),
      );
      await repository.deleteAllocationRule('a1');

      expect(rules.single.envelopeId, 'e1');
      expect(rules.single.amount, 1000);
      expect(backend.sent('POST /allocation-rules').single.body, {
        'envelopeId': 'e1',
        'amountMinor': 100,
        'dayOfMonth': 1,
        'note': null,
        'active': true,
      });
      expect(backend.sent('DELETE /allocation-rules/a1'), hasLength(1));
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

  group('sharing', () {
    test('lists the members with their roles', () async {
      backend.on(
        'GET /envelopes/e1/members',
        (_) => Reply([
          memberJson('u1', 'ann@example.com', name: 'Ann', role: 'owner'),
          memberJson('u2', 'bob@example.com'),
        ]),
      );

      final members = await backend.repository().members('e1');

      expect(members.map((m) => m.displayName), ['Ann', 'bob@example.com']);
      expect(members.map((m) => m.role), [
        EnvelopeRole.owner,
        EnvelopeRole.member,
      ]);
    });

    test('changes a role and removes a member', () async {
      backend
        ..on(
          'PUT /envelopes/e1/members/u2',
          (_) => Reply(memberJson('u2', 'bob@example.com', role: 'owner')),
        )
        ..on(
          'DELETE /envelopes/e1/members/u2',
          (_) => const Reply(null, status: 204),
        );
      final repository = backend.repository();

      await repository.setRole('e1', 'u2', EnvelopeRole.owner);
      await repository.removeMember('e1', 'u2');

      expect(backend.sent('PUT /envelopes/e1/members/u2').single.body, {
        'role': 'owner',
      });
      expect(backend.sent('DELETE /envelopes/e1/members/u2'), hasLength(1));
    });

    test('the last owner cannot leave', () {
      backend.on(
        'DELETE /envelopes/e1/members/u1',
        (_) => Reply.error(409, 'LastOwner'),
      );

      expect(
        backend.repository().removeMember('e1', 'u1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.failure, 'failure', ApiFailure.conflict)
              .having((e) => e.tag, 'tag', 'LastOwner'),
        ),
      );
    });

    test('contributions are in złoty', () async {
      backend.on(
        'GET /envelopes/e1/contributions',
        (_) => Reply([
          contributionJson('e1', 'u1', 60000),
          contributionJson('e2', 'u2', 5050),
        ]),
      );

      final all = await backend.repository().contributions('e1');

      expect(all.map((c) => (c.envelopeId, c.userId, c.amount)), [
        ('e1', 'u1', 600.0),
        ('e2', 'u2', 50.5),
      ]);
    });

    test('inviting sends the address and the role', () async {
      backend.on(
        'POST /envelopes/e1/invitations',
        (_) =>
            Reply(invitationJson('i1', 'e1', 'bob@example.com'), status: 201),
      );

      final invitation = await backend.repository().invite(
        'e1',
        email: 'bob@example.com',
        role: EnvelopeRole.member,
      );

      expect(invitation.id, 'i1');
      expect(invitation.status, InvitationStatus.invited);
      expect(invitation.invitedBy, 'ann@example.com');
      expect(backend.sent('POST /envelopes/e1/invitations').single.body, {
        'email': 'bob@example.com',
        'role': 'member',
      });
    });

    test('an invitation is answered, approved and revoked by id', () async {
      backend
        ..on(
          'POST /invitations/i1/accept',
          (_) => Reply(
            invitationJson('i1', 'e1', 'bob@example.com', status: 'accepted'),
          ),
        )
        ..on(
          'POST /invitations/i2/decline',
          (_) => const Reply(null, status: 204),
        )
        ..on(
          'POST /envelopes/e1/invitations/i1/approve',
          (_) => Reply(memberJson('u2', 'bob@example.com')),
        )
        ..on(
          'DELETE /envelopes/e1/invitations/i3',
          (_) => const Reply(null, status: 204),
        );
      final repository = backend.repository();

      await repository.acceptInvitation('i1');
      await repository.declineInvitation('i2');
      await repository.approveInvitation('e1', 'i1');
      await repository.revokeInvitation('e1', 'i3');

      expect(backend.sent('POST /invitations/i1/accept'), hasLength(1));
      expect(backend.sent('POST /invitations/i2/decline'), hasLength(1));
      expect(
        backend.sent('POST /envelopes/e1/invitations/i1/approve'),
        hasLength(1),
      );
      expect(backend.sent('DELETE /envelopes/e1/invitations/i3'), hasLength(1));
    });

    test('lists the invitations for me and for an envelope', () async {
      backend
        ..on(
          'GET /invitations',
          (_) => Reply([invitationJson('i1', 'e1', 'me@example.com')]),
        )
        ..on(
          'GET /envelopes/e1/invitations',
          (_) => Reply([
            invitationJson(
              'i2',
              'e1',
              'cid@example.com',
              status: 'accepted',
              invitedBy: null,
            ),
          ]),
        );
      final repository = backend.repository();

      final mine = await repository.myInvitations();
      final open = await repository.envelopeInvitations('e1');

      expect(mine.single.envelopeName, 'Home');
      expect(open.single.status, InvitationStatus.accepted);
      expect(open.single.invitedBy, isNull);
    });
  });

  group('overview of a shared envelope', () {
    test('carries the role and the number of people', () async {
      backend.on(
        'GET /overview',
        (_) => Reply(
          overviewJson(
            envelopes: [figuresJson('e1', role: 'member', memberCount: 3)],
          ),
        ),
      );
      const home = Envelope(id: 'e1', name: 'Home', color: '#22C55E');

      final overview = await backend.repository().overview(august, {
        'e1': home,
      });

      final progress = overview.envelopes.single;
      expect(progress.role, EnvelopeRole.member);
      expect(progress.isOwner, isFalse);
      expect(progress.memberCount, 3);
      expect(progress.isShared, isTrue);
    });
  });
}
