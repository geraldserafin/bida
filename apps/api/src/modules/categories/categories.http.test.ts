import { Api, CategoryId } from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { HttpServer } from "effect/http";
import { HttpApiTest } from "effect/http-api";
import { CategoriesHttp } from "./categories.http.ts";
import { CategoriesService } from "./categories.service.ts";
import { CategoriesRepositoryMemory } from "./categories.testing.ts";

const makeClient = HttpApiTest.groups(Api, ["categories"]);
const input = { name: "Food", color: "#ff8800", icon: null };

const TestLayer = CategoriesHttp.pipe(
  Layer.provide(CategoriesService.layer),
  Layer.provide(CategoriesRepositoryMemory),
  Layer.provideMerge(HttpServer.layerServices),
);

layer(TestLayer)("CategoriesHttp", (it) => {
  it.effect("creates and fetches a category", () =>
    Effect.gen(function* () {
      const client = yield* makeClient;
      const created = yield* client.categories.create({ payload: input });
      const fetched = yield* client.categories.get({
        params: { id: created.id },
      });
      assert.deepStrictEqual(fetched, created);
    }),
  );

  it.effect("returns CategoryNotFound for an unknown id", () =>
    Effect.gen(function* () {
      const client = yield* makeClient;
      const error = yield* client.categories
        .get({
          params: {
            id: CategoryId.make("019845e1-682f-4b02-a706-3b2422d13aec"),
          },
        })
        .pipe(Effect.flip);
      assert.strictEqual(error._tag, "CategoryNotFound");
    }),
  );

  it.effect("rejects an invalid color", () =>
    Effect.gen(function* () {
      const client = yield* makeClient;
      const error = yield* client.categories
        .create({ payload: { ...input, color: "red" } })
        .pipe(Effect.flip);
      assert.notStrictEqual(error._tag, "CategoryNotFound");
    }),
  );
});
