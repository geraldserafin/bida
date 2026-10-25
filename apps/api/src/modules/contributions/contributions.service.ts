import {
  type AddContribution,
  Contribution,
  type ContributionId,
  ContributionNotFound,
  Forbidden,
  type PeriodId,
  type PeriodNotFound,
  type Role,
  type UserId,
} from "@bida/api-contract";
import { Context, Effect, Layer, Option } from "effect";
import type { InSpace } from "../../platform/space.ts";
import { BudgetsService } from "../budgets/budgets.module.ts";
import { ContributionsRepository } from "./contributions.repository.ts";

/** Business rules for money paid into the budget of a shared space. */
export class ContributionsService extends Context.Service<
  ContributionsService,
  {
    listForPeriod(
      periodId: PeriodId,
    ): InSpace<ReadonlyArray<Contribution>, PeriodNotFound>;
    /** In the name of `userId`, or of nobody when the money is external. */
    add(
      periodId: PeriodId,
      input: AddContribution,
      userId: UserId,
    ): InSpace<Contribution, PeriodNotFound>;
    /** Whoever recorded it may delete it, and so may an owner. */
    remove(
      id: ContributionId,
      userId: string,
      role: Role,
    ): InSpace<void, ContributionNotFound | Forbidden>;
    /** Total paid in per period; periods without contributions are absent. */
    totalByPeriod: InSpace<ReadonlyMap<PeriodId, number>>;
  }
>()("bida/contributions/ContributionsService") {
  static readonly layer = Layer.effect(
    ContributionsService,
    Effect.gen(function* () {
      const repo = yield* ContributionsRepository;
      const budgets = yield* BudgetsService;

      const listForPeriod = Effect.fn("ContributionsService.listForPeriod")(
        function* (periodId: PeriodId) {
          yield* budgets.getPeriod(periodId); // 404 for a period of another space
          return yield* repo.listForPeriod(periodId);
        },
      );

      const add = Effect.fn("ContributionsService.add")(function* (
        periodId: PeriodId,
        input: AddContribution,
        userId: UserId,
      ) {
        yield* budgets.getPeriod(periodId);
        const row = yield* Contribution.insert
          .makeEffect({
            periodId,
            userId: input.external === true ? null : userId,
            amountMinor: input.amountMinor,
            contributedAt: input.contributedAt,
            note: input.note,
          })
          .pipe(Effect.orDie);
        return yield* repo.insert(row);
      });

      const remove = Effect.fn("ContributionsService.remove")(function* (
        id: ContributionId,
        userId: string,
        role: Role,
      ) {
        const found = yield* repo.findById(id);
        const contribution = yield* Option.match(found, {
          onNone: () => Effect.fail(new ContributionNotFound({ id })),
          onSome: Effect.succeed,
        });
        if (role !== "owner" && contribution.userId !== userId)
          return yield* new Forbidden();
        yield* repo.delete(id);
      });

      return ContributionsService.of({
        listForPeriod,
        add,
        remove,
        totalByPeriod: repo.totalByPeriod,
      });
    }),
  );
}
