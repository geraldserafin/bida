import { Layer } from "effect";
import { EnvelopesRepository } from "./envelopes.repository.ts";
import { EnvelopesService } from "./envelopes.service.ts";

export { AllocationsHttp, EnvelopesHttp } from "./envelopes.http.ts";
export { EnvelopesService } from "./envelopes.service.ts";

/**
 * Public surface of the module: exposes `EnvelopesService` only. The
 * repository is wired in privately. Requires `SqlClient`.
 */
export const EnvelopesModule = EnvelopesService.layer.pipe(
  Layer.provide(EnvelopesRepository.layer),
);
