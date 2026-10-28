import {
  Income,
  type IncomeId,
  IncomeNotFound,
  type SaveIncome,
  type UserId,
} from "@bida/api-contract";
import { Context, Effect, Layer, Option } from "effect";
import { IncomesRepository } from "./incomes.repository.ts";

/** Business rules for income. */
export class IncomesService extends Context.Service<
  IncomesService,
  {
    list(
      userId: UserId,
      range: {
        readonly from?: string | undefined;
        readonly to?: string | undefined;
      },
    ): Effect.Effect<ReadonlyArray<Income>>;
    create(userId: UserId, input: SaveIncome): Effect.Effect<Income>;
    /** Adds the income a recurring income produces for a stretch. */
    createFromRule(
      userId: UserId,
      input: SaveIncome,
      link: { readonly ruleId: string; readonly month: string },
    ): Effect.Effect<Income>;
    /** Of the rules, those that already made an income for the stretch. */
    appliedRuleIds(
      ruleIds: ReadonlyArray<string>,
      month: string,
    ): Effect.Effect<ReadonlySet<string>>;
    update(
      userId: UserId,
      id: IncomeId,
      input: SaveIncome,
    ): Effect.Effect<Income, IncomeNotFound>;
    remove(userId: UserId, id: IncomeId): Effect.Effect<void, IncomeNotFound>;
  }
>()("bida/incomes/IncomesService") {
  static readonly layer = Layer.effect(
    IncomesService,
    Effect.gen(function* () {
      const repo = yield* IncomesRepository;

      const insert = Effect.fn("IncomesService.insert")(function* (
        userId: UserId,
        input: SaveIncome,
        link?: { readonly ruleId: string; readonly month: string },
      ) {
        const row = yield* Income.insert
          .makeEffect({ ...input, userId })
          .pipe(Effect.orDie);
        return yield* repo.insert(row, link);
      });

      const create = (userId: UserId, input: SaveIncome) =>
        insert(userId, input);

      const update = Effect.fn("IncomesService.update")(function* (
        userId: UserId,
        id: IncomeId,
        input: SaveIncome,
      ) {
        const updated = yield* repo.update(userId, id, input);
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new IncomeNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const remove = Effect.fn("IncomesService.remove")(function* (
        userId: UserId,
        id: IncomeId,
      ) {
        if (!(yield* repo.remove(userId, id))) {
          return yield* new IncomeNotFound({ id });
        }
      });

      return IncomesService.of({
        list: repo.list,
        create,
        createFromRule: insert,
        appliedRuleIds: repo.appliedRuleIds,
        update,
        remove,
      });
    }),
  );
}
