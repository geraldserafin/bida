import { createServer } from "node:http";
import { NodeHttpServer } from "@effect/platform-node";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { HttpRouter, HttpServer, HttpServerResponse } from "effect/http";
import { bodyLimit, MAX_BODY } from "./http.ts";

const Echo = HttpRouter.add("POST", "/echo", (request) =>
  Effect.map(request.text, (text) =>
    HttpServerResponse.text(String(text.length)),
  ),
);

// a real server on a free port, with the same limit the API uses
const TestServer = HttpRouter.serve(Echo, {
  middleware: bodyLimit,
  disableLogger: true,
  disableListenLog: true,
}).pipe(Layer.provideMerge(NodeHttpServer.layer(createServer, { port: 0 })));

const post = (port: number, size: number) =>
  Effect.promise(() =>
    fetch(`http://localhost:${port}/echo`, {
      method: "POST",
      headers: { "content-type": "text/plain" },
      body: "a".repeat(size),
    }),
  );

layer(TestServer)("request body limit", (it) => {
  it.effect("reads a body below the limit and refuses one above it", () =>
    Effect.gen(function* () {
      const server = yield* HttpServer.HttpServer;
      const port = (server.address as { port: number }).port;

      const small = yield* post(port, 1_000);
      assert.strictEqual(small.status, 200);
      assert.strictEqual(yield* Effect.promise(() => small.text()), "1000");

      const big = yield* post(port, Number(MAX_BODY) + 1_000_000);
      assert.notStrictEqual(big.status, 200);
    }),
  );
});
