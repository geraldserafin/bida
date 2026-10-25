import { InvalidCsv } from "@bida/api-contract";
import { assert, it } from "@effect/vitest";
import { Effect } from "effect";
import {
  formatAmount,
  formatCsv,
  parseAmount,
  parseCsv,
  parseLine,
} from "./csv.ts";

it("formats and parses amounts", () => {
  assert.strictEqual(formatAmount(123456), "1234.56");
  assert.strictEqual(formatAmount(5), "0.05");
  assert.strictEqual(parseAmount("12.34"), 1234);
  assert.strictEqual(parseAmount("12,34"), 1234);
  assert.strictEqual(parseAmount("0.1"), 10);
  assert.strictEqual(parseAmount("0"), undefined);
  assert.strictEqual(parseAmount("-5"), undefined);
  assert.strictEqual(parseAmount("abc"), undefined);
});

it("splits lines with quotes and escaped quotes", () => {
  assert.deepStrictEqual(parseLine('a,"b,c","say ""hi""",d'), [
    "a",
    "b,c",
    'say "hi"',
    "d",
  ]);
});

it("round-trips through formatCsv and parseCsv", () =>
  Effect.gen(function* () {
    const text = formatCsv([
      {
        period: "July, 2026",
        category: "Food",
        amountMinor: 4599,
        currency: "PLN" as const,
        date: "2026-07-03",
        note: 'a "b"',
      },
      {
        period: "July, 2026",
        category: "Rent",
        amountMinor: 200000,
        currency: "PLN" as const,
        date: "2026-07-01",
        note: null,
      },
    ]);
    const rows = yield* parseCsv(text);
    assert.strictEqual(rows.length, 2);
    assert.deepStrictEqual(
      rows.map((r) => [r.period, r.category, r.amount, r.date, r.note]),
      [
        ["July, 2026", "Food", "45.99", "2026-07-03", 'a "b"'],
        ["July, 2026", "Rent", "2000.00", "2026-07-01", ""],
      ],
    );
  }).pipe(Effect.runPromise));

it("reports the line of an invalid row", () =>
  Effect.gen(function* () {
    const header = "Period,Category,Amount,Date,Note,Currency";
    const badAmount = yield* parseCsv(
      `${header}\nJuly,Food,x,2026-07-03,\n`,
    ).pipe(Effect.flip);
    assert.instanceOf(badAmount, InvalidCsv);
    assert.strictEqual(badAmount.line, 2);

    const badDate = yield* parseCsv(
      `${header}\n\nJuly,Food,1,2026-02-31,\n`,
    ).pipe(Effect.flip);
    assert.strictEqual(badDate.line, 3);

    const short = yield* parseCsv(`${header}\nJuly,Food\n`).pipe(Effect.flip);
    assert.strictEqual(short.line, 2);
  }).pipe(Effect.runPromise));

it("an empty or header-only file has no rows", () =>
  Effect.gen(function* () {
    assert.deepStrictEqual(yield* parseCsv(""), []);
    assert.deepStrictEqual(
      yield* parseCsv("Period,Category,Amount,Date,Note,Currency\n"),
      [],
    );
  }).pipe(Effect.runPromise));
