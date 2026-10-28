import { Layer } from "effect";
import { EnvelopesModule } from "../envelopes/envelopes.module.ts";
import { ExpensesModule } from "../expenses/expenses.module.ts";
import { IncomesModule } from "../incomes/incomes.module.ts";
import { RecurringRepository } from "./recurring.repository.ts";
import { RecurringService } from "./recurring.service.ts";
import {
  AllocationRulesRepository,
  RecurringIncomesRepository,
} from "./rules.repository.ts";

export {
  AllocationRulesHttp,
  RecurringHttp,
  RecurringIncomesHttp,
} from "./recurring.http.ts";
export { RecurringService } from "./recurring.service.ts";

/**
 * Public surface of the module: exposes `RecurringService` only. Depends on
 * envelopes, expenses and incomes and requires `SqlClient`.
 */
export const RecurringModule = RecurringService.layer.pipe(
  Layer.provide(
    Layer.mergeAll(
      RecurringRepository.layer,
      RecurringIncomesRepository.layer,
      AllocationRulesRepository.layer,
    ),
  ),
  Layer.provide(Layer.mergeAll(EnvelopesModule, ExpensesModule, IncomesModule)),
);
