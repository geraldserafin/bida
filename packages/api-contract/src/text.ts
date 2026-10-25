import { Schema } from "effect";

/** Names of things: not empty, not absurdly long. */
export const Name = Schema.NonEmptyString.check(Schema.isMaxLength(200));

/** Free text such as a note. */
export const Note = Schema.String.check(Schema.isMaxLength(1000));

/** Key of an icon. */
export const IconKey = Schema.String.check(Schema.isMaxLength(50));

/** A calendar date, `YYYY-MM-DD`, that exists (no 31 February). */
export const IsoDate = Schema.String.check(
  Schema.isPattern(/^\d{4}-\d{2}-\d{2}$/),
  Schema.makeFilter(
    (text) => {
      const [y, m, d] = text.split("-").map(Number) as [number, number, number];
      const date = new Date(Date.UTC(y, m - 1, d));
      return (
        (date.getUTCFullYear() === y &&
          date.getUTCMonth() === m - 1 &&
          date.getUTCDate() === d) ||
        "a calendar date that exists"
      );
    },
    { expected: "a calendar date that exists" },
  ),
);
