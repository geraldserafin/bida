import { Layer } from "effect";
import { BudgetsModule } from "../budgets/budgets.module.ts";
import { ContributionsRepository } from "./contributions.repository.ts";
import { ContributionsService } from "./contributions.service.ts";

export { ContributionsHttp } from "./contributions.http.ts";
export { ContributionsService } from "./contributions.service.ts";

/**
 * Public surface of the module: exposes `ContributionsService` only. Depends
 * on the budgets module and requires `SqlClient`.
 */
export const ContributionsModule = ContributionsService.layer.pipe(
  Layer.provide(ContributionsRepository.layer),
  Layer.provide(BudgetsModule),
);
