import { Api } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { BudgetsService } from "./budgets.service.ts";

/** Thin adapter: decoded request in, service call, domain errors out. */
export const BudgetsHttp = HttpApiBuilder.group(
  Api,
  "budgets",
  Effect.fn(function* (handlers) {
    const budgets = yield* BudgetsService;
    return handlers
      .handle("list", () => budgets.listPeriods)
      .handle("current", () => budgets.currentPeriod)
      .handle("create", ({ payload }) => budgets.createPeriod(payload))
      .handle("get", ({ params }) => budgets.getPeriod(params.id))
      .handle("setPlan", ({ params, payload }) =>
        budgets.setPlan(params.id, payload),
      )
      .handle("addEnvelope", ({ params, payload }) =>
        budgets.addEnvelope(params.id, payload),
      )
      .handle("delete", ({ params }) => budgets.deletePeriod(params.id));
  }),
);
