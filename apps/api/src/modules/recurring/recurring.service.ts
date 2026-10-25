import {
  type ApplyResult,
  CategoryNotFound,
  type Currency,
  CurrentSpace,
  type EnvelopePlan,
  type PeriodId,
  type PeriodNotFound,
  RecurringRule,
  type RecurringRuleId,
  RecurringRuleNotFound,
  type SaveRecurringRule,
} from "@bida/api-contract";
import { Context, DateTime, Effect, Layer, Option } from "effect";
import { SqlClient } from "effect/sql";
import type { InSpace } from "../../platform/space.ts";
import { BudgetsService } from "../budgets/budgets.module.ts";
import { CategoriesService } from "../categories/categories.module.ts";
import { ExpensesService } from "../expenses/expenses.module.ts";
import { RecurringRepository } from "./recurring.repository.ts";

/** Business rules for recurring expenses. */
export class RecurringService extends Context.Service<
  RecurringService,
  {
    list: InSpace<ReadonlyArray<RecurringRule>>;
    create(input: SaveRecurringRule): InSpace<RecurringRule, CategoryNotFound>;
    update(
      id: RecurringRuleId,
      input: SaveRecurringRule,
    ): InSpace<RecurringRule, RecurringRuleNotFound | CategoryNotFound>;
    remove(id: RecurringRuleId): InSpace<void, RecurringRuleNotFound>;
    /** Sum of the active rules per category. */
    suggestedPlan(currency?: Currency): InSpace<ReadonlyArray<EnvelopePlan>>;
    applyToPeriod(periodId: PeriodId): InSpace<ApplyResult, PeriodNotFound>;
  }
>()("bida/recurring/RecurringService") {
  static readonly layer = Layer.effect(
    RecurringService,
    Effect.gen(function* () {
      const repo = yield* RecurringRepository;
      const categories = yield* CategoriesService;
      const budgets = yield* BudgetsService;
      const expenses = yield* ExpensesService;
      const sql = yield* SqlClient.SqlClient;

      const requireCategory = Effect.fn("RecurringService.requireCategory")(
        function* (input: SaveRecurringRule) {
          const known = yield* categories.list;
          if (!known.some((category) => category.id === input.categoryId)) {
            return yield* new CategoryNotFound({ id: input.categoryId });
          }
        },
      );

      const create = Effect.fn("RecurringService.create")(function* (
        input: SaveRecurringRule,
      ) {
        yield* requireCategory(input);
        const row = yield* RecurringRule.insert
          .makeEffect({
            ...input,
            currency: input.currency ?? (yield* CurrentSpace).defaultCurrency,
          })
          .pipe(Effect.orDie);
        return yield* repo.insert(row);
      });

      const update = Effect.fn("RecurringService.update")(function* (
        id: RecurringRuleId,
        input: SaveRecurringRule,
      ) {
        yield* requireCategory(input);
        const updated = yield* repo.update(id, {
          ...input,
          currency: input.currency ?? (yield* CurrentSpace).defaultCurrency,
        });
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new RecurringRuleNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const remove = Effect.fn("RecurringService.remove")(function* (
        id: RecurringRuleId,
      ) {
        const removed = yield* repo.remove(id);
        if (!removed) return yield* new RecurringRuleNotFound({ id });
      });

      const suggestedPlan = Effect.fn("RecurringService.suggestedPlan")(
        function* (currency?: Currency) {
          const wanted = currency ?? (yield* CurrentSpace).defaultCurrency;
          const totals = new Map<EnvelopePlan["categoryId"], number>();
          for (const rule of yield* repo.list) {
            if (!rule.active || rule.currency !== wanted) continue;
            totals.set(
              rule.categoryId,
              (totals.get(rule.categoryId) ?? 0) + rule.amountMinor,
            );
          }
          return [...totals].map(([categoryId, plannedMinor]) => ({
            categoryId,
            plannedMinor,
          }));
        },
      );

      const applyToPeriod = Effect.fn("RecurringService.applyToPeriod")(
        function* (periodId: PeriodId) {
          const detail = yield* budgets.getPeriod(periodId);
          const applied = yield* expenses.appliedRecurringIds(periodId);
          const rules = (yield* repo.list)
            .filter(
              (rule) =>
                rule.active &&
                rule.currency === detail.period.currency &&
                !applied.has(rule.id),
            )
            .reverse(); // oldest first
          const spentAt = yield* DateTime.now;

          // all or nothing: a failure half way must not leave a partial apply
          const added = yield* Effect.gen(function* () {
            const envelopeByCategory = new Map(
              detail.envelopes.map((e) => [e.categoryId, e.id] as const),
            );
            for (const rule of rules) {
              let envelopeId = envelopeByCategory.get(rule.categoryId);
              if (envelopeId === undefined) {
                // no envelope for the category yet: plan exactly this rule
                const envelope = yield* budgets.addEnvelope(periodId, {
                  categoryId: rule.categoryId,
                  plannedMinor: rule.amountMinor,
                });
                envelopeId = envelope.id;
                envelopeByCategory.set(rule.categoryId, envelope.id);
              }
              yield* expenses.createFromRule({
                envelopeId,
                recurringId: rule.id,
                amountMinor: rule.amountMinor,
                spentAt,
                note: rule.note,
              });
            }
            return rules.length;
          }).pipe(sql.withTransaction, Effect.orDie);

          return { added };
        },
      );

      return RecurringService.of({
        list: repo.list,
        create,
        update,
        remove,
        suggestedPlan,
        applyToPeriod,
      });
    }),
  );
}
