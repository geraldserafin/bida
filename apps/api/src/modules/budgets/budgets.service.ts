import {
  CategoryNotFound,
  type CreatePeriod,
  CurrentSpace,
  Envelope,
  EnvelopeAlreadyExists,
  type EnvelopeId,
  EnvelopeNotFound,
  type EnvelopePlan,
  InvalidPeriodRange,
  NoPeriods,
  Period,
  type PeriodDetail,
  type PeriodId,
  PeriodNotFound,
  type SetPlan,
  type UpdatePeriod,
} from "@bida/api-contract";
import { Context, Effect, Layer, Option } from "effect";
import { SqlClient } from "effect/sql";
import type { InSpace } from "../../platform/space.ts";
import { CategoriesService } from "../categories/categories.module.ts";
import { BudgetsRepository, type EnvelopeInUse } from "./budgets.repository.ts";

/** Business rules for periods and their envelopes. */
export class BudgetsService extends Context.Service<
  BudgetsService,
  {
    listPeriods: InSpace<ReadonlyArray<Period>>;
    /** Total planned per period; periods without envelopes are absent. */
    plannedByPeriod: InSpace<ReadonlyMap<PeriodId, number>>;
    currentPeriod: InSpace<PeriodDetail, NoPeriods>;
    getPeriod(id: PeriodId): InSpace<PeriodDetail, PeriodNotFound>;
    createPeriod(
      input: CreatePeriod,
    ): InSpace<PeriodDetail, InvalidPeriodRange | CategoryNotFound>;
    setPlan(
      id: PeriodId,
      input: SetPlan,
    ): InSpace<PeriodDetail, PeriodNotFound | CategoryNotFound>;
    addEnvelope(
      id: PeriodId,
      input: EnvelopePlan,
    ): InSpace<
      Envelope,
      PeriodNotFound | CategoryNotFound | EnvelopeAlreadyExists
    >;
    updatePeriod(
      id: PeriodId,
      input: UpdatePeriod,
    ): InSpace<PeriodDetail, PeriodNotFound | InvalidPeriodRange>;
    getEnvelope(id: EnvelopeId): InSpace<Envelope, EnvelopeNotFound>;
    deletePeriod(id: PeriodId): InSpace<void, PeriodNotFound>;
  }
