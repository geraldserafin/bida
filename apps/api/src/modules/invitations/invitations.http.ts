import { Api, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { InvitationsService } from "./invitations.service.ts";

/** Thin adapter: decoded request in, service call, domain errors out. */
export const InvitationsHttp = HttpApiBuilder.group(
  Api,
  "invitations",
  Effect.fn(function* (handlers) {
    const invitations = yield* InvitationsService;
    const me = Effect.map(CurrentUser, ({ user }) => user);
    return handlers
      .handle("invite", ({ params, payload }) =>
        Effect.flatMap(me, (user) =>
          invitations.invite(user.id, params.id, payload.email, payload.role),
        ),
      )
      .handle("forSpace", ({ params }) =>
        Effect.flatMap(me, (user) => invitations.forSpace(user.id, params.id)),
      )
      .handle("revoke", ({ params }) =>
        Effect.flatMap(me, (user) =>
          invitations.revoke(user.id, params.id, params.invitationId),
        ),
      )
      .handle("approve", ({ params }) =>
        Effect.flatMap(me, (user) =>
          invitations.approve(user.id, params.id, params.invitationId),
        ),
      )
      .handle("mine", () =>
        Effect.flatMap(me, (user) => invitations.mine(user.email)),
      )
      .handle("accept", ({ params }) =>
        Effect.flatMap(me, (user) =>
          invitations.accept(user.id, user.email, params.invitationId),
        ),
      )
      .handle("decline", ({ params }) =>
        Effect.flatMap(me, (user) =>
          invitations.decline(user.email, params.invitationId),
        ),
      );
  }),
);
