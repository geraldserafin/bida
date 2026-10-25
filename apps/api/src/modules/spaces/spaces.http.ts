import {
  Api,
  CurrentMember,
  CurrentSpace,
  CurrentUser,
  type MySpace,
} from "@bida/api-contract";
import { Effect, Option } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import type { Membership } from "./spaces.repository.ts";
import { SpacesService } from "./spaces.service.ts";

const present = (membership: Membership): MySpace => membership;

/** Thin adapter: decoded request in, service call, domain errors out. */
export const SpacesHttp = HttpApiBuilder.group(
  Api,
  "spaces",
  Effect.fn(function* (handlers) {
    const spaces = yield* SpacesService;
    const me = Effect.map(CurrentUser, ({ user }) => user.id);
    return handlers
      .handle("list", () =>
        Effect.flatMap(me, spaces.listFor).pipe(
          Effect.map((all) => all.map(present)),
        ),
      )
      .handle("create", ({ payload }) =>
        Effect.flatMap(me, (userId) => spaces.createFor(userId, payload)).pipe(
          Effect.map(present),
        ),
      )
      .handle("current", () =>
        Effect.gen(function* () {
          const userId = yield* me;
          const space = yield* CurrentSpace;
          const { role } = yield* CurrentMember;
          const found = yield* spaces.findFor(userId, space.id);
          return {
            space,
            role,
            memberCount: Option.match(found, {
              onNone: () => 1,
              onSome: (m) => m.memberCount,
            }),
          };
        }),
      )
      .handle("update", ({ params, payload }) =>
        Effect.flatMap(me, (userId) =>
          spaces.updateFor(userId, params.id, payload),
        ).pipe(Effect.map(present)),
      )
      .handle("delete", ({ params }) =>
        Effect.flatMap(me, (userId) => spaces.deleteFor(userId, params.id)),
      )
      .handle("members", ({ params }) =>
        Effect.flatMap(me, (userId) => spaces.membersOf(userId, params.id)),
      )
      .handle("setRole", ({ params, payload }) =>
        Effect.flatMap(me, (userId) =>
          spaces.setRoleFor(userId, params.id, params.userId, payload.role),
        ),
      )
      .handle("removeMember", ({ params }) =>
        Effect.flatMap(me, (userId) =>
          spaces.removeMemberFor(userId, params.id, params.userId),
        ),
      )
      .handle("leave", ({ params }) =>
        Effect.flatMap(me, (userId) => spaces.leaveFor(userId, params.id)),
      );
  }),
);
