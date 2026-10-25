import {
  type CreateExpense,
  type EnvelopeId,
  type EnvelopeNotFound,
  Expense,
  type ExpenseId,
  ExpenseNotFound,
  Forbidden,
  type RecurringRuleId,
  type UpdateExpense,
  type UserId,
} from "@bida/api-contract";
import { Context, type DateTime, Effect, Layer, Option } from "effect";
import { EnvelopesService } from "../envelopes/envelopes.module.ts";
import { ExpensesRepository } from "./expenses.repository.ts";

export interface ListExpenses {
  readonly envelopeId?: EnvelopeId | undefined;
  readonly from?: DateTime.Utc | undefined;
  readonly to?: DateTime.Utc | undefined;
  readonly limit?: number | undefined;
  readonly offset?: number | undefined;
}

const DEFAULT_LIMIT = 50;

/** Business rules for expenses. */
export class ExpensesService extends Context.Service<
  ExpensesService,
  {
    create(
      userId: UserId,
      input: CreateExpense,
    ): Effect.Effect<Expense, EnvelopeNotFound>;
    /** Adds the expense a recurring rule of the user produces. */
    createFromRule(
      userId: UserId,
      input: CreateExpense & {
        readonly recurringId: RecurringRuleId;
        /** First day of the stretch the rule was applied to. */
        readonly recurringMonth: string;
      },
    ): Effect.Effect<Expense, EnvelopeNotFound>;
    /** Of the rules, those that already produced an expense for the stretch. */
    appliedRecurringIds(
      ruleIds: ReadonlyArray<RecurringRuleId>,
      recurringMonth: string,
    ): Effect.Effect<ReadonlySet<RecurringRuleId>>;
    get(userId: UserId, id: ExpenseId): Effect.Effect<Expense, ExpenseNotFound>;
    update(
      userId: UserId,
      id: ExpenseId,
      input: UpdateExpense,
    ): Effect.Effect<Expense, ExpenseNotFound | EnvelopeNotFound | Forbidden>;
    remove(
      userId: UserId,
      id: ExpenseId,
    ): Effect.Effect<void, ExpenseNotFound | Forbidden>;
    list(
      userId: UserId,
      filter: ListExpenses,
    ): Effect.Effect<ReadonlyArray<Expense>, EnvelopeNotFound>;
  }
>()("bida/expenses/ExpensesService") {
  static readonly layer = Layer.effect(
    ExpensesService,
    Effect.gen(function* () {
      const repo = yield* ExpensesRepository;
      const envelopes = yield* EnvelopesService;

      const insert = Effect.fn("ExpensesService.insert")(function* (
        userId: UserId,
        input: CreateExpense,
        recurringId: RecurringRuleId | null,
        recurringMonth: string | null,
      ) {
        const { envelope } = yield* envelopes.access(userId, input.envelopeId);
        const row = yield* Expense.insert
          .makeEffect({
            envelopeId: envelope.id,
            createdBy: userId,
            amountMinor: input.amountMinor,
            spentAt: input.spentAt,
            note: input.note,
            recurringId,
          })
          .pipe(Effect.orDie);
        return yield* repo.insert(row, recurringMonth);
      });

      const create = (userId: UserId, input: CreateExpense) =>
        insert(userId, input, null, null);

      const createFromRule = (
        userId: UserId,
        input: CreateExpense & {
          readonly recurringId: RecurringRuleId;
          readonly recurringMonth: string;
        },
      ) => insert(userId, input, input.recurringId, input.recurringMonth);

      /** The expense, when the user can see the envelope it is in. */
      const visible = Effect.fn("ExpensesService.visible")(function* (
        userId: UserId,
        id: ExpenseId,
      ) {
        const found = yield* repo.findById(id);
        if (Option.isNone(found)) return yield* new ExpenseNotFound({ id });
        const access = yield* envelopes
          .access(userId, found.value.envelopeId)
          .pipe(Effect.mapError(() => new ExpenseNotFound({ id })));
        return { expense: found.value, role: access.role };
      });

      const get = (userId: UserId, id: ExpenseId) =>
        Effect.map(visible(userId, id), ({ expense }) => expense);

      // the author and the owner of the envelope may change an expense
      const mayChange = (
        userId: UserId,
        found: { expense: Expense; role: "owner" | "member" },
      ) => found.expense.createdBy === userId || found.role === "owner";

      const update = Effect.fn("ExpensesService.update")(function* (
        userId: UserId,
        id: ExpenseId,
        input: UpdateExpense,
      ) {
        const found = yield* visible(userId, id);
        if (!mayChange(userId, found)) return yield* new Forbidden();
        yield* envelopes.access(userId, input.envelopeId);
        const updated = yield* repo.update(id, {
          envelopeId: input.envelopeId,
          amountMinor: input.amountMinor,
          spentAt: input.spentAt,
          note: input.note,
        });
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new ExpenseNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const remove = Effect.fn("ExpensesService.remove")(function* (
        userId: UserId,
        id: ExpenseId,
      ) {
        const found = yield* visible(userId, id);
        if (!mayChange(userId, found)) return yield* new Forbidden();
        yield* repo.remove(id);
      });

      const list = Effect.fn("ExpensesService.list")(function* (
        userId: UserId,
        filter: ListExpenses,
      ) {
        const envelopeIds = yield* envelopes.scope(userId, filter.envelopeId);
        return yield* repo.list({
          envelopeIds,
          from: filter.from,
          to: filter.to,
          limit: filter.limit ?? DEFAULT_LIMIT,
          offset: filter.offset ?? 0,
        });
      });

      return ExpensesService.of({
        create,
        createFromRule,
        appliedRecurringIds: repo.appliedRecurringIds,
        get,
        update,
        remove,
        list,
      });
    }),
  );
}
