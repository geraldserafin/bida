import { Context, Schema } from "effect";
import { Model } from "effect/schema";
import { Currency } from "../currency/index.ts";

export const SpaceId = Schema.String.pipe(Schema.brand("SpaceId"));
export type SpaceId = typeof SpaceId.Type;

/**
 * A budget space: everything else (categories, periods, expenses, rules) lives
 * in exactly one space. Sharing a budget will mean sharing a space. A fresh
 * installation has one default space.
 */
export class Space extends Model.Class<Space>("Space")({
  id: Model.UuidV4Insert(SpaceId),
  name: Schema.NonEmptyString,
  /** Currency of new periods and recurring rules when none is chosen. */
  defaultCurrency: Currency,
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const SpaceJson = Space.json.annotate({ identifier: "Space" });

export const SaveSpace = Schema.Struct({
  name: Schema.NonEmptyString,
  defaultCurrency: Currency,
}).annotate({ identifier: "SaveSpace" });
export type SaveSpace = typeof SaveSpace.Type;

/** The space the current request works in. Provided by `SpaceContext`. */
export class CurrentSpace extends Context.Service<CurrentSpace, Space>()(
  "bida/spaces/CurrentSpace",
) {}

/** Id of the space that exists from the start and is used by default. */
export const DEFAULT_SPACE_ID =
  "00000000-0000-4000-8000-000000000001" as SpaceId;
