import { randomUUID } from "node:crypto";
import {
  Category,
  type CategoryId,
  Envelope,
  type EnvelopeId,
  Expense,
  type ExpenseId,
  type ExportDocument,
  type ImportLegacy,
  InvalidImport,
  Period,
  type PeriodId,
  RecurringRule,
  type RecurringRuleId,
} from "@bida/api-contract";
import { DateTime, Effect } from "effect";

const DEFAULT_TIME_ZONE = "Europe/Warsaw";

/** zloty as a decimal (the old app used doubles) -> grosze */
const toMinor = (amount: number): number => Math.round(amount * 100);

const invalid = (reason: string) => new InvalidImport({ reason });

/**
 * Turns a backup of the offline app into a snapshot of the new data model.
 * Integer ids become uuids, `splits` become envelopes, amounts become grosze
 * and the app's local timestamps are read in `timeZone`.
 */
export const convertLegacy = (
  input: ImportLegacy,
  now: DateTime.Utc,
): Effect.Effect<Omit<ExportDocument, "exportedAt">, InvalidImport> =>
  Effect.gen(function* () {
    const { data } = input.backup;
    const timeZone = input.timeZone ?? DEFAULT_TIME_ZONE;
    if (DateTime.zoneMakeNamed(timeZone) === undefined) {
      return yield* invalid(`unknown time zone "${timeZone}"`);
    }

    const ids = <A extends { id: number }, Id>(rows: ReadonlyArray<A>) =>
      new Map(rows.map((row) => [row.id, randomUUID() as Id] as const));
    const categoryIds = ids<(typeof data.categories)[number], CategoryId>(
      data.categories,
    );
    const periodIds = ids<(typeof data.periods)[number], PeriodId>(
      data.periods,
    );
    const ruleIds = ids<(typeof data.recurring_rules)[number], RecurringRuleId>(
      data.recurring_rules,
    );
    const envelopeIds = ids<(typeof data.splits)[number], EnvelopeId>(
      data.splits,
    );

    const lookup = <Id>(map: Map<number, Id>, id: number, what: string) => {
      const found = map.get(id);
      return found === undefined
        ? Effect.fail(invalid(`${what} ${id} does not exist`))
        : Effect.succeed(found);
    };

    const categories = data.categories.map(
      (row) =>
        new Category({
          id: categoryIds.get(row.id) as CategoryId,
          name: row.name,
          color: row.color,
          icon: row.icon,
          createdAt: now,
          updatedAt: now,
        }),
    );

    const periods = data.periods.map(
      (row) =>
        new Period({
          id: periodIds.get(row.id) as PeriodId,
          name: row.name,
          startDate: row.start_date.slice(0, 10),
          endDate: row.end_date.slice(0, 10),
          incomeMinor: toMinor(row.income),
          createdAt: now,
          updatedAt: now,
        }),
    );

    const recurringRules: Array<RecurringRule> = [];
    for (const row of data.recurring_rules) {
      if (row.frequency !== "weekly" && row.frequency !== "monthly") {
        return yield* invalid(
          `recurring rule ${row.id} has frequency "${row.frequency}"`,
        );
      }
      recurringRules.push(
        new RecurringRule({
          id: ruleIds.get(row.id) as RecurringRuleId,
          categoryId: yield* lookup(categoryIds, row.category_id, "category"),
          amountMinor: toMinor(row.amount),
          frequency: row.frequency,
          note: row.note,
          active: row.active === 1,
          createdAt: now,
          updatedAt: now,
        }),
      );
    }

    const envelopes: Array<Envelope> = [];
    const periodOfEnvelope = new Map<number, PeriodId>();
    for (const row of data.splits) {
      const periodId = yield* lookup(periodIds, row.period_id, "period");
      periodOfEnvelope.set(row.id, periodId);
      envelopes.push(
        new Envelope({
          id: envelopeIds.get(row.id) as EnvelopeId,
          periodId,
          categoryId: yield* lookup(categoryIds, row.category_id, "category"),
          plannedMinor: toMinor(row.planned_amount),
          createdAt: now,
          updatedAt: now,
        }),
      );
    }

    const expenses: Array<Expense> = [];
    for (const row of data.expenses) {
      const amountMinor = toMinor(row.amount);
      if (amountMinor <= 0) {
        return yield* invalid(`expense ${row.id} has a non-positive amount`);
      }
      const zoned = yield* Effect.try({
        try: () =>
          DateTime.makeZonedUnsafe(row.date, {
            timeZone,
            adjustForTimeZone: true,
          }),
        catch: () =>
          invalid(`expense ${row.id} has an invalid date "${row.date}"`),
      });
      expenses.push(
        new Expense({
          id: randomUUID() as ExpenseId,
          envelopeId: yield* lookup(envelopeIds, row.split_id, "split"),
          periodId: periodOfEnvelope.get(row.split_id) as PeriodId,
          amountMinor,
          spentAt: DateTime.toUtc(zoned),
          note: row.note,
          recurringId:
            row.recurring_id === null
              ? null
              : yield* lookup(ruleIds, row.recurring_id, "recurring rule"),
          createdAt: now,
          updatedAt: now,
        }),
      );
    }

    return {
      version: 1 as const,
      categories,
      periods,
      envelopes,
      expenses,
      recurringRules,
    };
  });
