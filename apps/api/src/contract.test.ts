import {
  CategoryId,
  CategoryNotFound,
  CreateExpense,
  CreatePeriod,
  ImportLegacy,
  IsoDate,
  MAX_MINOR,
  Money,
  Name,
  PositiveMoney,
  SaveSpace,
  wire,
} from "@bida/api-contract";
import { assert, it } from "@effect/vitest";
import { Schema } from "effect";

it("ids must be uuids", () => {
  const isId = Schema.is(CategoryId);
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
  assert.isTrue(Schema.is(PositiveMoney)(1));
});

it("names and notes are bounded", () => {
  assert.isTrue(Schema.is(Name)("a".repeat(200)));
  assert.isFalse(Schema.is(Name)("a".repeat(201)));
  assert.isFalse(Schema.is(Name)(""));
  const space = Schema.is(SaveSpace);
  assert.isFalse(space({ name: "a".repeat(20_000), defaultCurrency: "PLN" }));
  assert.isFalse(space({ name: "Home", defaultCurrency: "XXX" }));
  assert.isTrue(space({ name: "Home", defaultCurrency: "EUR" }));
});

it("payload arrays are bounded", () => {
  const entry = {
    categoryId: "019845e1-682f-4b02-a706-3b2422d13aec",
    plannedMinor: 1,
  };
  const period = (count: number) =>
    Schema.is(CreatePeriod)({
      name: "x",
      startDate: "2026-07-01",
      endDate: "2026-07-31",
      incomeMinor: 1,
      envelopes: Array.from({ length: count }, () => entry),
    });
  assert.isTrue(period(500));
  assert.isFalse(period(501));
});

it("an expense note is bounded", () => {
  // the request side: spentAt arrives as a string
  const accepts = (note: string) => {
    try {
      Schema.decodeUnknownSync(CreateExpense)({
        envelopeId: "019845e1-682f-4b02-a706-3b2422d13aec",
        amountMinor: 1,
        spentAt: "2026-07-03T10:00:00Z",
        note,
      });
      return true;
    } catch {
      return false;
    }
  };
  assert.isTrue(accepts("a".repeat(1000)));
  assert.isFalse(accepts("a".repeat(1001)));
});

it("wire() names the response schema after the error class", () => {
  const annotated = wire(CategoryNotFound);
  assert.strictEqual(
    Schema.toEncoded(annotated).ast.annotations?.identifier,
    "CategoryNotFound",
  );
});

it("accepts the backup the mobile app builds from its old database", () => {
  // the payload of the app's `LegacyMigrator`, as its tests assert it
  const sent = {
    backup: {
      version: 1,
      data: {
        periods: [
          {
            id: 1,
            name: "July",
            start_date: "2026-07-01T00:00:00.000",
            end_date: "2026-07-31T00:00:00.000",
            income: 5000.5,
          },
        ],
        categories: [
          { id: 1, name: "Food", color: "#22C55E", icon: "restaurant" },
        ],
        recurring_rules: [
          {
            id: 1,
            category_id: 1,
            amount: 99.99,
            frequency: "monthly",
            note: "Gym",
            active: 1,
          },
        ],
        splits: [
          { id: 1, period_id: 1, category_id: 1, planned_amount: 1200.25 },
        ],
        expenses: [
          {
            id: 1,
            split_id: 1,
            amount: 45.99,
            date: "2026-07-03T10:30:00.000",
            note: "Biedronka",
            recurring_id: 1,
          },
        ],
      },
    },
  };
  assert.doesNotThrow(() => Schema.decodeUnknownSync(ImportLegacy)(sent));
});
