import {
  AllocationRule,
  type AllocationRuleId,
  AllocationRuleNotFound,
  type ApplyRecurring,
  type ApplyResult,
  type EnvelopeNotFound,
  RecurringIncome,
  type RecurringIncomeId,
  RecurringIncomeNotFound,
  RecurringRule,
  type RecurringRuleId,
  RecurringRuleNotFound,
  type SaveAllocationRule,
  type SaveRecurringIncome,
  type SaveRecurringRule,
  type UserId,
} from "@bida/api-contract";
import { Context, DateTime, Effect, Layer, Option } from "effect";
import { SqlClient } from "effect/sql";
import { EnvelopesService } from "../envelopes/envelopes.module.ts";
import { ExpensesService } from "../expenses/expenses.module.ts";
import { IncomesService } from "../incomes/incomes.module.ts";
import { RecurringRepository } from "./recurring.repository.ts";
import {
  AllocationRulesRepository,
  RecurringIncomesRepository,
} from "./rules.repository.ts";

const DAY = 24 * 60 * 60 * 1000;

/**
 * The first day of the stretch that falls on the day of the month. Rules are
 * on the 1st to the 28th and a stretch is at least 28 days, so there is one.
 */
const dayIn = (from: string, to: string, dayOfMonth: number): string => {
  const end = Date.parse(`${to}T00:00:00Z`);
  for (let t = Date.parse(`${from}T00:00:00Z`); t <= end; t += DAY) {
    if (new Date(t).getUTCDate() === dayOfMonth) {
      return new Date(t).toISOString().slice(0, 10);
    }
  }
  return from;
};

/** Business rules for recurring expenses, recurring income and allocation rules. */
export class RecurringService extends Context.Service<
  RecurringService,
  {
    list(userId: UserId): Effect.Effect<ReadonlyArray<RecurringRule>>;
    create(
      userId: UserId,
      input: SaveRecurringRule,
    ): Effect.Effect<RecurringRule, EnvelopeNotFound>;
    update(
      userId: UserId,
      id: RecurringRuleId,
      input: SaveRecurringRule,
    ): Effect.Effect<RecurringRule, RecurringRuleNotFound | EnvelopeNotFound>;
    remove(
      userId: UserId,
      id: RecurringRuleId,
    ): Effect.Effect<void, RecurringRuleNotFound>;

    listIncomes(userId: UserId): Effect.Effect<ReadonlyArray<RecurringIncome>>;
    createIncome(
      userId: UserId,
      input: SaveRecurringIncome,
    ): Effect.Effect<RecurringIncome>;
    updateIncome(
      userId: UserId,
      id: RecurringIncomeId,
      input: SaveRecurringIncome,
    ): Effect.Effect<RecurringIncome, RecurringIncomeNotFound>;
    removeIncome(
      userId: UserId,
      id: RecurringIncomeId,
    ): Effect.Effect<void, RecurringIncomeNotFound>;

    listAllocationRules(
      userId: UserId,
    ): Effect.Effect<ReadonlyArray<AllocationRule>>;
    createAllocationRule(
      userId: UserId,
      input: SaveAllocationRule,
    ): Effect.Effect<AllocationRule, EnvelopeNotFound>;
    updateAllocationRule(
      userId: UserId,
      id: AllocationRuleId,
      input: SaveAllocationRule,
    ): Effect.Effect<AllocationRule, AllocationRuleNotFound | EnvelopeNotFound>;
    removeAllocationRule(
      userId: UserId,
      id: AllocationRuleId,
    ): Effect.Effect<void, AllocationRuleNotFound>;

    /** What applying would add for the stretch. Changes nothing. */
    pending(userId: UserId, input: ApplyRecurring): Effect.Effect<ApplyResult>;
    /** Adds incomes, then allocations, then expenses; see `ApplyResult`. */
    apply(userId: UserId, input: ApplyRecurring): Effect.Effect<ApplyResult>;
  }
