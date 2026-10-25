import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { wire } from "../errors.ts";
import { SpaceContext } from "../spaces/space-context.ts";
import { CategoryInUse, CategoryNotFound } from "./categories.errors.ts";
import {
  CategoryId,
  CategoryJson,
  CreateCategory,
  UpdateCategory,
} from "./category.model.ts";

export class CategoriesApi extends HttpApiGroup.make("categories")
  .add(
    HttpApiEndpoint.get("list", "/", {
      success: Schema.Array(CategoryJson),
    }).annotateMerge(OpenApi.annotations({ summary: "List categories" })),
    HttpApiEndpoint.get("get", "/:id", {
      params: { id: CategoryId },
      success: CategoryJson,
      error: wire(CategoryNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Get a category" })),
    HttpApiEndpoint.post("create", "/", {
      payload: CreateCategory,
      success: CategoryJson.pipe(HttpApiSchema.status(201)),
    }).annotateMerge(OpenApi.annotations({ summary: "Create a category" })),
    HttpApiEndpoint.put("update", "/:id", {
      params: { id: CategoryId },
      payload: UpdateCategory,
      success: CategoryJson,
      error: wire(CategoryNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Update a category" })),
    HttpApiEndpoint.delete("delete", "/:id", {
      params: { id: CategoryId },
      error: [wire(CategoryNotFound), wire(CategoryInUse)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete a category",
        description:
          "Fails with 409 while any envelope still uses the category.",
      }),
    ),
  )
  .prefix("/categories")
  .middleware(SpaceContext)
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Categories" })) {}
