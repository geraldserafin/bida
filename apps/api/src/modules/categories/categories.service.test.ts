import { CategoryId, CategoryNotFound } from "@bida/api-contract";
import { assert, it } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { CategoriesService } from "./categories.service.ts";
import { CategoriesRepositoryMemory } from "./categories.testing.ts";

const TestLayer = CategoriesService.layer.pipe(
  Layer.provide(CategoriesRepositoryMemory),
);
const missing = CategoryId.make("019845e1-682f-4b02-a706-3b2422d13aec");
const input = { name: "Food", color: "#ff8800", icon: null };

it.effect("creates, gets and lists", () =>
  Effect.gen(function* () {
    const categories = yield* CategoriesService;
    const created = yield* categories.create(input);
    assert.strictEqual(created.name, "Food");
    assert.deepStrictEqual(yield* categories.get(created.id), created);
    assert.deepStrictEqual(yield* categories.list, [created]);
  }).pipe(Effect.provide(TestLayer)),
);

it.effect("updates a category", () =>
  Effect.gen(function* () {
    const categories = yield* CategoriesService;
    const created = yield* categories.create(input);
    const updated = yield* categories.update(created.id, {
      name: "Groceries",
      color: "#00ff00",
      icon: "cart",
    });
    assert.strictEqual(updated.id, created.id);
    assert.strictEqual(updated.name, "Groceries");
    assert.strictEqual(updated.icon, "cart");
  }).pipe(Effect.provide(TestLayer)),
);

it.effect("fails with CategoryNotFound for unknown ids", () =>
  Effect.gen(function* () {
    const categories = yield* CategoriesService;
    const getError = yield* categories.get(missing).pipe(Effect.flip);
    assert.instanceOf(getError, CategoryNotFound);
    const updateError = yield* categories
      .update(missing, input)
      .pipe(Effect.flip);
    assert.instanceOf(updateError, CategoryNotFound);
    const removeError = yield* categories.remove(missing).pipe(Effect.flip);
    assert.instanceOf(removeError, CategoryNotFound);
  }).pipe(Effect.provide(TestLayer)),
);

it.effect("removes a category", () =>
  Effect.gen(function* () {
    const categories = yield* CategoriesService;
    const created = yield* categories.create(input);
    yield* categories.remove(created.id);
    assert.deepStrictEqual(yield* categories.list, []);
  }).pipe(Effect.provide(TestLayer)),
);
