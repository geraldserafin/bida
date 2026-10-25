import { Layer } from "effect";
import { IncomesRepository } from "./incomes.repository.ts";
import { IncomesService } from "./incomes.service.ts";

export { IncomesHttp } from "./incomes.http.ts";
export { IncomesService } from "./incomes.service.ts";

/**
 * Public surface of the module: exposes `IncomesService` only. Requires
 * `SqlClient`.
 */
export const IncomesModule = IncomesService.layer.pipe(
  Layer.provide(IncomesRepository.layer),
);
