import { Schema } from "effect";
import { Model } from "effect/schema";

export const CategoryId = Schema.String.pipe(Schema.brand("CategoryId"));
export type CategoryId = typeof CategoryId.Type;

const HexColor = Schema.String.check(Schema.isPattern(/^#[0-9a-fA-F]{6}$/));

/**
 * One field declaration, many variants: `Category` (db row), `Category.insert`,
 * `Category.update` and the `json*` variants used on the HTTP boundary.
 */
export class Category extends Model.Class<Category>("Category")({
  id: Model.UuidV4Insert(CategoryId),
  name: Schema.NonEmptyString,
  color: HexColor,
  icon: Schema.NullOr(Schema.String),
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}
