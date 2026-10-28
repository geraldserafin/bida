import { randomUUID } from "node:crypto";
import {
  Allocation,
  type AllocationId,
  Envelope,
  type EnvelopeId,
  Expense,
  type ExpenseId,
  type ImportLegacy,
  Income,
  type IncomeId,
  InvalidImport,
  RecurringRule,
  type RecurringRuleId,
  type UserId,
} from "@bida/api-contract";
import { DateTime, Effect } from "effect";
import type { Snapshot } from "./transfer.repository.ts";

const DEFAULT_TIME_ZONE = "Europe/Warsaw";

/** zloty as a decimal (the old app used doubles) -> grosze */
const toMinor = (amount: number): number => Math.round(amount * 100);

const invalid = (reason: string) => new InvalidImport({ reason });

/**
 * Turns a backup of the offline app into a snapshot of the current data
 * model. Integer ids become uuids, a category becomes a top-level envelope, the
 * income of a period an income and what it planned for a category an
 * allocation (both dated at the start of the period), amounts become grosze
 * and the app's local timestamps are read in `timeZone`.
 */
export const convertLegacy = (
  input: ImportLegacy,
  userId: string,
  now: DateTime.Utc,
): Effect.Effect<Snapshot, InvalidImport> =>
  Effect.gen(function* () {
    const { data } = input.backup;
    const timeZone = input.timeZone ?? DEFAULT_TIME_ZONE;
    if (DateTime.zoneMakeNamed(timeZone) === undefined) {
      return yield* invalid(`unknown time zone "${timeZone}"`);
    }
    const owner = userId as UserId;

    const ids = <A extends { id: number }, Id>(rows: ReadonlyArray<A>) =>
      new Map(rows.map((row) => [row.id, randomUUID() as Id] as const));
    const envelopeIds = ids<(typeof data.categories)[number], EnvelopeId>(
      data.categories,
    );
    const ruleIds = ids<(typeof data.recurring_rules)[number], RecurringRuleId>(
      data.recurring_rules,
    );

    const lookup = <Id>(map: Map<number, Id>, id: number, what: string) => {
      const found = map.get(id);
      return found === undefined
        ? Effect.fail(invalid(`${what} ${id} does not exist`))
        : Effect.succeed(found);
    };

    const envelopes = data.categories.map(
      (row) =>
        new Envelope({
          id: envelopeIds.get(row.id) as EnvelopeId,
          ownerId: owner,
          parentId: null,
          name: row.name,
          color: row.color,
          icon: row.icon,
          createdAt: now,
          updatedAt: now,
        }),
    );

    const periodStart = new Map<number, string>();
    const incomes: Array<Income> = [];
    for (const row of data.periods) {
      const start = row.start_date.slice(0, 10);
      periodStart.set(row.id, start);
      const amountMinor = toMinor(row.income);
      if (amountMinor > 0) {
        incomes.push(
          new Income({
            id: randomUUID() as IncomeId,
            userId: owner,
            amountMinor,
            receivedOn: start,
            note: row.name,
            createdAt: now,
            updatedAt: now,
          }),
        );
      }
    }

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
          userId: owner,
          envelopeId: yield* lookup(envelopeIds, row.category_id, "category"),
          amountMinor: toMinor(row.amount),
          frequency: row.frequency,
          note: row.note,
          active: row.active === 1,
          createdAt: now,
          updatedAt: now,
        }),
      );
    }

    // a split is what a period planned for a category
    const allocations: Array<Allocation> = [];
    const envelopeOfSplit = new Map<number, EnvelopeId>();
    for (const row of data.splits) {
      const envelopeId = yield* lookup(
        envelopeIds,
        row.category_id,
        "category",
      );
      envelopeOfSplit.set(row.id, envelopeId);
      const start = periodStart.get(row.period_id);
      if (start === undefined) {
        return yield* invalid(`period ${row.period_id} does not exist`);
      }
      const amountMinor = toMinor(row.planned_amount);
      if (amountMinor > 0) {
        allocations.push(
          new Allocation({
            id: randomUUID() as AllocationId,
            envelopeId,
            userId: owner,
            amountMinor,
            madeOn: start,
            note: null,
            createdAt: now,
            updatedAt: now,
          }),
        );
      }
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
          envelopeId: yield* lookup(envelopeOfSplit, row.split_id, "split"),
          createdBy: owner,
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
      envelopes,
      allocations,
      incomes,
      expenses,
      recurringRules,
      recurringIncomes: [],
      allocationRules: [],
    };
  });
