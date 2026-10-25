import { Layer } from "effect";
import { EnvelopesModule } from "../envelopes/envelopes.module.ts";
import { MembersModule } from "../members/members.module.ts";
import { InvitationsRepository } from "./invitations.repository.ts";
import { InvitationsService } from "./invitations.service.ts";

export { InvitationsHttp } from "./invitations.http.ts";
export { InvitationsService } from "./invitations.service.ts";

/**
 * Public surface of the module: exposes `InvitationsService`. Depends on
 * envelopes and members and requires `SqlClient` and `Mailer`.
 */
export const InvitationsModule = InvitationsService.layer.pipe(
  Layer.provide(InvitationsRepository.layer),
  Layer.provide(Layer.mergeAll(EnvelopesModule, MembersModule)),
);
