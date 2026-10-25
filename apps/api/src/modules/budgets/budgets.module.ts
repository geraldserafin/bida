import { Layer } from "effect";
import { CategoriesModule } from "../categories/categories.module.ts";
import { BudgetsRepository } from "./budgets.repository.ts";
import { BudgetsService } from "./budgets.service.ts";

export { BudgetsHttp } from "./budgets.http.ts";
export { BudgetsService } from "./budgets.service.ts";

/**
 * Public surface of the module: exposes `BudgetsService` only. Depends on the
 * categories module and requires `SqlClient`.
 */
export const BudgetsModule = BudgetsService.layer.pipe(
  Layer.provide(BudgetsRepository.layer),
  Layer.provide(CategoriesModule),
);
