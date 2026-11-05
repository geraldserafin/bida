import { assert, describe, it } from "@effect/vitest";
import { firstPeriod, nextPeriod, occurrences, reanchor } from "./cycle.ts";
import { localDay } from "./dates.ts";
import {
  balanceOf,
  fitOf,
  freeOf,
  type Ledger,
  type Move,
  remainingPlansOf,
  type SpentItem,
  settle,
  sharesOf,
  withdrawableOf,
} from "./money.ts";

describe("periods (F24)", () => {
  it("monthly from the 1st by default", () => {
    const cycle = { kind: "monthly", day: 1 } as const;
    const first = firstPeriod(cycle, "2026-11-05");
    assert.deepStrictEqual(first, {
      startsOn: "2026-11-01",
      endsOn: "2026-11-30",
    });
    assert.deepStrictEqual(nextPeriod(cycle, first), {
      startsOn: "2026-12-01",
      endsOn: "2026-12-31",
    });
  });

  it("monthly from a later day crosses the month", () => {
    const cycle = { kind: "monthly", day: 10 } as const;
    assert.deepStrictEqual(firstPeriod(cycle, "2026-11-05"), {
      startsOn: "2026-10-10",
      endsOn: "2026-11-09",
    });
    assert.deepStrictEqual(firstPeriod(cycle, "2026-11-10"), {
      startsOn: "2026-11-10",
      endsOn: "2026-12-09",
    });
  });

  it("a day past the end of a short month falls on its last day", () => {
    const cycle = { kind: "monthly", day: 31 } as const;
    const jan = firstPeriod(cycle, "2027-01-31");
    assert.deepStrictEqual(jan, {
      startsOn: "2027-01-31",
      endsOn: "2027-02-27",
    });
    const feb = nextPeriod(cycle, jan);
    assert.deepStrictEqual(feb, {
      startsOn: "2027-02-28",
      endsOn: "2027-03-30",
    });
    assert.deepStrictEqual(nextPeriod(cycle, feb).startsOn, "2027-03-31");
  });

  it("every N weeks from an anchor, before and after it", () => {
    const cycle = { kind: "weeks", weeks: 2, anchor: "2026-11-02" } as const;
    assert.deepStrictEqual(firstPeriod(cycle, "2026-11-05"), {
      startsOn: "2026-11-02",
      endsOn: "2026-11-15",
    });
    assert.deepStrictEqual(firstPeriod(cycle, "2026-10-30"), {
      startsOn: "2026-10-19",
      endsOn: "2026-11-01",
    });
  });

  it("periods follow each other without gaps or overlap", () => {
    for (const cycle of [
      { kind: "monthly", day: 1 },
      { kind: "monthly", day: 30 },
      { kind: "weeks", weeks: 1, anchor: "2026-01-05" },
      { kind: "manual" },
    ] as const) {
      let span = firstPeriod(cycle, "2026-01-20", "2026-02-03");
      for (let i = 0; i < 30; i++) {
        const next = nextPeriod(cycle, span);
        const dayAfter = new Date(`${span.endsOn}T00:00:00Z`);
        dayAfter.setUTCDate(dayAfter.getUTCDate() + 1);
        assert.strictEqual(next.startsOn, dayAfter.toISOString().slice(0, 10));
        assert.isTrue(next.endsOn >= next.startsOn);
        span = next;
      }
    }
  });

  it("a manual period is as long as the one before", () => {
    const cycle = { kind: "manual" } as const;
    const first = firstPeriod(cycle, "2026-11-05", "2026-11-14");
    assert.deepStrictEqual(nextPeriod(cycle, first), {
      startsOn: "2026-11-15",
      endsOn: "2026-11-24",
    });
  });

  it("after the end moves, the next periods count from the new end", () => {
    const moved = reanchor({ kind: "monthly", day: 1 }, "2026-12-06");
    assert.deepStrictEqual(
      nextPeriod(moved, { startsOn: "2026-11-01", endsOn: "2026-12-05" }),
      { startsOn: "2026-12-06", endsOn: "2027-01-05" },
    );
  });

  it("the day is the day in the time zone of the household", () => {
    // 23:30 UTC on 30 November is already 1 December in Warsaw
    const instant = new Date("2026-11-30T23:30:00Z");
    assert.strictEqual(localDay(instant, "Europe/Warsaw"), "2026-12-01");
    assert.strictEqual(localDay(instant, "UTC"), "2026-11-30");
    // summer time: +2
    const summer = new Date("2026-06-30T22:30:00Z");
    assert.strictEqual(localDay(summer, "Europe/Warsaw"), "2026-07-01");
  });
});

