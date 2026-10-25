import {
  type ApplyRecurring,
  type ApplyResult,
  type EnvelopeNotFound,
  RecurringRule,
  type RecurringRuleId,
  RecurringRuleNotFound,
  type SaveRecurringRule,
  type UserId,
} from "@bida/api-contract";
import { Context, DateTime, Effect, Layer, Option } from "effect";
import { SqlClient } from "effect/sql";
import { EnvelopesService } from "../envelopes/envelopes.module.ts";
import { ExpensesService } from "../expenses/expenses.module.ts";
import { RecurringRepository } from "./recurring.repository.ts";

/** Business rules for recurring expenses. */
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
    apply(userId: UserId, input: ApplyRecurring): Effect.Effect<ApplyResult>;
  }
>()("bida/recurring/RecurringService") {
  static readonly layer = Layer.effect(
    RecurringService,
    Effect.gen(function* () {
      const repo = yield* RecurringRepository;
      const envelopes = yield* EnvelopesService;
      const expenses = yield* ExpensesService;
      const sql = yield* SqlClient.SqlClient;

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
        const added = yield* Effect.gen(function* () {
          // One apply per user and stretch at a time. A second, concurrent call
          // waits here and then finds nothing left to add, instead of failing
          // on the unique index.
          yield* sql`SELECT pg_advisory_xact_lock(hashtext(${`${userId}/${from}`}))`;

          const rules = (yield* repo.list(userId))
            .filter((rule) => rule.active)
            .reverse(); // oldest first
          const applied = yield* expenses.appliedRecurringIds(
            rules.map((rule) => rule.id),
            from,
          );

          let count = 0;
          for (const rule of rules) {
            if (applied.has(rule.id)) continue;
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
            if (created !== undefined) count++;
          }
          return count;
        }).pipe(sql.withTransaction, Effect.orDie);

        return { added };
      });

      return RecurringService.of({
        list: repo.list,
        create,
        update,
        remove,
        apply,
      });
    }),
  );
}
