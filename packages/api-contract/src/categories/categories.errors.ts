import { Schema } from "effect";
import { CategoryId } from "./category.model.ts";

export class CategoryNotFound extends Schema.TaggedError<CategoryNotFound>()(
  "CategoryNotFound",
  { id: CategoryId },
  { httpApiStatus: 404 },
) {}

/** The category is still referenced by an envelope, so it cannot be deleted. */
export class CategoryInUse extends Schema.TaggedError<CategoryInUse>()(
  "CategoryInUse",
  { id: CategoryId },
  { httpApiStatus: 409 },
) {}
