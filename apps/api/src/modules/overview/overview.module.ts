import { Layer } from "effect";
import { OverviewRepository } from "./overview.repository.ts";
import { OverviewService } from "./overview.service.ts";

export { OverviewHttp } from "./overview.http.ts";
export { OverviewService } from "./overview.service.ts";

/**
 * Public surface of the module: exposes `OverviewService` only. Reads the
 * tables directly, so it needs nothing but `SqlClient`.
 */
export const OverviewModule = OverviewService.layer.pipe(
  Layer.provide(OverviewRepository.layer),
);
