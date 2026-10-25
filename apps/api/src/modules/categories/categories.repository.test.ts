import { Category, CategoryId, CategoryInUse } from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer, Option } from "effect";
import { SqlClient } from "effect/sql";
import { DbLive } from "../../platform/db.ts";
import { CategoriesRepository } from "./categories.repository.ts";

const TestLayer = CategoriesRepository.layer.pipe(Layer.provideMerge(DbLive));
const missing = CategoryId.make("019845e1-682f-4b02-a706-3b2422d13aec");

const newCategory = (name: string) =>
  Category.insert.makeEffect({ name, color: "#ff8800", icon: null });

layer(TestLayer)("CategoriesRepository", (it) => {
  it.effect("inserts, finds and lists ordered by name", () =>
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      yield* sql`DELETE FROM categories`;
      const repo = yield* CategoriesRepository;
      const b = yield* repo.insert(yield* newCategory("banana"));
      const a = yield* repo.insert(yield* newCategory("Apple"));
      assert.deepStrictEqual(Option.getOrNull(yield* repo.findById(a.id)), a);
      assert.deepStrictEqual(yield* repo.list, [a, b]);
    }),
  );

  it.effect("updates an existing row and returns None for a missing one", () =>
    Effect.gen(function* () {
      const repo = yield* CategoriesRepository;
      const created = yield* repo.insert(yield* newCategory("Food"));
      const update = yield* Category.update.makeEffect({
        id: created.id,
        name: "Groceries",
        color: "#00ff00",
        icon: "cart",
      });
      const updated = Option.getOrThrow(yield* repo.update(update));
      assert.strictEqual(updated.name, "Groceries");
      assert.strictEqual(updated.icon, "cart");
      assert.isTrue(
        Option.isNone(yield* repo.update({ ...update, id: missing })),
      );
    }),
  );

  it.effect("remove maps a foreign key violation to CategoryInUse", () =>
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      const repo = yield* CategoriesRepository;
      const created = yield* repo.insert(yield* newCategory("Used"));
      yield* sql`DROP TABLE IF EXISTS category_refs`;
      yield* sql`CREATE TABLE category_refs (
        category_id uuid NOT NULL REFERENCES categories (id) ON DELETE RESTRICT
      )`;
      yield* sql`INSERT INTO category_refs ${sql.insert({ categoryId: created.id })}`;
      const error = yield* repo.remove(created.id).pipe(Effect.flip);
      assert.instanceOf(error, CategoryInUse);
      yield* sql`DROP TABLE category_refs`;
      yield* repo.remove(created.id);
      assert.isTrue(Option.isNone(yield* repo.findById(created.id)));
    }),
  );
});
