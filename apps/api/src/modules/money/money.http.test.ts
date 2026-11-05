import { Api, User } from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer } from "effect";
import { HttpServer } from "effect/http";
import { HttpApiTest } from "effect/http-api";
import { SqlClient } from "effect/sql";
import { DbLive } from "../../platform/db.ts";
import {
  resetDb,
  TestAuthenticated,
  TestMailer,
} from "../../platform/testing.ts";
import { MoneyHttp } from "./money.module.ts";

const makeClient = HttpApiTest.groups(Api, [
  "sync",
  "wallet",
  "households",
  "envelopes",
  "expenses",
]);

// every request is made by this user; the row is inserted by the test
const ann = new User({
  id: "00000000-0000-4000-8000-0000000000a1" as User["id"],
  email: "ann-http@example.com",
  name: "Ann",
  createdAt: DateTime.makeUnsafe(0),
});

layer(
  Layer.mergeAll(MoneyHttp, HttpServer.layerServices).pipe(
    Layer.provideMerge(
      Layer.mergeAll(TestAuthenticated(ann), DbLive, TestMailer),
    ),
  ),
)("MoneyHttp", (it) => {
  it.effect("the app start, a household and a 409 that says what to do", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const sql = yield* SqlClient.SqlClient;
      yield* sql`INSERT INTO users (id, email, name, created_at)
        VALUES (${ann.id}, ${ann.email}, 'Ann', now())`;
      const client = yield* makeClient;

      const synced = yield* client.sync.run();
      assert.strictEqual(synced.todo, 0);

      const home = yield* client.households.create({
        payload: { name: "Dom" },
      });
      assert.strictEqual(home.current.status, "current");
      yield* client.wallet.addIncome({
        payload: {
          amountMinor: 10_000,
          onDate: home.current.startsOn,
          note: null,
          estimated: false,
        },
      });
      yield* client.households.transfer({
        params: { id: home.current.id },
        payload: { amountMinor: 1_000 },
      });
      const [food] = yield* client.envelopes.list({ params: { id: home.id } });
      if (food === undefined) return yield* Effect.die("no envelope");
      const error = yield* client.expenses
        .create({
          params: { id: home.id },
          payload: {
            envelopeId: food.id,
            amountMinor: 2_000,
            spentAt: DateTime.makeUnsafe(new Date()),
            title: null,
            forWhom: null,
            forWhomUserId: null,
          },
        })
        .pipe(Effect.flip);
      assert.strictEqual(error._tag, "PlanTooSmall");
      if (error._tag === "PlanTooSmall")
        assert.strictEqual(error.transferMinor, 1_000);
    }),
  );
});
