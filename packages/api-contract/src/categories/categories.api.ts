import { Schema } from "effect";
import { HttpApiEndpoint, HttpApiGroup, OpenApi } from "effect/http-api";
import { CategoryInUse, CategoryNotFound } from "./categories.errors.ts";
import { Category, CategoryId } from "./category.model.ts";

export class CategoriesApi extends HttpApiGroup.make("categories")
  .add(
    HttpApiEndpoint.get("list", "/", {
      success: Schema.Array(Category.json),
    }).annotateMerge(OpenApi.annotations({ summary: "List categories" })),
    HttpApiEndpoint.get("get", "/:id", {
      params: { id: CategoryId },
      success: Category.json,
      error: CategoryNotFound,
    }).annotateMerge(OpenApi.annotations({ summary: "Get a category" })),
    HttpApiEndpoint.post("create", "/", {
      payload: Category.jsonCreate,
      success: Category.json,
    }).annotateMerge(OpenApi.annotations({ summary: "Create a category" })),
    HttpApiEndpoint.patch("update", "/:id", {
      params: { id: CategoryId },
      payload: Category.jsonUpdate,
      success: Category.json,
      error: CategoryNotFound,
    }).annotateMerge(OpenApi.annotations({ summary: "Update a category" })),
    HttpApiEndpoint.delete("delete", "/:id", {
      params: { id: CategoryId },
      error: [CategoryNotFound, CategoryInUse],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete a category",
        description:
          "Fails with 409 while any envelope still uses the category.",
      }),
    ),
  )
  .prefix("/categories")
  .annotateMerge(OpenApi.annotations({ title: "Categories" })) {}
