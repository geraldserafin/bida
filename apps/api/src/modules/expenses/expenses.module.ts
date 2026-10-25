import { Layer } from "effect";
import { BudgetsModule } from "../budgets/budgets.module.ts";
import { ExpensesRepository } from "./expenses.repository.ts";
import { ExpensesService } from "./expenses.service.ts";

export { ExpensesHttp } from "./expenses.http.ts";
export { ExpensesService } from "./expenses.service.ts";

/**
 * Public surface of the module: exposes `ExpensesService` only. Depends on the
 * budgets module and requires `SqlClient`.
 */
export const ExpensesModule = ExpensesService.layer.pipe(
  Layer.provide(ExpensesRepository.layer),
  Layer.provide(BudgetsModule),
);
