import {
  CreateHousehold,
  CreateIncome,
  Cycle,
  IsoDate,
  MAX_MINOR,
  Money,
  Name,
  NonZeroMoney,
  PlanTooSmall,
  PositiveMoney,
  SaveEnvelope,
  SaveExpense,
  Uuid,
  wire,
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

it("an income is positive, with at most a 200-character note (F31)", () => {
  const ok = {
    amountMinor: 1,
    onDate: "2026-11-05",
    note: null,
    estimated: true,
  };
  assert.isTrue(Schema.is(CreateIncome)(ok));
  assert.isFalse(Schema.is(CreateIncome)({ ...ok, amountMinor: 0 }));
  assert.isFalse(Schema.is(CreateIncome)({ ...ok, note: "a".repeat(201) }));
});

it("a household name is 1-50 characters, an envelope name 1-30 (F05, F12)", () => {
  assert.isTrue(Schema.is(CreateHousehold)({ name: "Dom" }));
  assert.isFalse(Schema.is(CreateHousehold)({ name: "" }));
  assert.isFalse(Schema.is(CreateHousehold)({ name: "a".repeat(51) }));
  const envelope = { color: "#112233", icon: null };
  assert.isTrue(Schema.is(SaveEnvelope)({ ...envelope, name: "a".repeat(30) }));
  assert.isFalse(
    Schema.is(SaveEnvelope)({ ...envelope, name: "a".repeat(31) }),
  );
});

it("a cycle day is 1-31 and weeks 1-52 (F24)", () => {
  const cycle = { kind: "monthly", day: 31, weeks: null, anchorOn: null };
  assert.isTrue(Schema.is(Cycle)(cycle));
  assert.isFalse(Schema.is(Cycle)({ ...cycle, day: 32 }));
  assert.isFalse(Schema.is(Cycle)({ ...cycle, kind: "weeks", weeks: 53 }));
});

it("wire() names the response schema after the error class", () => {
  const annotated = wire(PlanTooSmall);
  assert.strictEqual(
    Schema.toEncoded(annotated).ast.annotations?.identifier,
    "PlanTooSmall",
  );
});

it("optional fields also take null (the Dart client sends them)", () => {
  const decodes = (schema: Schema.Top, value: unknown) => {
    try {
      Schema.decodeUnknownSync(schema as never)(value);
      return true;
    } catch {
      return false;
    }
  };
  assert.isTrue(
    decodes(CreateHousehold, {
      name: "Dom",
      cycle: null,
      firstEndsOn: null,
      timeZone: null,
      envelopes: null,
    }),
  );
  assert.isTrue(
    decodes(SaveExpense, {
      envelopeId: "019845e1-682f-4b02-a706-3b2422d13aec",
      amountMinor: 100,
      spentAt: "2026-11-05T10:00:00Z",
      title: null,
      forWhom: null,
      forWhomUserId: null,
      decision: null,
    }),
  );
});