>()("bida/budgets/BudgetsService") {
  static readonly layer = Layer.effect(
    BudgetsService,
    Effect.gen(function* () {
      const repo = yield* BudgetsRepository;
      const categories = yield* CategoriesService;
      const sql = yield* SqlClient.SqlClient;

      const detail = Effect.fn("BudgetsService.detail")(function* (
        period: Period,
      ) {
        const envelopes = yield* repo.listEnvelopes(period.id);
        const plannedMinor = envelopes.reduce(
          (sum, envelope) => sum + envelope.plannedMinor,
          0,
        );
        return {
          period,
          envelopes,
          plannedMinor,
          unallocatedMinor: period.incomeMinor - plannedMinor,
        };
      });

      const requirePeriod = Effect.fn("BudgetsService.requirePeriod")(
        function* (id: PeriodId) {
          const found = yield* repo.findPeriod(id);
          return yield* Option.match(found, {
            onNone: () => Effect.fail(new PeriodNotFound({ id })),
            onSome: Effect.succeed,
          });
        },
      );

      // Fails with CategoryNotFound for the first id that does not exist.
      const requireCategories = Effect.fn("BudgetsService.requireCategories")(
        function* (plans: ReadonlyArray<EnvelopePlan>) {
          const known = new Set((yield* categories.list).map((c) => c.id));
          for (const plan of plans) {
            if (!known.has(plan.categoryId)) {
              return yield* new CategoryNotFound({ id: plan.categoryId });
            }
          }
        },
      );

      const insertEnvelope = (periodId: PeriodId, plan: EnvelopePlan) =>
        Envelope.insert
          .makeEffect({ periodId, ...plan })
          .pipe(Effect.orDie, Effect.flatMap(repo.insertEnvelope));

      const listPeriods = repo.listPeriods;

      const currentPeriod = Effect.fn("BudgetsService.currentPeriod")(
        function* () {
          const latest = yield* repo.latestPeriod;
          const period = yield* Option.match(latest, {
            onNone: () => Effect.fail(new NoPeriods()),
            onSome: Effect.succeed,
          });
          return yield* detail(period);
        },
      );

      const getPeriod = Effect.fn("BudgetsService.getPeriod")(function* (
        id: PeriodId,
      ) {
        return yield* detail(yield* requirePeriod(id));
      });

      const createPeriod = Effect.fn("BudgetsService.createPeriod")(function* (
        input: CreatePeriod,
      ) {
        if (input.endDate < input.startDate) {
          return yield* new InvalidPeriodRange({
            startDate: input.startDate,
            endDate: input.endDate,
          });
        }
        const plans = input.envelopes.filter((plan) => plan.plannedMinor > 0);
        yield* requireCategories(plans);

        return yield* Effect.gen(function* () {
          const row = yield* Period.insert
            .makeEffect({
              name: input.name,
              startDate: input.startDate,
              endDate: input.endDate,
              incomeMinor: input.incomeMinor,
              currency: input.currency ?? (yield* CurrentSpace).defaultCurrency,
            })
            .pipe(Effect.orDie);
          const period = yield* repo.insertPeriod(row);
          // a category listed twice keeps its last amount
          const lastPerCategory = new Map(
            plans.map((plan) => [plan.categoryId, plan] as const),
          );
          for (const plan of lastPerCategory.values()) {
            yield* insertEnvelope(period.id, plan);
          }
          return yield* detail(period);
        }).pipe(sql.withTransaction, Effect.orDie);
      });

      // Removes the envelope, or keeps it at zero when something still points
      // at it. The savepoint keeps a failed delete from poisoning the outer
      // transaction.
      const removeOrZero = (envelopeId: EnvelopeId) =>
        repo.removeEnvelope(envelopeId).pipe(
          sql.withTransaction,
          Effect.catchTag("EnvelopeInUse", (_: EnvelopeInUse) =>
            repo.setPlanned(envelopeId, 0).pipe(Effect.asVoid),
          ),
        );

      const setPlan = Effect.fn("BudgetsService.setPlan")(function* (
        id: PeriodId,
        input: SetPlan,
      ) {
        yield* requirePeriod(id);
        yield* requireCategories(input.envelopes);

        return yield* Effect.gen(function* () {
          const updated = yield* repo.setIncome(id, input.incomeMinor);
          const period = yield* Option.match(updated, {
            onNone: () => Effect.fail(new PeriodNotFound({ id })),
            onSome: Effect.succeed,
          });
          for (const plan of input.envelopes) {
            const existing = yield* repo.findEnvelope(id, plan.categoryId);
            if (Option.isSome(existing)) {
              if (plan.plannedMinor > 0) {
                yield* repo.setPlanned(existing.value.id, plan.plannedMinor);
              } else {
                yield* removeOrZero(existing.value.id);
              }
            } else if (plan.plannedMinor > 0) {
              yield* insertEnvelope(id, plan);
            }
          }
          return yield* detail(period);
        }).pipe(sql.withTransaction, Effect.catchTag("SqlError", Effect.die));
      });

      const addEnvelope = Effect.fn("BudgetsService.addEnvelope")(function* (
        id: PeriodId,
        input: EnvelopePlan,
      ) {
        yield* requirePeriod(id);
        yield* requireCategories([input]);
        const existing = yield* repo.findEnvelope(id, input.categoryId);
        if (Option.isSome(existing)) {
          return yield* new EnvelopeAlreadyExists({
            periodId: id,
            categoryId: input.categoryId,
          });
        }
        return yield* insertEnvelope(id, input);
      });

      const getEnvelope = Effect.fn("BudgetsService.getEnvelope")(function* (
        id: EnvelopeId,
      ) {
        const found = yield* repo.findEnvelopeById(id);
        return yield* Option.match(found, {
          onNone: () => Effect.fail(new EnvelopeNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const updatePeriod = Effect.fn("BudgetsService.updatePeriod")(function* (
        id: PeriodId,
        input: UpdatePeriod,
      ) {
        if (input.endDate < input.startDate) {
          return yield* new InvalidPeriodRange({
            startDate: input.startDate,
            endDate: input.endDate,
          });
        }
        const updated = yield* repo.updatePeriod(id, input);
        const period = yield* Option.match(updated, {
          onNone: () => Effect.fail(new PeriodNotFound({ id })),
          onSome: Effect.succeed,
        });
        return yield* detail(period);
      });

      const deletePeriod = Effect.fn("BudgetsService.deletePeriod")(function* (
        id: PeriodId,
      ) {
        const deleted = yield* repo.deletePeriod(id);
        if (!deleted) return yield* new PeriodNotFound({ id });
      });

      return BudgetsService.of({
        listPeriods,
        plannedByPeriod: repo.plannedByPeriod,
        currentPeriod: currentPeriod(),
        getPeriod,
        createPeriod,
        setPlan,
        addEnvelope,
        updatePeriod,
        getEnvelope,
        deletePeriod,
      });
    }),
  );
}
