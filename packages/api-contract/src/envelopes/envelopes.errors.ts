import { Schema } from "effect";
import { AllocationId } from "./allocation.model.ts";
import { EnvelopeId } from "./envelope.model.ts";

/** The envelope does not exist or is not visible to the user. */
export class EnvelopeNotFound extends Schema.TaggedError<EnvelopeNotFound>()(
  "EnvelopeNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

export class AllocationNotFound extends Schema.TaggedError<AllocationNotFound>()(
  "AllocationNotFound",
  { id: AllocationId },
  { httpApiStatus: 404 },
) {}

/** The user may see this, but not change it. */
export class Forbidden extends Schema.TaggedError<Forbidden>()(
  "Forbidden",
  {},
  { httpApiStatus: 403 },
) {}

/** A sub-envelope can only be put under a top-level envelope. */
export class ParentMustBeTopLevel extends Schema.TaggedError<ParentMustBeTopLevel>()(
  "ParentMustBeTopLevel",
  { parentId: EnvelopeId },
  { httpApiStatus: 422 },
) {}

/**
 * The change would take more out of an envelope than is free in it, or assign
 * more to sub-envelopes than the user put into the parent.
 */
export class NotEnoughMoney extends Schema.TaggedError<NotEnoughMoney>()(
  "NotEnoughMoney",
  { envelopeId: EnvelopeId, availableMinor: Schema.Int },
  { httpApiStatus: 409 },
) {}
