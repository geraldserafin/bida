import { Schema } from "effect";
import { Model } from "effect/schema";
import { UserId } from "../auth/user.model.ts";
import { NonZeroMoney } from "../money.ts";
import { IsoDate, Note } from "../text.ts";
import { Uuid } from "../uuid.ts";
import { EnvelopeId } from "./envelope.model.ts";

export const AllocationId = Uuid.pipe(Schema.brand("AllocationId"));
export type AllocationId = typeof AllocationId.Type;

const ServerUser = Model.Field({
  select: UserId,
  insert: UserId,
  update: UserId,
  json: UserId,
});

/**
 * Money a user puts into an envelope (`amountMinor` > 0) or takes back out
 * (< 0). On a top-level envelope it comes out of the user's pool of income; on
 * a sub-envelope it moves part of what the same user put into the parent.
 */
export class Allocation extends Model.Class<Allocation>("Allocation")({
  id: Model.UuidV4Insert(AllocationId),
  envelopeId: EnvelopeId,
  userId: ServerUser,
  amountMinor: NonZeroMoney,
  madeOn: IsoDate,
  note: Schema.NullOr(Note),
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const AllocationJson = Allocation.json.annotate({
  identifier: "Allocation",
});

export const CreateAllocation = Schema.Struct({
  envelopeId: EnvelopeId,
  amountMinor: NonZeroMoney,
  madeOn: IsoDate,
  note: Schema.NullOr(Note),
}).annotate({ identifier: "CreateAllocation" });
export type CreateAllocation = typeof CreateAllocation.Type;

/** The envelope of an allocation does not change; delete it and add another. */
export const UpdateAllocation = Schema.Struct({
  amountMinor: NonZeroMoney,
  madeOn: IsoDate,
  note: Schema.NullOr(Note),
}).annotate({ identifier: "UpdateAllocation" });
export type UpdateAllocation = typeof UpdateAllocation.Type;
