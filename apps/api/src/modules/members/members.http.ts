import { Api, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { MembersService } from "./members.service.ts";

const userId = Effect.map(CurrentUser, ({ user }) => user.id);

/** Thin adapter: decoded request in, service call, domain errors out. */
export const MembersHttp = HttpApiBuilder.group(
  Api,
  "members",
  Effect.fn(function* (handlers) {
    const members = yield* MembersService;
    return handlers
      .handle("list", ({ params }) =>
        Effect.flatMap(userId, (id) => members.list(id, params.id)),
      )
      .handle("setRole", ({ params, payload }) =>
        Effect.flatMap(userId, (id) =>
          members.setRole(id, params.id, params.userId, payload.role),
        ),
      )
      .handle("remove", ({ params }) =>
        Effect.flatMap(userId, (id) =>
          members.remove(id, params.id, params.userId),
        ),
      )
      .handle("contributions", ({ params }) =>
        Effect.flatMap(userId, (id) => members.contributions(id, params.id)),
      );
  }),
);
