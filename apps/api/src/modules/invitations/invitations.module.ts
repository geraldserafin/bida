import { Layer } from "effect";
import { SpacesModule } from "../spaces/spaces.module.ts";
import { InvitationsRepository } from "./invitations.repository.ts";
import { InvitationsService } from "./invitations.service.ts";

export { InvitationsHttp } from "./invitations.http.ts";
export { InvitationsService } from "./invitations.service.ts";

/**
 * Public surface of the module: exposes `InvitationsService`. Depends on spaces
 * and requires `SqlClient` and `Mailer`.
 */
export const InvitationsModule = InvitationsService.layer.pipe(
  Layer.provide(InvitationsRepository.layer),
  Layer.provide(SpacesModule),
);
