import { InvalidImport, type LegacyBackup } from "@bida/api-contract";
import { assert, it } from "@effect/vitest";
import { DateTime, Effect } from "effect";
import { convertLegacy } from "./legacy.ts";

const userId = "00000000-0000-4000-8000-0000000000aa";
const now = DateTime.makeUnsafe("2026-10-25T12:00:00Z");

const backup = (patch: Partial<LegacyBackup["data"]> = {}): LegacyBackup => ({
  version: 1,
  data: {
    categories: [{ id: 1, name: "Food", color: "#22C55E", icon: "restaurant" }],
    periods: [
      {
        id: 7,
        name: "July",
        start_date: "2026-07-01T00:00:00.000",
        end_date: "2026-07-31T00:00:00.000",
        income: 5000.5,
      },
    ],
    splits: [{ id: 3, period_id: 7, category_id: 1, planned_amount: 1200.25 }],
    recurring_rules: [
      {
        id: 9,
        category_id: 1,
        amount: 99.99,
        frequency: "monthly",
        note: "Gym",
        active: 1,
      },
    ],
    expenses: [
      {
        id: 5,
        split_id: 3,
        amount: 45.99,
        date: "2026-07-03T10:30:00.000",
        note: "Biedronka",
        recurring_id: 9,
      },
    ],
    ...patch,
  },
});

it("converts ids, amounts and dates", () =>
  Effect.gen(function* () {
    const doc = yield* convertLegacy({ backup: backup() }, userId, now);

    const [envelope] = doc.envelopes;
    const [income] = doc.incomes;
    const [allocation] = doc.allocations;
    const [rule] = doc.recurringRules;
    const [expense] = doc.expenses;

    assert.strictEqual(envelope?.name, "Food");
    assert.strictEqual(envelope?.parentId, null);
    assert.strictEqual(envelope?.ownerId, userId);
    // a period gives an income and what it planned for the category
    assert.strictEqual(income?.amountMinor, 500050);
    assert.strictEqual(income?.receivedOn, "2026-07-01");
    assert.strictEqual(allocation?.amountMinor, 120025);
    assert.strictEqual(allocation?.madeOn, "2026-07-01");
    assert.strictEqual(allocation?.envelopeId, envelope?.id);
    assert.strictEqual(rule?.amountMinor, 9999);
    assert.isTrue(rule?.active);
    assert.strictEqual(expense?.amountMinor, 4599);
    assert.strictEqual(expense?.envelopeId, envelope?.id);
    assert.strictEqual(expense?.recurringId, rule?.id);
    // 10:30 in Warsaw (UTC+2 in July) is 08:30 UTC
    assert.strictEqual(
      DateTime.formatIso(expense!.spentAt),
      "2026-07-03T08:30:00.000Z",
    );
  }).pipe(Effect.runPromise));

it("honours the time zone", () =>
  Effect.gen(function* () {
    const doc = yield* convertLegacy(
      { backup: backup(), timeZone: "UTC" },
      userId,
      now,
    );
    assert.strictEqual(
      DateTime.formatIso(doc.expenses[0]!.spentAt),
      "2026-07-03T10:30:00.000Z",
    );
  }).pipe(Effect.runPromise));

it("fails on dangling references and bad values", () =>
  Effect.gen(function* () {
    const dangling = yield* convertLegacy(
      {
        backup: backup({
          splits: [{ id: 3, period_id: 99, category_id: 1, planned_amount: 1 }],
        }),
      },
      userId,
      now,
    ).pipe(Effect.flip);
    assert.instanceOf(dangling, InvalidImport);

    const zero = yield* convertLegacy(
      {
        backup: backup({
          expenses: [
            {
              id: 5,
              split_id: 3,
              amount: 0,
              date: "2026-07-03T10:30:00.000",
              note: null,
              recurring_id: null,
            },
          ],
        }),
      },
      userId,
      now,
    ).pipe(Effect.flip);
    assert.instanceOf(zero, InvalidImport);

    const frequency = yield* convertLegacy(
      {
        backup: backup({
          recurring_rules: [
            {
              id: 9,
              category_id: 1,
              amount: 1,
              frequency: "daily",
              note: null,
              active: 1,
            },
          ],
        }),
      },
      userId,
      now,
    ).pipe(Effect.flip);
    assert.instanceOf(frequency, InvalidImport);

    const zone = yield* convertLegacy(
      { backup: backup(), timeZone: "Mars/Phobos" },
      userId,
      now,
    ).pipe(Effect.flip);
    assert.instanceOf(zone, InvalidImport);
  }).pipe(Effect.runPromise));