describe("occurrences of a rule", () => {
  it("monthly: Spotify on the 5th three times in a long period", () => {
    const days = occurrences(
      { frequency: "monthly", dayOfMonth: 5 },
      "2026-01-01",
      "2026-03-31",
    );
    assert.deepStrictEqual(days, ["2026-01-05", "2026-02-05", "2026-03-05"]);
    assert.strictEqual(days.length * 2000, 6000);
    assert.strictEqual(
      occurrences(
        { frequency: "monthly", dayOfMonth: 5 },
        "2026-04-01",
        "2026-04-30",
      ).length,
      1,
    );
  });

  it("monthly on the 31st falls on the last day of February", () => {
    assert.deepStrictEqual(
      occurrences(
        { frequency: "monthly", dayOfMonth: 31 },
        "2027-02-01",
        "2027-03-31",
      ),
      ["2027-02-28", "2027-03-31"],
    );
  });

  it("weekly: every week from the anchor, never before it", () => {
    assert.deepStrictEqual(
      occurrences(
        { frequency: "weeks", everyWeeks: 1, anchorOn: "2026-11-04" },
        "2026-11-01",
        "2026-11-30",
      ),
      ["2026-11-04", "2026-11-11", "2026-11-18", "2026-11-25"],
    );
    assert.deepStrictEqual(
      occurrences(
        { frequency: "weeks", everyWeeks: 2, anchorOn: "2026-10-01" },
        "2026-11-01",
        "2026-11-30",
      ),
      ["2026-11-12", "2026-11-26"],
    );
  });
});

const move = (
  kind: Move["kind"],
  amountMinor: number,
  userId: string | null = "ann",
): Move => ({ kind, amountMinor, userId });

let seq = 0;
const spent = (
  envelopeId: string,
  amountMinor: number,
  userId = "ann",
  at = seq,
): SpentItem => {
  seq++;
  return {
    id: `x${seq}`,
    envelopeId,
    amountMinor,
    userId,
    spentAtMs: at,
    createdAtMs: seq,
  };
};

const plan = (envelopeId: string, manualMinor: number, recurringMinor = 0) => ({
  envelopeId,
  manualMinor,
  recurringMinor,
});

describe("the piggy bank (WO08, F16)", () => {
  it("the November example: what is left goes on as nobody's money", () => {
    const november: Ledger = {
      moves: [move("transfer", 100_000)],
      plans: [plan("food", 80_000)],
      expenses: [spent("food", 70_000)],
    };
    const carry = balanceOf(november);
    assert.strictEqual(carry, 30_000);

    const december: Ledger = {
      moves: [move("transfer", 70_000), move("carry", carry, null)],
      plans: [plan("food", 70_000)],
      expenses: [],
    };
    assert.strictEqual(balanceOf(december), 100_000);
    assert.strictEqual(sharesOf(december).nobodyMinor, 30_000);
    // 300 zł more to plan
    assert.strictEqual(freeOf(december), 30_000);
  });

  it("the plans may exceed the balance; free money is then negative", () => {
    const ledger: Ledger = {
      moves: [move("transfer", 1_000)],
      plans: [plan("a", 800), plan("b", 500)],
      expenses: [spent("a", 900)],
    };
    // a: overspent counts 0 remaining; b: 500
    assert.strictEqual(remainingPlansOf(ledger), 500);
    assert.strictEqual(balanceOf(ledger), 100);
    assert.strictEqual(freeOf(ledger), -400);
  });
});

