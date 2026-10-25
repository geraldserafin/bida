import { Api } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { RecurringService } from "./recurring.service.ts";

/** Thin adapter: decoded request in, service call, domain errors out. */
export const RecurringHttp = HttpApiBuilder.group(
  Api,
  "recurring",
  Effect.fn(function* (handlers) {
    const recurring = yield* RecurringService;
    return handlers
      .handle("list", () => recurring.list)
      .handle("create", ({ payload }) => recurring.create(payload))
      .handle("update", ({ params, payload }) =>
        recurring.update(params.id, payload),
      )
      .handle("delete", ({ params }) => recurring.remove(params.id))
      .handle("suggestedPlan", ({ query }) =>
        recurring.suggestedPlan(query.currency),
      )
      .handle("apply", ({ params }) =>
        recurring.applyToPeriod(params.periodId),
      );
  }),
);
