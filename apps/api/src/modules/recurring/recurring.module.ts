import { Layer } from "effect";
import { BudgetsModule } from "../budgets/budgets.module.ts";
import { CategoriesModule } from "../categories/categories.module.ts";
import { ExpensesModule } from "../expenses/expenses.module.ts";
import { RecurringRepository } from "./recurring.repository.ts";
import { RecurringService } from "./recurring.service.ts";

export { RecurringHttp } from "./recurring.http.ts";
export { RecurringService } from "./recurring.service.ts";

/**
 * Public surface of the module: exposes `RecurringService` only. Depends on
 * categories, budgets and expenses and requires `SqlClient`.
 */
export const RecurringModule = RecurringService.layer.pipe(
  Layer.provide(RecurringRepository.layer),
  Layer.provide(
    Layer.mergeAll(CategoriesModule, BudgetsModule, ExpensesModule),
  ),
);
