import { Api, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { RecurringService } from "./recurring.service.ts";

const userId = Effect.map(CurrentUser, ({ user }) => user.id);

/** Thin adapter: decoded request in, service call, domain errors out. */
export const RecurringHttp = HttpApiBuilder.group(
  Api,
  "recurring",
  Effect.fn(function* (handlers) {
    const recurring = yield* RecurringService;
    return handlers
      .handle("list", () => Effect.flatMap(userId, recurring.list))
      .handle("create", ({ payload }) =>
        Effect.flatMap(userId, (id) => recurring.create(id, payload)),
      )
      .handle("update", ({ params, payload }) =>
        Effect.flatMap(userId, (id) =>
          recurring.update(id, params.id, payload),
        ),
      )
      .handle("delete", ({ params }) =>
        Effect.flatMap(userId, (id) => recurring.remove(id, params.id)),
      )
      .handle("pending", ({ query }) =>
        Effect.flatMap(userId, (id) => recurring.pending(id, query)),
      )
      .handle("apply", ({ payload }) =>
        Effect.flatMap(userId, (id) => recurring.apply(id, payload)),
      );
  }),
);

export const RecurringIncomesHttp = HttpApiBuilder.group(
  Api,
  "recurringIncomes",
  Effect.fn(function* (handlers) {
    const recurring = yield* RecurringService;
    return handlers
      .handle("list", () => Effect.flatMap(userId, recurring.listIncomes))
      .handle("create", ({ payload }) =>
        Effect.flatMap(userId, (id) => recurring.createIncome(id, payload)),
      )
      .handle("update", ({ params, payload }) =>
        Effect.flatMap(userId, (id) =>
          recurring.updateIncome(id, params.id, payload),
        ),
      )
      .handle("delete", ({ params }) =>
        Effect.flatMap(userId, (id) => recurring.removeIncome(id, params.id)),
      );
  }),
);

export const AllocationRulesHttp = HttpApiBuilder.group(
  Api,
  "allocationRules",
  Effect.fn(function* (handlers) {
    const recurring = yield* RecurringService;
    return handlers
      .handle("list", () =>
        Effect.flatMap(userId, recurring.listAllocationRules),
      )
      .handle("create", ({ payload }) =>
        Effect.flatMap(userId, (id) =>
          recurring.createAllocationRule(id, payload),
        ),
      )
      .handle("update", ({ params, payload }) =>
        Effect.flatMap(userId, (id) =>
          recurring.updateAllocationRule(id, params.id, payload),
        ),
      )
      .handle("delete", ({ params }) =>
        Effect.flatMap(userId, (id) =>
          recurring.removeAllocationRule(id, params.id),
        ),
      );
  }),
);
