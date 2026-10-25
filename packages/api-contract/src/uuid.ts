import { Schema } from "effect";

/** A UUID. Ids are checked at the edge so a malformed one is a 400, not a database error. */
export const Uuid = Schema.String.check(Schema.isUUID());
