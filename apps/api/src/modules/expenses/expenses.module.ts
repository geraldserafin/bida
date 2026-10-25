import { Layer } from "effect";
import { BudgetsModule } from "../budgets/budgets.module.ts";
import { ContributionsModule } from "../contributions/contributions.module.ts";
import { ExpensesRepository } from "./expenses.repository.ts";
import { ExpensesService } from "./expenses.service.ts";

export { ExpensesHttp } from "./expenses.http.ts";
export { ExpensesService } from "./expenses.service.ts";

/**
 * Public surface of the module: exposes `ExpensesService` only. Depends on the
 * budgets and contributions modules and requires `SqlClient`.
 */
export const ExpensesModule = ExpensesService.layer.pipe(
  Layer.provide(ExpensesRepository.layer),
  Layer.provide(Layer.mergeAll(BudgetsModule, ContributionsModule)),
);
