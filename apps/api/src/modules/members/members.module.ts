import { Layer } from "effect";
import { EnvelopesModule } from "../envelopes/envelopes.module.ts";
import { MembersRepository } from "./members.repository.ts";
import { MembersService } from "./members.service.ts";

export { MembersHttp } from "./members.http.ts";
export { MembersService } from "./members.service.ts";

/**
 * Public surface of the module: exposes `MembersService` only. Depends on the
 * envelopes module and requires `SqlClient`.
 */
export const MembersModule = MembersService.layer.pipe(
  Layer.provide(MembersRepository.layer),
  Layer.provide(EnvelopesModule),
);
