import { Layer } from "effect";
import { CategoriesRepository } from "./categories.repository.ts";
import { CategoriesService } from "./categories.service.ts";

export { CategoriesHttp } from "./categories.http.ts";
export { CategoriesService } from "./categories.service.ts";

/**
 * Public surface of the module: exposes `CategoriesService` only. The
 * repository is wired in privately, so other modules cannot depend on it.
 * Requires `SqlClient`.
 */
export const CategoriesModule = CategoriesService.layer.pipe(
  Layer.provide(CategoriesRepository.layer),
);
