import { Layer } from "effect";
import { EnvelopesModule } from "../envelopes/envelopes.module.ts";
import { ExpensesModule } from "../expenses/expenses.module.ts";
import { TransferRepository } from "./transfer.repository.ts";
import { TransferService } from "./transfer.service.ts";

export { TransferHttp } from "./transfer.http.ts";
export { TransferService } from "./transfer.service.ts";

/**
 * Public surface of the module: exposes `TransferService` only. Depends on
 * envelopes and expenses and requires `SqlClient`.
 */
export const TransferModule = TransferService.layer.pipe(
  Layer.provide(TransferRepository.layer),
  Layer.provide(Layer.mergeAll(EnvelopesModule, ExpensesModule)),
);
