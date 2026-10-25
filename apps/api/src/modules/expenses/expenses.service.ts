import {
  type CategoryId,
  type CreateExpense,
  type EnvelopeId,
  EnvelopeNotFound,
  Expense,
  type ExpenseId,
  ExpenseNotFound,
  type OriginalAmount,
  type PeriodId,
  type PeriodNotFound,
  type PeriodProgress,
  type PeriodSummary,
  type RecurringRuleId,
  type UpdateExpense,
  type UserId,
} from "@bida/api-contract";
import { Context, type DateTime, Effect, Layer, Option } from "effect";
import type { InSpace } from "../../platform/space.ts";
import { BudgetsService } from "../budgets/budgets.module.ts";
import { ExpensesRepository } from "./expenses.repository.ts";

export interface ListExpenses {
  readonly categoryId?: CategoryId | undefined;
  readonly envelopeId?: EnvelopeId | undefined;
  readonly from?: DateTime.Utc | undefined;
  readonly to?: DateTime.Utc | undefined;
  readonly limit?: number | undefined;
  readonly offset?: number | undefined;
}

const DEFAULT_LIMIT = 50;

/** Business rules for expenses and the planned-vs-spent view. */
export class ExpensesService extends Context.Service<
  ExpensesService,
  {
    /** `createdBy` is the user who adds it, if any. */
    create(
      input: CreateExpense,
      createdBy?: UserId | null,
    ): InSpace<Expense, EnvelopeNotFound>;
    /** Adds the expense a recurring rule produces, on behalf of whoever applied it. */
    createFromRule(
      input: CreateExpense & { readonly recurringId: RecurringRuleId },
      createdBy?: UserId | null,
    ): InSpace<Expense, EnvelopeNotFound>;
    /** Rules that already produced an expense in the period. */
    appliedRecurringIds(
      periodId: PeriodId,
    ): InSpace<ReadonlySet<RecurringRuleId>>;
    get(id: ExpenseId): InSpace<Expense, ExpenseNotFound>;
    update(
      id: ExpenseId,
      input: UpdateExpense,
    ): InSpace<Expense, ExpenseNotFound | EnvelopeNotFound>;
    remove(id: ExpenseId): InSpace<void, ExpenseNotFound>;
    listForPeriod(
      periodId: PeriodId,
      filter: ListExpenses,
    ): InSpace<ReadonlyArray<Expense>, PeriodNotFound>;
    progress(periodId: PeriodId): InSpace<PeriodProgress, PeriodNotFound>;
    /** Planned and spent for every period, newest first. */
    periodSummaries: InSpace<ReadonlyArray<PeriodSummary>>;
  }
