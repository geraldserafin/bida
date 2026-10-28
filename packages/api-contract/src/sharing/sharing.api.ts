import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { UserId } from "../auth/user.model.ts";
import { EnvelopeId } from "../envelopes/envelope.model.ts";
import { EnvelopeNotFound, Forbidden } from "../envelopes/envelopes.errors.ts";
import { wire } from "../errors.ts";
import {
  AlreadyMember,
  InvitationNotFound,
  LastOwner,
  LimitReached,
  MemberNotFound,
  NotShareable,
} from "./sharing.errors.ts";
import {
  Contribution,
  Invitation,
  InvitationId,
  Invite,
  Member,
  SetRole,
} from "./sharing.model.ts";

export class MembersApi extends HttpApiGroup.make("members")
  .add(
    HttpApiEndpoint.get("list", "/envelopes/:id/members", {
      params: { id: EnvelopeId },
      success: Schema.Array(Member),
      error: wire(EnvelopeNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List the members of an envelope",
        description:
          "For a sub-envelope these are the members of its parent. Any member can ask.",
      }),
    ),
    HttpApiEndpoint.put("setRole", "/envelopes/:id/members/:userId", {
      params: { id: EnvelopeId, userId: UserId },
      payload: SetRole,
      success: Member,
      error: [
        wire(EnvelopeNotFound),
        wire(Forbidden),
        wire(MemberNotFound),
        wire(LastOwner),
      ],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Change the role of a member",
        description:
          "Owners only. An envelope always keeps at least one owner.",
      }),
    ),
    HttpApiEndpoint.delete("remove", "/envelopes/:id/members/:userId", {
      params: { id: EnvelopeId, userId: UserId },
      error: [
        wire(EnvelopeNotFound),
        wire(Forbidden),
        wire(MemberNotFound),
        wire(LastOwner),
      ],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Remove a member, or leave an envelope",
        description:
          "Owners remove anybody; anybody removes themselves. What a member put into the envelope stays in it, and so do their expenses. An envelope always keeps at least one owner.",
      }),
    ),
    HttpApiEndpoint.get("contributions", "/envelopes/:id/contributions", {
      params: { id: EnvelopeId },
      success: Schema.Array(Contribution),
      error: wire(EnvelopeNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Who put how much into an envelope",
        description:
          "Per member and per envelope: the envelope itself and its sub-envelopes, all time, net of what was taken back.",
      }),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Members" })) {}

export class InvitationsApi extends HttpApiGroup.make("invitations")
  .add(
    HttpApiEndpoint.post("invite", "/envelopes/:id/invitations", {
      params: { id: EnvelopeId },
      payload: Invite,
      success: Invitation.pipe(HttpApiSchema.status(201)),
      error: [
        wire(EnvelopeNotFound),
        wire(Forbidden),
        wire(NotShareable),
        wire(AlreadyMember),
        wire(LimitReached),
      ],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Invite somebody by e-mail",
        description:
          "Owners only, to top-level envelopes. The address gets an e-mail and sees the invitation once signed in with it. Inviting an address again renews its invitation and sets the new role.",
      }),
    ),
    HttpApiEndpoint.get("forEnvelope", "/envelopes/:id/invitations", {
      params: { id: EnvelopeId },
      success: Schema.Array(Invitation),
      error: [wire(EnvelopeNotFound), wire(Forbidden), wire(NotShareable)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List the open invitations of an envelope",
        description:
          "Owners only: those waiting for an answer and those waiting for approval.",
      }),
    ),
    HttpApiEndpoint.delete(
      "revoke",
      "/envelopes/:id/invitations/:invitationId",
      {
        params: { id: EnvelopeId, invitationId: InvitationId },
        error: [
          wire(EnvelopeNotFound),
          wire(Forbidden),
          wire(NotShareable),
          wire(InvitationNotFound),
        ],
      },
    ).annotateMerge(
      OpenApi.annotations({
        summary: "Revoke an invitation, or turn down an accepted one",
        description: "Owners only.",
      }),
    ),
    HttpApiEndpoint.post(
      "approve",
      "/envelopes/:id/invitations/:invitationId/approve",
      {
        params: { id: EnvelopeId, invitationId: InvitationId },
        success: Member,
        error: [
          wire(EnvelopeNotFound),
          wire(Forbidden),
          wire(NotShareable),
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
          "Does not give access yet: an owner of the envelope has to approve it, and is told by e-mail.",
      }),
    ),
    HttpApiEndpoint.post("decline", "/invitations/:invitationId/decline", {
      params: { invitationId: InvitationId },
      error: wire(InvitationNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Decline an invitation" })),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Invitations" })) {}