>()("bida/recurring/RecurringService") {
  static readonly layer = Layer.effect(
    RecurringService,
    Effect.gen(function* () {
      const repo = yield* RecurringRepository;
      const incomeRules = yield* RecurringIncomesRepository;
      const allocationRules = yield* AllocationRulesRepository;
      const envelopes = yield* EnvelopesService;
      const expenses = yield* ExpensesService;
      const incomes = yield* IncomesService;
      const sql = yield* SqlClient.SqlClient;

      // ---- recurring expenses ------------------------------------------------

      const create = Effect.fn("RecurringService.create")(function* (
        userId: UserId,
        input: SaveRecurringRule,
      ) {
        yield* envelopes.access(userId, input.envelopeId);
        const row = yield* RecurringRule.insert
          .makeEffect({ ...input, userId })
          .pipe(Effect.orDie);
        return yield* repo.insert(row);
      });

      const update = Effect.fn("RecurringService.update")(function* (
        userId: UserId,
        id: RecurringRuleId,
        input: SaveRecurringRule,
      ) {
        yield* envelopes.access(userId, input.envelopeId);
        const updated = yield* repo.update(userId, id, input);
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new RecurringRuleNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const remove = Effect.fn("RecurringService.remove")(function* (
        userId: UserId,
        id: RecurringRuleId,
      ) {
        if (!(yield* repo.remove(userId, id))) {
          return yield* new RecurringRuleNotFound({ id });
        }
      });

      // ---- recurring incomes -------------------------------------------------

      const createIncome = Effect.fn("RecurringService.createIncome")(
        function* (userId: UserId, input: SaveRecurringIncome) {
          const row = yield* RecurringIncome.insert
            .makeEffect({ ...input, userId })
            .pipe(Effect.orDie);
          return yield* incomeRules.insert(row);
        },
      );

      const updateIncome = Effect.fn("RecurringService.updateIncome")(
        function* (
          userId: UserId,
          id: RecurringIncomeId,
          input: SaveRecurringIncome,
        ) {
          const updated = yield* incomeRules.update(userId, id, input);
          return yield* Option.match(updated, {
            onNone: () => Effect.fail(new RecurringIncomeNotFound({ id })),
            onSome: Effect.succeed,
          });
        },
      );

      const removeIncome = Effect.fn("RecurringService.removeIncome")(
        function* (userId: UserId, id: RecurringIncomeId) {
          if (!(yield* incomeRules.remove(userId, id))) {
            return yield* new RecurringIncomeNotFound({ id });
          }
        },
      );

      // ---- allocation rules --------------------------------------------------

      const createAllocationRule = Effect.fn(
        "RecurringService.createAllocationRule",
      )(function* (userId: UserId, input: SaveAllocationRule) {
        yield* envelopes.access(userId, input.envelopeId);
        const row = yield* AllocationRule.insert
          .makeEffect({ ...input, userId })
          .pipe(Effect.orDie);
        return yield* allocationRules.insert(row);
      });

      const updateAllocationRule = Effect.fn(
        "RecurringService.updateAllocationRule",
      )(function* (
        userId: UserId,
        id: AllocationRuleId,
        input: SaveAllocationRule,
      ) {
        yield* envelopes.access(userId, input.envelopeId);
        const updated = yield* allocationRules.update(userId, id, input);
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new AllocationRuleNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const removeAllocationRule = Effect.fn(
        "RecurringService.removeAllocationRule",
      )(function* (userId: UserId, id: AllocationRuleId) {
        if (!(yield* allocationRules.remove(userId, id))) {
          return yield* new AllocationRuleNotFound({ id });
        }
      });

      // ---- applying ----------------------------------------------------------

      /** The active rules that have not been applied to the stretch yet. */
      const open = Effect.fn("RecurringService.open")(function* (
        userId: UserId,
        from: string,
      ) {
        const [incomeList, allocationList, expenseList] = yield* Effect.all([
          incomeRules.list(userId),
          allocationRules.list(userId),
          repo.list(userId),
        ]);
        // oldest first, so the entries come out in the order they were made
        const active = <A extends { readonly active: boolean }>(
          rules: ReadonlyArray<A>,
        ) => rules.filter((rule) => rule.active).reverse();
        const incomeActive = active(incomeList);
        const allocationActive = active(allocationList);
        const expenseActive = active(expenseList);
        const [incomeDone, allocationDone, expenseDone] = yield* Effect.all([
          incomes.appliedRuleIds(
            incomeActive.map((rule) => rule.id),
            from,
          ),
          envelopes.appliedRuleIds(
            allocationActive.map((rule) => rule.id),
            from,
          ),
          expenses.appliedRecurringIds(
            expenseActive.map((rule) => rule.id),
            from,
          ),
        ]);
        return {
          incomes: incomeActive.filter((rule) => !incomeDone.has(rule.id)),
          allocations: allocationActive.filter(
            (rule) => !allocationDone.has(rule.id),
          ),
          expenses: expenseActive.filter((rule) => !expenseDone.has(rule.id)),
        };
      });

      const pending = Effect.fn("RecurringService.pending")(function* (
        userId: UserId,
        { from }: ApplyRecurring,
      ) {
        const todo = yield* open(userId, from);
        return {
          incomes: todo.incomes.length,
          allocations: todo.allocations.length,
          expenses: todo.expenses.length,
          skipped: 0,
        };
      });

      const apply = Effect.fn("RecurringService.apply")(function* (
        userId: UserId,
        { from, to }: ApplyRecurring,
      ) {
        const now = yield* DateTime.now;
        const today = DateTime.formatIso(now).slice(0, 10);
        // an expense is dated today when today is in the stretch, else its first day
        const spentAt =
          from <= today && today <= to
            ? now
            : DateTime.makeUnsafe(`${from}T00:00:00Z`);

        // All or nothing: a failure half way must not leave a partial apply.
        return yield* Effect.gen(function* () {
          // One apply per user and stretch at a time. A second, concurrent call
          // waits here and then finds nothing left to add, instead of failing
          // on the unique indexes.
          yield* sql`SELECT pg_advisory_xact_lock(hashtext(${`${userId}/${from}`}))`;

          const todo = yield* open(userId, from);
          const link = (ruleId: string) => ({ ruleId, month: from });

          // money first, so what the allocations take is there
          for (const rule of todo.incomes) {
            yield* incomes.createFromRule(
              userId,
              {
                amountMinor: rule.amountMinor,
                receivedOn: dayIn(from, to, rule.dayOfMonth),
                note: rule.note,
              },
              link(rule.id),
            );
          }

          // top-level envelopes first: a sub-envelope is funded from what the
          // same user put into its parent, which may be a rule of this very apply
          const parentOf = new Map(
            (yield* envelopes.list(userId)).map((e) => [e.id, e.parentId]),
          );
          const byDepth = [...todo.allocations].sort(
            (a, b) =>
              Number(parentOf.get(a.envelopeId) != null) -
              Number(parentOf.get(b.envelopeId) != null),
          );

          let allocations = 0;
          let skipped = 0;
          for (const rule of byDepth) {
            const made = yield* envelopes
              .createAllocation(
                userId,
                {
                  envelopeId: rule.envelopeId,
                  amountMinor: rule.amountMinor,
                  madeOn: dayIn(from, to, rule.dayOfMonth),
                  note: rule.note,
                },
                link(rule.id),
              )
              .pipe(
                // the envelope does not have the money or is not the user's now
                Effect.catchTags({
                  NotEnoughMoney: () => Effect.succeed(undefined),
                  EnvelopeNotFound: () => Effect.succeed(undefined),
                }),
              );
            if (made === undefined) skipped++;
            else allocations++;
          }

          let spentCount = 0;
          for (const rule of todo.expenses) {
            const created = yield* expenses
              .createFromRule(userId, {
                envelopeId: rule.envelopeId,
                amountMinor: rule.amountMinor,
                spentAt,
                note: rule.note,
                recurringId: rule.id,
                recurringMonth: from,
              })
              .pipe(
                // the user cannot see the envelope any more: nothing to add
                Effect.catchTag("EnvelopeNotFound", () =>
                  Effect.succeed(undefined),
                ),
              );
            if (created !== undefined) spentCount++;
          }
          return {
            incomes: todo.incomes.length,
            allocations,
            expenses: spentCount,
            skipped,
          };
        }).pipe(sql.withTransaction, Effect.orDie);
      });

      return RecurringService.of({
        list: repo.list,
        create,
        update,
        remove,
        listIncomes: incomeRules.list,
        createIncome,
        updateIncome,
        removeIncome,
        listAllocationRules: allocationRules.list,
        createAllocationRule,
        updateAllocationRule,
        removeAllocationRule,
        pending,
        apply,
      });
    }),
  );
}
