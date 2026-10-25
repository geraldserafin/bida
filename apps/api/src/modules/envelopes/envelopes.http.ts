import { Api, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { EnvelopesService } from "./envelopes.service.ts";

const userId = Effect.map(CurrentUser, ({ user }) => user.id);

/** Thin adapter: decoded request in, service call, domain errors out. */
export const EnvelopesHttp = HttpApiBuilder.group(
  Api,
  "envelopes",
  Effect.fn(function* (handlers) {
    const envelopes = yield* EnvelopesService;
    return handlers
      .handle("list", () => Effect.flatMap(userId, envelopes.list))
      .handle("get", ({ params }) =>
        Effect.flatMap(userId, (id) => envelopes.get(id, params.id)),
      )
      .handle("create", ({ payload }) =>
        Effect.flatMap(userId, (id) => envelopes.create(id, payload)),
      )
      .handle("update", ({ params, payload }) =>
        Effect.flatMap(userId, (id) =>
          envelopes.update(id, params.id, payload),
        ),
      )
      .handle("delete", ({ params }) =>
        Effect.flatMap(userId, (id) => envelopes.remove(id, params.id)),
      );
  }),
);

export const AllocationsHttp = HttpApiBuilder.group(
  Api,
  "allocations",
  Effect.fn(function* (handlers) {
    const envelopes = yield* EnvelopesService;
    return handlers
      .handle("list", ({ query }) =>
        Effect.flatMap(userId, (id) => envelopes.listAllocations(id, query)),
      )
      .handle("create", ({ payload }) =>
        Effect.flatMap(userId, (id) => envelopes.createAllocation(id, payload)),
      )
      .handle("update", ({ params, payload }) =>
        Effect.flatMap(userId, (id) =>
          envelopes.updateAllocation(id, params.id, payload),
        ),
      )
      .handle("delete", ({ params }) =>
        Effect.flatMap(userId, (id) =>
          envelopes.removeAllocation(id, params.id),
        ),
      );
  }),
);
