import {
  CreateAllocation,
  CreateEnvelope,
  CreateExpense,
  EnvelopeId,
  EnvelopeNotFound,
  ExportDocument,
  ImportLegacy,
  IsoDate,
  MAX_MINOR,
  Money,
  Name,
  NonZeroMoney,
  PositiveMoney,
  wire,
} from "@bida/api-contract";
import { assert, it } from "@effect/vitest";
import { Schema } from "effect";

it("ids must be uuids", () => {
  const isId = Schema.is(EnvelopeId);
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
  // a negative allocation takes money back, zero is no change
  assert.isTrue(Schema.is(NonZeroMoney)(-5));
  assert.isFalse(Schema.is(NonZeroMoney)(0));
  assert.isFalse(Schema.is(NonZeroMoney)(MAX_MINOR + 1));
  assert.isTrue(Schema.is(PositiveMoney)(1));
});

it("names and notes are bounded", () => {
  assert.isTrue(Schema.is(Name)("a".repeat(200)));
  assert.isFalse(Schema.is(Name)("a".repeat(201)));
  assert.isFalse(Schema.is(Name)(""));
  const envelope = Schema.is(CreateEnvelope);
  const look = { parentId: null, color: "#112233", icon: null };
  assert.isFalse(envelope({ ...look, name: "a".repeat(20_000) }));
  assert.isFalse(envelope({ ...look, name: "Home", color: "red" }));
  assert.isTrue(envelope({ ...look, name: "Home" }));
});

it("an allocation needs a real amount and day", () => {
  const allocation = Schema.is(CreateAllocation);
  const ok = {
    envelopeId: "019845e1-682f-4b02-a706-3b2422d13aec",
    amountMinor: 100,
    madeOn: "2026-07-01",
    note: null,
  };
  assert.isTrue(allocation(ok));
  assert.isTrue(allocation({ ...ok, amountMinor: -100 }));
  assert.isFalse(allocation({ ...ok, amountMinor: 0 }));
  assert.isFalse(allocation({ ...ok, madeOn: "2026-02-31" }));
});

it("the documents of an import are bounded", () => {
  const empty = {
    version: 2,
    exportedAt: "2026-07-01T00:00:00Z",
    envelopes: [],
    allocations: [],
    incomes: [],
    expenses: [],
    recurringRules: [],
    recurringIncomes: [],
    allocationRules: [],
  };
  const decodes = (value: unknown) => {
    try {
      Schema.decodeUnknownSync(ExportDocument)(value);
      return true;
    } catch {
      return false;
    }
  };
  assert.isTrue(decodes(empty));
  assert.isFalse(decodes({ ...empty, version: 1 }));
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
  const annotated = wire(EnvelopeNotFound);
  assert.strictEqual(
    Schema.toEncoded(annotated).ast.annotations?.identifier,
    "EnvelopeNotFound",
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
