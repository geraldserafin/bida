import { Schema } from "effect";
import { Model } from "effect/schema";
import { UserId } from "../auth/user.model.ts";
import { IconKey, Name } from "../text.ts";
import { Uuid } from "../uuid.ts";

export const EnvelopeId = Uuid.pipe(Schema.brand("EnvelopeId"));
export type EnvelopeId = typeof EnvelopeId.Type;

export const HexColor = Schema.String.check(
  Schema.isPattern(/^#[0-9a-fA-F]{6}$/),
);

/** What a member may do in an envelope. */
export const Role = Schema.Literals(["owner", "member"]).annotate({
  identifier: "Role",
  description:
    "`owner` manages the envelope and its members; `member` works with the money in it.",
});
export type Role = typeof Role.Type;

// set by the server from the signed-in user, never taken from a request
const ServerUser = Model.Field({
  select: UserId,
  insert: UserId,
  update: UserId,
  json: UserId,
});

/**
 * Money is kept in envelopes. An envelope is either top-level or a
 * sub-envelope of a top-level one (`parentId`); there are no deeper levels.
 */
export class Envelope extends Model.Class<Envelope>("Envelope")({
  id: Model.UuidV4Insert(EnvelopeId),
  ownerId: ServerUser,
  parentId: Schema.NullOr(EnvelopeId),
  name: Name,
  color: HexColor,
  icon: Schema.NullOr(IconKey),
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const EnvelopeJson = Envelope.json.annotate({ identifier: "Envelope" });

export const CreateEnvelope = Schema.Struct({
  /** Makes this a sub-envelope. It has to be a top-level envelope. */
  parentId: Schema.NullOr(EnvelopeId),
  name: Name,
  color: HexColor,
  icon: Schema.NullOr(IconKey),
}).annotate({ identifier: "CreateEnvelope" });
export type CreateEnvelope = typeof CreateEnvelope.Type;

/** An envelope keeps its place in the tree; only how it looks changes. */
export const UpdateEnvelope = Schema.Struct({
  name: Name,
  color: HexColor,
  icon: Schema.NullOr(IconKey),
}).annotate({ identifier: "UpdateEnvelope" });
export type UpdateEnvelope = typeof UpdateEnvelope.Type;