>()("bida/expenses/ExpensesService") {
  static readonly layer = Layer.effect(
    ExpensesService,
    Effect.gen(function* () {
      const repo = yield* ExpensesRepository;
      const budgets = yield* BudgetsService;

      // Records what was paid in another currency. A payment in the currency
      // of the period is just an ordinary expense, so it stays null.
      const originalOf = Effect.fn("ExpensesService.originalOf")(function* (
        periodId: PeriodId,
        original: OriginalAmount | undefined,
      ) {
        if (original === undefined) {
          return { originalAmountMinor: null, originalCurrency: null };
        }
        const { period } = yield* budgets
          .getPeriod(periodId)
          .pipe(Effect.orDie);
        return original.currency === period.currency
          ? { originalAmountMinor: null, originalCurrency: null }
          : {
              originalAmountMinor: original.amountMinor,
              originalCurrency: original.currency,
            };
      });

      const insert = Effect.fn("ExpensesService.insert")(function* (
        input: CreateExpense,
        recurringId: RecurringRuleId | null,
        createdBy: UserId | null,
      ) {
        const envelope = yield* budgets.getEnvelope(input.envelopeId);
        const row = yield* Expense.insert
          .makeEffect({
            envelopeId: envelope.id,
            periodId: envelope.periodId,
            amountMinor: input.amountMinor,
            ...(yield* originalOf(envelope.periodId, input.original)),
            spentAt: input.spentAt,
            note: input.note,
            recurringId,
            createdBy,
          })
          .pipe(Effect.orDie);
        return yield* repo.insert(row);
      });

      const create = (input: CreateExpense, createdBy: UserId | null = null) =>
        insert(input, null, createdBy);

      const createFromRule = (
        input: CreateExpense & { readonly recurringId: RecurringRuleId },
        createdBy: UserId | null = null,
      ) => insert(input, input.recurringId, createdBy);

      const get = Effect.fn("ExpensesService.get")(function* (id: ExpenseId) {
        const found = yield* repo.findById(id);
        return yield* Option.match(found, {
          onNone: () => Effect.fail(new ExpenseNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const update = Effect.fn("ExpensesService.update")(function* (
        id: ExpenseId,
        input: UpdateExpense,
      ) {
        const existing = yield* get(id);
        // an expense may only move to another envelope of the same period
        const envelope = yield* budgets.getEnvelope(input.envelopeId);
        if (envelope.periodId !== existing.periodId) {
          return yield* new EnvelopeNotFound({ id: input.envelopeId });
        }
        const updated = yield* repo.update(id, {
          envelopeId: input.envelopeId,
          amountMinor: input.amountMinor,
          spentAt: input.spentAt,
          note: input.note,
          ...(yield* originalOf(existing.periodId, input.original)),
        });
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new ExpenseNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const remove = Effect.fn("ExpensesService.remove")(function* (
        id: ExpenseId,
      ) {
        const removed = yield* repo.remove(id);
        if (!removed) return yield* new ExpenseNotFound({ id });
      });

      const listForPeriod = Effect.fn("ExpensesService.listForPeriod")(
        function* (periodId: PeriodId, filter: ListExpenses) {
          const { envelopes } = yield* budgets.getPeriod(periodId);

          let envelopeIds: ReadonlyArray<EnvelopeId> | undefined;
          if (filter.categoryId !== undefined) {
            envelopeIds = envelopes
              .filter((e) => e.categoryId === filter.categoryId)
              .map((e) => e.id);
          }
          if (filter.envelopeId !== undefined) {
            const only = filter.envelopeId;
            envelopeIds = (envelopeIds ?? envelopes.map((e) => e.id)).filter(
              (id) => id === only,
            );
          }

          return yield* repo.list({
            periodId,
            envelopeIds,
            from: filter.from,
            to: filter.to,
            limit: filter.limit ?? DEFAULT_LIMIT,
            offset: filter.offset ?? 0,
          });
        },
      );

      const progress = Effect.fn("ExpensesService.progress")(function* (
        periodId: PeriodId,
      ) {
        const detail = yield* budgets.getPeriod(periodId);
        const spent = yield* repo.spentByEnvelope(periodId);

        const envelopes = detail.envelopes.map((envelope) => {
          const spentMinor = spent.get(envelope.id) ?? 0;
          return {
            envelopeId: envelope.id,
            categoryId: envelope.categoryId,
            plannedMinor: envelope.plannedMinor,
            spentMinor,
            remainingMinor: envelope.plannedMinor - spentMinor,
          };
        });
        const spentMinor = envelopes.reduce((sum, e) => sum + e.spentMinor, 0);
        return {
          periodId,
          incomeMinor: detail.period.incomeMinor,
          plannedMinor: detail.plannedMinor,
          spentMinor,
          remainingMinor: detail.plannedMinor - spentMinor,
          unallocatedMinor: detail.unallocatedMinor,
          envelopes,
        };
      });

      const periodSummaries = Effect.gen(function* () {
        const periods = yield* budgets.listPeriods;
        const planned = yield* budgets.plannedByPeriod;
        const spent = yield* repo.spentByPeriod;
        return periods.map((period) => ({
          period,
          plannedMinor: planned.get(period.id) ?? 0,
          spentMinor: spent.get(period.id) ?? 0,
        }));
      }).pipe(Effect.withSpan("ExpensesService.periodSummaries"));

      return ExpensesService.of({
        create,
        createFromRule,
        appliedRecurringIds: repo.appliedRecurringIds,
        get,
        update,
        remove,
        listForPeriod,
        progress,
        periodSummaries,
      });
    }),
  );
}
