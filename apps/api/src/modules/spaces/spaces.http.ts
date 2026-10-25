import { Api, CurrentSpace, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { SpacesService } from "./spaces.service.ts";

/** Thin adapter: decoded request in, service call, domain errors out. */
export const SpacesHttp = HttpApiBuilder.group(
  Api,
  "spaces",
  Effect.fn(function* (handlers) {
    const spaces = yield* SpacesService;
    return handlers
      .handle("list", () =>
        Effect.flatMap(CurrentUser, ({ user }) => spaces.listFor(user.id)),
      )
      .handle("create", ({ payload }) =>
        Effect.flatMap(CurrentUser, ({ user }) =>
          spaces.createFor(user.id, payload),
        ),
      )
      .handle("current", () => CurrentSpace)
      .handle("update", ({ params, payload }) =>
        Effect.flatMap(CurrentUser, ({ user }) =>
          spaces.updateFor(user.id, params.id, payload),
        ),
      );
  }),
);
