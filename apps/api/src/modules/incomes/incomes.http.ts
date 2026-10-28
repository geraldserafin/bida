import { Api, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { IncomesService } from "./incomes.service.ts";

const userId = Effect.map(CurrentUser, ({ user }) => user.id);

/** Thin adapter: decoded request in, service call, domain errors out. */
export const IncomesHttp = HttpApiBuilder.group(
  Api,
  "incomes",
  Effect.fn(function* (handlers) {
    const incomes = yield* IncomesService;
    return handlers
      .handle("list", ({ query }) =>
        Effect.flatMap(userId, (id) => incomes.list(id, query)),
      )
      .handle("create", ({ payload }) =>
        Effect.flatMap(userId, (id) => incomes.create(id, payload)),
      )
      .handle("update", ({ params, payload }) =>
        Effect.flatMap(userId, (id) => incomes.update(id, params.id, payload)),
      )
      .handle("delete", ({ params }) =>
        Effect.flatMap(userId, (id) => incomes.remove(id, params.id)),
      );
  }),
);
