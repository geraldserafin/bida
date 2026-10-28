import { Api, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { ExpensesService } from "./expenses.service.ts";

const userId = Effect.map(CurrentUser, ({ user }) => user.id);

/** Thin adapter: decoded request in, service call, domain errors out. */
export const ExpensesHttp = HttpApiBuilder.group(
  Api,
  "expenses",
  Effect.fn(function* (handlers) {
    const expenses = yield* ExpensesService;
    return handlers
      .handle("create", ({ payload }) =>
        Effect.flatMap(userId, (id) => expenses.create(id, payload)),
      )
      .handle("get", ({ params }) =>
        Effect.flatMap(userId, (id) => expenses.get(id, params.id)),
      )
      .handle("update", ({ params, payload }) =>
        Effect.flatMap(userId, (id) => expenses.update(id, params.id, payload)),
      )
      .handle("delete", ({ params }) =>
        Effect.flatMap(userId, (id) => expenses.remove(id, params.id)),
      )
      .handle("list", ({ query }) =>
        Effect.flatMap(userId, (id) => expenses.list(id, query)),
      );
  }),
);
