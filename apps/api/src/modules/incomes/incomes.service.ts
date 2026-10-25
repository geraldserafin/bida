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

      const create = Effect.fn("IncomesService.create")(function* (
        userId: UserId,
        input: SaveIncome,
      ) {
        const row = yield* Income.insert
          .makeEffect({ ...input, userId })
          .pipe(Effect.orDie);
        return yield* repo.insert(row);
      });

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

      return IncomesService.of({ list: repo.list, create, update, remove });
    }),
  );
}