describe("shares (F33)", () => {
  it("an expense uses nobody's money first, then the share of its author", () => {
    const ledger: Ledger = {
      moves: [
        move("carry", 300, null),
        move("transfer", 1_000, "ann"),
        move("transfer", 1_000, "bob"),
      ],
      plans: [],
      expenses: [spent("a", 500, "bob", 1), spent("a", 200, "ann", 2)],
    };
    const shares = sharesOf(ledger);
    const of = (id: string) =>
      shares.people.find((p) => p.userId === id)?.shareMinor;
    // bob's 500: 300 of nobody's, 200 of his; ann's 200: all hers
    assert.strictEqual(of("bob"), 800);
    assert.strictEqual(of("ann"), 800);
    assert.strictEqual(shares.nobodyLeftMinor, 0);
    assert.strictEqual(
      balanceOf(ledger),
      (of("ann") ?? 0) + (of("bob") ?? 0) + shares.nobodyLeftMinor,
    );
  });

  it("the order is the order of spending, not of writing down", () => {
    const ledger: Ledger = {
      moves: [move("carry", 100, null), move("transfer", 1_000, "ann")],
      plans: [],
      expenses: [spent("a", 100, "ann", 50), spent("a", 100, "bob", 10)],
    };
    const bob = sharesOf(ledger).people.find((p) => p.userId === "bob");
    assert.strictEqual(bob?.fromNobodyMinor, 100);
    assert.strictEqual(bob?.shareMinor, 0);
  });

  it("a share goes negative when somebody spends more than they put in", () => {
    const ledger: Ledger = {
      moves: [move("transfer", 1_000, "ann")],
      plans: [],
      expenses: [spent("a", 300, "bob")],
    };
    const bob = sharesOf(ledger).people.find((p) => p.userId === "bob");
    assert.strictEqual(bob?.shareMinor, -300);
  });

  it("one withdraws at most their share and what is in the piggy bank", () => {
    const ledger: Ledger = {
      moves: [move("transfer", 1_000, "ann"), move("transfer", 500, "bob")],
      plans: [],
      expenses: [spent("a", 1_200, "bob")],
    };
    // ann's share is 1000, but only 300 is left
    assert.strictEqual(withdrawableOf(ledger, "ann"), 300);
    assert.strictEqual(withdrawableOf(ledger, "bob"), 0);
  });

  it("a forfeit turns a share into nobody's money", () => {
    const ledger: Ledger = {
      moves: [move("transfer", 1_000, "bob"), move("forfeit", 1_000, "bob")],
      plans: [],
      expenses: [spent("a", 400, "ann")],
    };
    const shares = sharesOf(ledger);
    assert.strictEqual(balanceOf(ledger), 600);
    assert.strictEqual(
      shares.people.find((p) => p.userId === "bob")?.shareMinor,
      0,
    );
    assert.strictEqual(
      shares.people.find((p) => p.userId === "ann")?.shareMinor,
      0,
    );
    assert.strictEqual(shares.nobodyLeftMinor, 600);
  });
});

describe("an expense has to fit (F08)", () => {
  const base: Ledger = {
    moves: [move("transfer", 1_000)],
    plans: [plan("food", 300), plan("fun", 200)],
    expenses: [spent("food", 100)],
  };

  it("within the plan it fits", () => {
    assert.deepStrictEqual(
      fitOf(base, { envelopeId: "food", amountMinor: 200 }),
      { kind: "fits" },
    );
  });

  it("step 1: a too small plan grows by itself out of free money", () => {
    // free: 900 − (200 + 200) = 500
    assert.deepStrictEqual(
      fitOf(base, { envelopeId: "food", amountMinor: 450 }),
      { kind: "raise", raiseMinor: 250 },
    );
  });

  it("step 2: no free money, so bring money from the wallet", () => {
    const fit = fitOf(base, { envelopeId: "food", amountMinor: 900 });
    assert.strictEqual(fit.kind, "needs");
    if (fit.kind !== "needs") return;
    assert.strictEqual(fit.planShortMinor, 700);
    assert.strictEqual(fit.freeMinor, 500);
    assert.strictEqual(fit.transferMinor, 200);
    // with the transfer the plan grows out of free money on its own
    assert.deepStrictEqual(
      settle(
        base,
        { envelopeId: "food", amountMinor: 900 },
        { raisePlan: false, transferMinor: 200 },
      ),
      { ok: true, raiseMinor: 700 },
    );
  });

  it("the plan can be raised past the balance only with the user's consent", () => {
    // short by 600, only 500 free
    const request = { envelopeId: "food", amountMinor: 800 };
    const fit = fitOf(base, request);
    assert.strictEqual(fit.kind, "needs");
    assert.deepStrictEqual(
      settle(base, request, { raisePlan: false, transferMinor: 0 }),
      { ok: false },
    );
    // 800 still fits in the balance of 900
    assert.deepStrictEqual(
      settle(base, request, { raisePlan: true, transferMinor: 0 }),
      { ok: true, raiseMinor: 600 },
    );
  });

  it("the balance must hold the expense, whatever the plan says", () => {
    const tight: Ledger = {
      moves: [move("transfer", 100)],
      plans: [plan("food", 500)],
      expenses: [],
    };
    const fit = fitOf(tight, { envelopeId: "food", amountMinor: 300 });
    assert.deepStrictEqual(fit, {
      kind: "needs",
      planShortMinor: 0,
      freeMinor: -400,
      balanceMinor: 100,
      transferMinor: 200,
    });
    assert.deepStrictEqual(
      settle(
        tight,
        { envelopeId: "food", amountMinor: 300 },
        { raisePlan: true, transferMinor: 100 },
      ),
      { ok: false },
    );
  });

  it("an edit is checked without the expense it replaces", () => {
    const edited = base.expenses[0];
    assert.deepStrictEqual(
      fitOf(base, {
        envelopeId: "food",
        amountMinor: 300,
        replacingId: edited?.id,
      }),
      { kind: "fits" },
    );
  });
});
