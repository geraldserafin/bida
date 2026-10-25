import { Api } from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { HttpServer } from "effect/http";
import { HttpApiTest } from "effect/http-api";
import { SystemHttp } from "./system.module.ts";

const makeClient = HttpApiTest.groups(Api, ["system"]);

layer(Layer.mergeAll(SystemHttp, HttpServer.layerServices))(
  "SystemHttp",
  (it) => {
    it.effect("health reports ok", () =>
      Effect.gen(function* () {
        const client = yield* makeClient;
        const health = yield* client.system.health();
        assert.strictEqual(health.status, "ok");
        assert.isAtLeast(health.uptimeSeconds, 0);
      }),
    );
  },
);
