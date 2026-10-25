import { Layer } from "effect";
import { SpaceContextLive } from "./space-context.ts";
import { SpacesRepository } from "./spaces.repository.ts";
import { SpacesService } from "./spaces.service.ts";

export { SpacesHttp } from "./spaces.http.ts";
export { SpacesService } from "./spaces.service.ts";

/**
 * Public surface of the module: exposes `SpacesService`. Requires `SqlClient`.
 */
export const SpacesModule = SpacesService.layer.pipe(
  Layer.provide(SpacesRepository.layer),
);

/**
 * The `SpaceContext` middleware that every space-scoped endpoint is wrapped
 * in. Needs `SpacesService`, so provide it next to `SpacesModule`.
 */
export const SpaceContextModule = SpaceContextLive.pipe(
  Layer.provide(SpacesModule),
);
