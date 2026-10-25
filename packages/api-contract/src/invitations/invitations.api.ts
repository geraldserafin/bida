import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { wire } from "../errors.ts";
import { Member, SpaceId } from "../spaces/space.model.ts";
import {
  Forbidden,
  LimitReached,
  PersonalSpace,
  SpaceNotFound,
} from "../spaces/spaces.errors.ts";
import { Invitation, InvitationId, Invite } from "./invitation.model.ts";
import { AlreadyMember, InvitationNotFound } from "./invitations.errors.ts";

export class InvitationsApi extends HttpApiGroup.make("invitations")
  .add(
    HttpApiEndpoint.post("invite", "/spaces/:id/invitations", {
      params: { id: SpaceId },
      payload: Invite,
      success: Invitation.pipe(HttpApiSchema.status(201)),
      error: [
        wire(SpaceNotFound),
        wire(Forbidden),
        wire(PersonalSpace),
        wire(AlreadyMember),
        wire(LimitReached),
      ],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Invite somebody by e-mail",
        description:
          "Owners only, to shared spaces. The address gets an e-mail and sees the invitation once signed in with it. Inviting an address again renews its invitation and sets the new role.",
      }),
    ),
    HttpApiEndpoint.get("forSpace", "/spaces/:id/invitations", {
      params: { id: SpaceId },
      success: Schema.Array(Invitation),
      error: [wire(SpaceNotFound), wire(Forbidden)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List the open invitations of a space",
        description:
          "Owners only: those waiting for an answer and those waiting for approval.",
      }),
    ),
    HttpApiEndpoint.delete("revoke", "/spaces/:id/invitations/:invitationId", {
      params: { id: SpaceId, invitationId: InvitationId },
      error: [wire(SpaceNotFound), wire(Forbidden), wire(InvitationNotFound)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Revoke an invitation, or turn down an accepted one",
        description: "Owners only.",
      }),
    ),
    HttpApiEndpoint.post(
      "approve",
      "/spaces/:id/invitations/:invitationId/approve",
      {
        params: { id: SpaceId, invitationId: InvitationId },
        success: Member,
        error: [
          wire(SpaceNotFound),
          wire(Forbidden),
          wire(InvitationNotFound),
          wire(LimitReached),
        ],
      },
    ).annotateMerge(
      OpenApi.annotations({
        summary: "Let in somebody who accepted an invitation",
        description: "Owners only. The person becomes a member.",
      }),
    ),
    HttpApiEndpoint.get("mine", "/invitations", {
      success: Schema.Array(Invitation),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Invitations for my address",
        description: "Only those still waiting for my answer.",
      }),
    ),
    HttpApiEndpoint.post("accept", "/invitations/:invitationId/accept", {
      params: { invitationId: InvitationId },
      success: Invitation,
      error: wire(InvitationNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Accept an invitation",
        description:
          "Does not give access yet: an owner of the space has to approve it, and is told by e-mail.",
      }),
    ),
    HttpApiEndpoint.post("decline", "/invitations/:invitationId/decline", {
      params: { invitationId: InvitationId },
      error: wire(InvitationNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Decline an invitation" })),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Invitations" })) {}
