import 'package:bida_api_client/bida_api_client.dart' as api;
import 'package:intl/intl.dart';

import '../models/models.dart';
import 'money.dart';

// Translation between the API's types and the app's models: ids stay strings,
// amounts go between grosze and złoty, dates between `YYYY-MM-DD` (a calendar
// day) or an ISO instant and a [DateTime].

final _day = DateFormat('yyyy-MM-dd');

String formatDay(DateTime date) => _day.format(date);

/// A calendar day from the API, as local midnight.
DateTime parseDay(String day) => DateTime.parse(day);

// ------------------------------------------------------------------- envelopes

Envelope envelopeFrom(api.Envelope e) => Envelope(
  id: e.id,
  parentId: e.parentId,
  name: e.name,
  color: e.color,
  icon: e.icon,
);

api.CreateEnvelope createEnvelopeOf(Envelope e) => api.CreateEnvelope(
  parentId: e.parentId,
  name: e.name,
  color: e.color,
  icon: e.icon,
);

api.UpdateEnvelope updateEnvelopeOf(Envelope e) =>
    api.UpdateEnvelope(name: e.name, color: e.color, icon: e.icon);

EnvelopeProgress progressFrom(api.EnvelopeFigures f, Envelope envelope) =>
    EnvelopeProgress(
      envelope: envelope,
      opening: fromMinor(f.openingMinor),
      allocated: fromMinor(f.allocatedMinor),
      spent: fromMinor(f.spentMinor),
      balance: fromMinor(f.balanceMinor),
      free: fromMinor(f.freeMinor),
      role: roleFrom(f.role),
      memberCount: f.memberCount,
    );

// ----------------------------------------------------------------- allocations

Allocation allocationFrom(api.Allocation a) => Allocation(
  id: a.id,
  envelopeId: a.envelopeId,
  userId: a.userId,
  amount: fromMinor(a.amountMinor),
  madeOn: parseDay(a.madeOn),
  note: a.note,
);

api.CreateAllocation createAllocationOf(Allocation a) => api.CreateAllocation(
  envelopeId: a.envelopeId,
  amountMinor: toMinor(a.amount),
  madeOn: formatDay(a.madeOn),
  note: a.note,
);

api.UpdateAllocation updateAllocationOf(Allocation a) => api.UpdateAllocation(
  amountMinor: toMinor(a.amount),
  madeOn: formatDay(a.madeOn),
  note: a.note,
);

// --------------------------------------------------------------------- incomes

Income incomeFrom(api.Income i) => Income(
  id: i.id,
  amount: fromMinor(i.amountMinor),
  receivedOn: parseDay(i.receivedOn),
  note: i.note,
);

api.SaveIncome saveIncomeOf(Income i) => api.SaveIncome(
  amountMinor: toMinor(i.amount),
  receivedOn: formatDay(i.receivedOn),
  note: i.note,
);

// -------------------------------------------------------------------- expenses

Expense expenseFrom(api.Expense e) => Expense(
  id: e.id,
  envelopeId: e.envelopeId,
  amount: fromMinor(e.amountMinor),
  date: DateTime.parse(e.spentAt).toLocal(),
  note: e.note,
  recurringId: e.recurringId,
  createdBy: e.createdBy,
);

api.CreateExpense createExpenseOf(Expense e) => api.CreateExpense(
  envelopeId: e.envelopeId,
  amountMinor: toMinor(e.amount),
  spentAt: e.date.toUtc().toIso8601String(),
  note: e.note,
);

api.UpdateExpense updateExpenseOf(Expense e) => api.UpdateExpense(
  envelopeId: e.envelopeId,
  amountMinor: toMinor(e.amount),
  spentAt: e.date.toUtc().toIso8601String(),
  note: e.note,
);

// ------------------------------------------------------------------- recurring

RecurringRule ruleFrom(api.RecurringRule r) => RecurringRule(
  id: r.id,
  envelopeId: r.envelopeId,
  amount: fromMinor(r.amountMinor),
  frequency: switch (r.frequency) {
    api.RecurringRuleFrequency.weekly => RecurrenceFrequency.weekly,
    _ => RecurrenceFrequency.monthly,
  },
  note: r.note,
  active: r.active,
);

api.SaveRecurringRule saveRuleOf(RecurringRule r) => api.SaveRecurringRule(
  envelopeId: r.envelopeId,
  amountMinor: toMinor(r.amount),
  frequency: switch (r.frequency) {
    RecurrenceFrequency.weekly => api.SaveRecurringRuleFrequency.weekly,
    RecurrenceFrequency.monthly => api.SaveRecurringRuleFrequency.monthly,
  },
  note: r.note,
  active: r.active,
);

// --------------------------------------------------------------------- sharing

EnvelopeRole roleFrom(api.Role role) => switch (role) {
  api.Role.owner => EnvelopeRole.owner,
  _ => EnvelopeRole.member,
};

api.Role roleOf(EnvelopeRole role) => switch (role) {
  EnvelopeRole.owner => api.Role.owner,
  EnvelopeRole.member => api.Role.member,
};

Member memberFrom(api.Member m) => Member(
  userId: m.userId,
  email: m.email,
  name: m.name,
  role: roleFrom(m.role),
);

Contribution contributionFrom(api.Contribution c) => Contribution(
  envelopeId: c.envelopeId,
  userId: c.userId,
  amount: fromMinor(c.amountMinor),
);

Invitation invitationFrom(api.Invitation i) {
  final by = i.invitedBy;
  return Invitation(
    id: i.id,
    envelopeId: i.envelopeId,
    envelopeName: i.envelopeName,
    email: i.email,
    role: roleFrom(i.role),
    status: switch (i.status) {
      api.InvitationStatus.accepted => InvitationStatus.accepted,
      _ => InvitationStatus.invited,
    },
    invitedBy: by == null ? null : (by.name ?? by.email),
  );
}
