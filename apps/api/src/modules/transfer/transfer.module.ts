import { Layer } from "effect";
import { BudgetsModule } from "../budgets/budgets.module.ts";
import { CategoriesModule } from "../categories/categories.module.ts";
import { ExpensesModule } from "../expenses/expenses.module.ts";
import { TransferRepository } from "./transfer.repository.ts";
import { TransferService } from "./transfer.service.ts";

export { TransferHttp } from "./transfer.http.ts";
export { TransferService } from "./transfer.service.ts";

/**
 * Public surface of the module: exposes `TransferService` only. Depends on
 * categories, budgets and expenses and requires `SqlClient`.
 */
export const TransferModule = TransferService.layer.pipe(
  Layer.provide(TransferRepository.layer),
  Layer.provide(
    Layer.mergeAll(CategoriesModule, BudgetsModule, ExpensesModule),
  ),
);
