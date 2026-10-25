import { InvalidImport, type LegacyBackup } from "@bida/api-contract";
import { assert, it } from "@effect/vitest";
import { DateTime, Effect } from "effect";
import { convertLegacy } from "./legacy.ts";

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
    const doc = yield* convertLegacy({ backup: backup() }, now);

    const [category] = doc.categories;
    const [period] = doc.periods;
    const [envelope] = doc.envelopes;
    const [rule] = doc.recurringRules;
    const [expense] = doc.expenses;

    assert.strictEqual(category?.name, "Food");
    assert.strictEqual(period?.startDate, "2026-07-01");
    assert.strictEqual(period?.endDate, "2026-07-31");
    assert.strictEqual(period?.incomeMinor, 500050);
    assert.strictEqual(envelope?.plannedMinor, 120025);
    assert.strictEqual(envelope?.periodId, period?.id);
    assert.strictEqual(envelope?.categoryId, category?.id);
    assert.strictEqual(rule?.amountMinor, 9999);
    assert.isTrue(rule?.active);
    assert.strictEqual(expense?.amountMinor, 4599);
    assert.strictEqual(expense?.envelopeId, envelope?.id);
    assert.strictEqual(expense?.periodId, period?.id);
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
      now,
    ).pipe(Effect.flip);
    assert.instanceOf(frequency, InvalidImport);

    const zone = yield* convertLegacy(
      { backup: backup(), timeZone: "Mars/Phobos" },
      now,
    ).pipe(Effect.flip);
    assert.instanceOf(zone, InvalidImport);
  }).pipe(Effect.runPromise));
