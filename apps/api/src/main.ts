import { createServer } from "node:http";
import { Api } from "@bida/api-contract";
import { NodeHttpServer, NodeRuntime } from "@effect/platform-node";
import { Effect, Layer } from "effect";
import { HttpRouter } from "effect/http";
import { HttpApiBuilder } from "effect/http-api";
import {
  CategoriesHttp,
  CategoriesModule,
} from "./modules/categories/categories.module.ts";
import { SystemHttp } from "./modules/system/system.module.ts";
import { AppConfig } from "./platform/config.ts";
import { DbLive } from "./platform/db.ts";

// Domain modules: each exposes its services, they may depend on each other.
const Modules = Layer.mergeAll(CategoriesModule);

const ApiRoutes = HttpApiBuilder.layer(Api, {
  openapiPath: "/openapi.json",
}).pipe(
  Layer.provide([SystemHttp, CategoriesHttp]),
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
