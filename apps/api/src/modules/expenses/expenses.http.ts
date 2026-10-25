import { Api } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { ExpensesService } from "./expenses.service.ts";

/** Thin adapter: decoded request in, service call, domain errors out. */
export const ExpensesHttp = HttpApiBuilder.group(
  Api,
  "expenses",
  Effect.fn(function* (handlers) {
    const expenses = yield* ExpensesService;
    return handlers
      .handle("create", ({ payload }) => expenses.create(payload))
      .handle("get", ({ params }) => expenses.get(params.id))
      .handle("update", ({ params, payload }) =>
        expenses.update(params.id, payload),
      )
      .handle("delete", ({ params }) => expenses.remove(params.id))
      .handle("listForPeriod", ({ params, query }) =>
        expenses.listForPeriod(params.periodId, query),
      )
      .handle("progress", ({ params }) => expenses.progress(params.periodId))
      .handle("periodSummaries", () => expenses.periodSummaries);
  }),
);
