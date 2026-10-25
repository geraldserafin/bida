import { Api, CurrentSpace } from "@bida/api-contract";
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
      .handle("list", () => spaces.list)
      .handle("create", ({ payload }) => spaces.create(payload))
      .handle("current", () => CurrentSpace)
      .handle("update", ({ params, payload }) =>
        spaces.update(params.id, payload),
      );
  }),
);
