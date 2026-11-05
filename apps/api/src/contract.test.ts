import {
  IsoDate,
  MAX_MINOR,
  Money,
  Name,
  NonZeroMoney,
  PositiveMoney,
  Uuid,
} from "@bida/api-contract";
import { assert, it } from "@effect/vitest";
import { Schema } from "effect";

it("ids must be uuids", () => {
  const isId = Schema.is(Uuid);
  assert.isTrue(isId("019845e1-682f-4b02-a706-3b2422d13aec"));
  assert.isFalse(isId("x"));
  assert.isFalse(isId("not-a-uuid"));
  assert.isFalse(isId(""));
});

it("dates must exist", () => {
  const isDate = Schema.is(IsoDate);
  assert.isTrue(isDate("2026-02-28"));
  assert.isTrue(isDate("2028-02-29")); // leap year
  assert.isFalse(isDate("2026-02-31"));
  assert.isFalse(isDate("2026-13-01"));
  assert.isFalse(isDate("2026-1-1"));
  assert.isFalse(isDate("tomorrow"));
});

it("money has bounds", () => {
  assert.isTrue(Schema.is(Money)(0));
  assert.isTrue(Schema.is(Money)(MAX_MINOR));
  assert.isFalse(Schema.is(Money)(-1));
  assert.isFalse(Schema.is(Money)(MAX_MINOR + 1));
  assert.isFalse(Schema.is(Money)(1.5));
  assert.isFalse(Schema.is(PositiveMoney)(0));
  assert.isTrue(Schema.is(NonZeroMoney)(-5));
  assert.isFalse(Schema.is(NonZeroMoney)(0));
  assert.isTrue(Schema.is(PositiveMoney)(1));
});

it("names are bounded", () => {
  assert.isTrue(Schema.is(Name)("a".repeat(200)));
  assert.isFalse(Schema.is(Name)("a".repeat(201)));
  assert.isFalse(Schema.is(Name)(""));
});
