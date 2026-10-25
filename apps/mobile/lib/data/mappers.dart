import 'package:bida_api_client/bida_api_client.dart' as api;
import 'package:intl/intl.dart';

import '../models/models.dart';
import 'money.dart';

// Translation between the API's types and the app's models: ids stay strings,
// amounts go between minor units and whole units, dates between `YYYY-MM-DD`
// (a calendar day) or an ISO instant and a [DateTime].

final _day = DateFormat('yyyy-MM-dd');

String formatDay(DateTime date) => _day.format(date);

/// A calendar day from the API, as local midnight.
DateTime parseDay(String day) => DateTime.parse(day);

String currencyCode(api.Currency currency) =>
    currency.json ?? Period.defaultCurrency;

api.Currency currencyOf(String code) => api.Currency.fromJson(code);

// ------------------------------------------------------------------ categories

Category categoryFrom(api.Category c) =>
    Category(id: c.id, name: c.name, color: c.color, icon: c.icon);

api.CreateCategory createCategoryOf(Category c) =>
    api.CreateCategory(name: c.name, color: c.color, icon: c.icon);

api.UpdateCategory updateCategoryOf(Category c) =>
    api.UpdateCategory(name: c.name, color: c.color, icon: c.icon);

// --------------------------------------------------------------------- periods

Period periodFrom(api.Period p) {
  final currency = currencyCode(p.currency);
  return Period(
    id: p.id,
    name: p.name,
    startDate: parseDay(p.startDate),
    endDate: parseDay(p.endDate),
    income: fromMinor(p.incomeMinor, currency),
    currency: currency,
    version: p.version,
  );
}

List<api.EnvelopePlan> envelopePlansOf(
  Map<String, double> plannedByCategory,
  String currency,
) => [
  for (final entry in plannedByCategory.entries)
    api.EnvelopePlan(
      categoryId: entry.key,
      plannedMinor: toMinor(entry.value, currency),
    ),
];

// ------------------------------------------------------------------- envelopes

Envelope envelopeFrom(
  api.EnvelopeProgress row,
  String periodId,
  String currency,
) => Envelope(
  id: row.envelopeId,
  periodId: periodId,
  categoryId: row.categoryId,
  plannedAmount: fromMinor(row.plannedMinor, currency),
);

// -------------------------------------------------------------------- expenses

Expense expenseFrom(api.Expense e, String currency) => Expense(
  id: e.id,
  envelopeId: e.envelopeId,
  amount: fromMinor(e.amountMinor, currency),
  date: DateTime.parse(e.spentAt).toLocal(),
  note: e.note,
  recurringId: e.recurringId,
  createdBy: e.createdBy,
  originalAmount: e.originalAmountMinor == null || e.originalCurrency == null
      ? null
      : fromMinor(e.originalAmountMinor!, currencyCode(e.originalCurrency!)),
  originalCurrency: e.originalCurrency == null
      ? null
      : currencyCode(e.originalCurrency!),
);

api.OriginalAmount? originalOf(Expense e) {
  final amount = e.originalAmount;
  final code = e.originalCurrency;
  if (amount == null || code == null) return null;
  return api.OriginalAmount(
    amountMinor: toMinor(amount, code),
    currency: currencyOf(code),
  );
}

api.CreateExpense createExpenseOf(Expense e, String currency) =>
    api.CreateExpense(
      envelopeId: e.envelopeId,
      amountMinor: toMinor(e.amount, currency),
      spentAt: e.date.toUtc().toIso8601String(),
      note: e.note,
      original: originalOf(e),
    );

api.UpdateExpense updateExpenseOf(Expense e, String currency) =>
    api.UpdateExpense(
      envelopeId: e.envelopeId,
      amountMinor: toMinor(e.amount, currency),
      spentAt: e.date.toUtc().toIso8601String(),
      note: e.note,
      original: originalOf(e),
    );

// ------------------------------------------------------------------- recurring

RecurringRule ruleFrom(api.RecurringRule r) {
  final currency = currencyCode(r.currency);
  return RecurringRule(
    id: r.id,
    categoryId: r.categoryId,
    amount: fromMinor(r.amountMinor, currency),
    currency: currency,
    frequency: switch (r.frequency) {
      api.RecurringRuleFrequency.weekly => RecurrenceFrequency.weekly,
      _ => RecurrenceFrequency.monthly,
    },
    note: r.note,
    active: r.active,
  );
}

api.SaveRecurringRule saveRuleOf(RecurringRule r) => api.SaveRecurringRule(
  categoryId: r.categoryId,
  amountMinor: toMinor(r.amount, r.currency),
  currency: currencyOf(r.currency),
  frequency: switch (r.frequency) {
    RecurrenceFrequency.weekly => api.SaveRecurringRuleFrequency.weekly,
    RecurrenceFrequency.monthly => api.SaveRecurringRuleFrequency.monthly,
  },
  note: r.note,
  active: r.active,
);
