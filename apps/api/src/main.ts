import { createServer } from "node:http";
import { Api } from "@bida/api-contract";
import { NodeHttpServer, NodeRuntime } from "@effect/platform-node";
import { Effect, Layer } from "effect";
import { HttpRouter } from "effect/http";
import { HttpApiBuilder } from "effect/http-api";
import { SystemHttp } from "./modules/system/system.module.ts";
import { AppConfig } from "./platform/config.ts";
import { DbLive } from "./platform/db.ts";

// Domain modules (services) go here as they are added.
const Modules = Layer.empty;

const ApiRoutes = HttpApiBuilder.layer(Api, {
  openapiPath: "/openapi.json",
}).pipe(
  Layer.provide([SystemHttp]),
  Layer.provide(Modules),
  Layer.provide(DbLive),
);

const Server = Layer.unwrap(
  AppConfig.pipe(
    Effect.map(({ port }) =>
      HttpRouter.serve(ApiRoutes).pipe(
        Layer.provide(NodeHttpServer.layer(createServer, { port })),
      ),
    ),
  ),
);

Layer.launch(Server).pipe(NodeRuntime.runMain);
