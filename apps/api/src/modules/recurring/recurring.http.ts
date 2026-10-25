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
      .handle("apply", ({ payload }) =>
        Effect.flatMap(userId, (id) => recurring.apply(id, payload)),
      );
  }),
);
