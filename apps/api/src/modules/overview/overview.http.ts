import { Api, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { OverviewService } from "./overview.service.ts";

const userId = Effect.map(CurrentUser, ({ user }) => user.id);

/** Thin adapter: decoded request in, service call, domain errors out. */
export const OverviewHttp = HttpApiBuilder.group(
  Api,
  "overview",
  Effect.fn(function* (handlers) {
    const overview = yield* OverviewService;
    return handlers
      .handle("get", ({ query }) =>
        Effect.flatMap(userId, (id) => overview.get(id, query)),
      )
      .handle("months", ({ query }) =>
        Effect.flatMap(userId, (id) => overview.months(id, query)),
      );
  }),
);
