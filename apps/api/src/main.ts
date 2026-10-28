import { createServer } from "node:http";
import { Api } from "@bida/api-contract";
import { NodeHttpServer, NodeRuntime } from "@effect/platform-node";
import { Effect, Layer } from "effect";
import { HttpRouter } from "effect/http";
import { HttpApiBuilder } from "effect/http-api";
import {
  AuthenticatedModule,
  AuthHttp,
  AuthModule,
  GoogleVerifier,
} from "./modules/auth/auth.module.ts";
import {
  AllocationsHttp,
  EnvelopesHttp,
  EnvelopesModule,
} from "./modules/envelopes/envelopes.module.ts";
import {
  ExpensesHttp,
  ExpensesModule,
} from "./modules/expenses/expenses.module.ts";
import {
  IncomesHttp,
  IncomesModule,
} from "./modules/incomes/incomes.module.ts";
import {
  InvitationsHttp,
  InvitationsModule,
} from "./modules/invitations/invitations.module.ts";
import {
  MembersHttp,
  MembersModule,
} from "./modules/members/members.module.ts";
import {
  OverviewHttp,
  OverviewModule,
} from "./modules/overview/overview.module.ts";
import {
  AllocationRulesHttp,
  RecurringHttp,
  RecurringIncomesHttp,
  RecurringModule,
} from "./modules/recurring/recurring.module.ts";
import { SystemHttp } from "./modules/system/system.module.ts";
import {
  TransferHttp,
  TransferModule,
} from "./modules/transfer/transfer.module.ts";
import { AppConfig } from "./platform/config.ts";
import { DbLive } from "./platform/db.ts";
import { bodyLimit, corsFor } from "./platform/http.ts";
import { Mailer } from "./platform/mailer.ts";

// Domain modules: each exposes its services, they may depend on each other.
const Modules = Layer.mergeAll(
  EnvelopesModule,
  MembersModule,
  InvitationsModule,
  IncomesModule,
  ExpensesModule,
  RecurringModule,
  OverviewModule,
  TransferModule,
  AuthModule,
);

// The handlers of every group behind a sign-in are wrapped in the
// Authenticated middleware, so it has to be available to them and to the
// router.
const Handlers = Layer.mergeAll(
  SystemHttp,
  AuthHttp,
  EnvelopesHttp,
  AllocationsHttp,
  MembersHttp,
  InvitationsHttp,
  IncomesHttp,
  ExpensesHttp,
  RecurringHttp,
  RecurringIncomesHttp,
  AllocationRulesHttp,
  OverviewHttp,
  TransferHttp,
).pipe(Layer.provideMerge(AuthenticatedModule));

const ApiRoutes = HttpApiBuilder.layer(Api, {
  openapiPath: "/openapi.json",
}).pipe(
  Layer.provide(Handlers),
  Layer.provide(Modules),
  Layer.provide(Mailer.layer),
  Layer.provide(GoogleVerifier.layer),
  Layer.provide(DbLive),
);

const Server = Layer.unwrap(
  AppConfig.pipe(
    Effect.map(({ port, corsOrigins }) =>
      HttpRouter.serve(ApiRoutes, {
        middleware: (app) => bodyLimit(corsFor(corsOrigins)(app)),
      }).pipe(Layer.provide(NodeHttpServer.layer(createServer, { port }))),
    ),
  ),
);

Layer.launch(Server).pipe(NodeRuntime.runMain);
