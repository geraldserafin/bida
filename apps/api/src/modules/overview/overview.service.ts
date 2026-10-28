import {
  type EnvelopeFigures,
  type EnvelopeId,
  InvalidRange,
  InvalidTimeZone,
  type MonthSummary,
  type Overview,
  type UserId,
} from "@bida/api-contract";
import { Context, DateTime, Effect, Layer } from "effect";
import {
  type EnvelopeSums,
  OverviewRepository,
} from "./overview.repository.ts";

const DEFAULT_TIME_ZONE = "Europe/Warsaw";

const isTimeZone = (timeZone: string): boolean => {
  try {
    new Intl.DateTimeFormat("en", { timeZone });
    return true;
  } catch {
    return false;
  }
};

/** `YYYY-MM-DD` of the instant in the time zone. */
const dayIn = (instant: DateTime.Utc, timeZone: string): string =>
  new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(instant.epochMilliseconds);

const pad = (n: number) => String(n).padStart(2, "0");

const isoOf = (y: number, m: number, d: number) => `${y}-${pad(m)}-${pad(d)}`;

/**
 * Adds up the rows of a top-level envelope with those of its sub-envelopes.
 * The money assigned to a sub-envelope is part of the parent's balance, so
 * only the parent's own allocations count towards it.
 */
const figuresOf = (
  rows: ReadonlyArray<EnvelopeSums>,
): Array<EnvelopeFigures> => {
  const children = new Map<string, Array<EnvelopeSums>>();
  for (const row of rows) {
    if (row.parentId === null) continue;
    children.set(row.parentId, [...(children.get(row.parentId) ?? []), row]);
  }
  const subFigures = (row: EnvelopeSums): EnvelopeFigures => {
    const opening = row.allocatedBefore - row.spentBefore;
    const balance = opening + row.allocatedInside - row.spentInside;
    return {
      envelopeId: row.id as EnvelopeId,
      parentId: row.parentId as EnvelopeId,
      role: row.role,
      memberCount: row.memberCount,
      openingMinor: opening,
      allocatedMinor: row.allocatedInside,
      spentMinor: row.spentInside,
      balanceMinor: balance,
      freeMinor: balance,
    };
  };

  const out: Array<EnvelopeFigures> = [];
  for (const row of rows) {
    if (row.parentId !== null) continue;
    const kids = children.get(row.id) ?? [];
    const kidFigures = kids.map(subFigures);
    const spentBefore =
      row.spentBefore + kids.reduce((sum, k) => sum + k.spentBefore, 0);
    const spentInside =
      row.spentInside + kids.reduce((sum, k) => sum + k.spentInside, 0);
    const opening = row.allocatedBefore - spentBefore;
    const balance = opening + row.allocatedInside - spentInside;
    out.push({
      envelopeId: row.id as EnvelopeId,
      parentId: null,
      role: row.role,
      memberCount: row.memberCount,
      openingMinor: opening,
      allocatedMinor: row.allocatedInside,
      spentMinor: spentInside,
      balanceMinor: balance,
      freeMinor:
        balance - kidFigures.reduce((sum, k) => sum + k.balanceMinor, 0),
    });
    out.push(...kidFigures);
  }
  return out;
};

/** Totals over a stretch of time and the history by month. */
export class OverviewService extends Context.Service<
  OverviewService,
  {
    get(
      userId: UserId,
      input: {
        readonly from: string;
        readonly to: string;
        readonly timeZone?: string | undefined;
      },
    ): Effect.Effect<Overview, InvalidTimeZone | InvalidRange>;
    months(
      userId: UserId,
      input: {
        readonly startDay?: number | undefined;
        readonly timeZone?: string | undefined;
        /** The day the history reaches (`YYYY-MM-DD`); today when omitted. */
        readonly today?: string | undefined;
      },
    ): Effect.Effect<ReadonlyArray<MonthSummary>, InvalidTimeZone>;
  }
>()("bida/overview/OverviewService") {
  static readonly layer = Layer.effect(
    OverviewService,
    Effect.gen(function* () {
      const repo = yield* OverviewRepository;

      const get = Effect.fn("OverviewService.get")(function* (
        userId: UserId,
        input: {
          readonly from: string;
          readonly to: string;
          readonly timeZone?: string | undefined;
        },
      ) {
        const timeZone = input.timeZone ?? DEFAULT_TIME_ZONE;
        if (!isTimeZone(timeZone))
          return yield* new InvalidTimeZone({ timeZone });
        if (input.to < input.from) {
          return yield* new InvalidRange({ from: input.from, to: input.to });
        }
        const range = { from: input.from, to: input.to };
        const [rows, user] = yield* Effect.all([
          repo.envelopeSums(userId, range, timeZone),
          repo.userSums(userId, range, timeZone),
        ]);
        return {
          ...range,
          incomeMinor: user.incomeInside,
          allocatedMinor: user.allocatedInside,
          spentMinor: user.spentInside,
          poolMinor: user.pool,
          envelopes: figuresOf(rows),
        };
      });

      const months = Effect.fn("OverviewService.months")(function* (
        userId: UserId,
        input: {
          readonly startDay?: number | undefined;
          readonly timeZone?: string | undefined;
          readonly today?: string | undefined;
        },
      ) {
        const timeZone = input.timeZone ?? DEFAULT_TIME_ZONE;
        if (!isTimeZone(timeZone))
          return yield* new InvalidTimeZone({ timeZone });
        const startDay = input.startDay ?? 1;
        const found = yield* repo.months(userId, startDay, timeZone);
        const byStart = new Map(
          found.map((month) => [month.monthStart, month]),
        );

        // the month today is in, so the list always reaches the present
        const today = input.today ?? dayIn(yield* DateTime.now, timeZone);
        const [y, m, d] = today.split("-").map(Number) as [
          number,
          number,
          number,
        ];
        let [cy, cm] =
          d >= startDay ? [y, m] : m === 1 ? [y - 1, 12] : [y, m - 1];
        const current = isoOf(cy, cm, startDay);

        const first = found.at(-1)?.monthStart ?? current;
        const starts: Array<string> = [];
        [cy, cm] = first.split("-").slice(0, 2).map(Number) as [number, number];
        for (let start = isoOf(cy, cm, startDay); start <= current; ) {
          starts.push(start);
          [cy, cm] = cm === 12 ? [cy + 1, 1] : [cy, cm + 1];
          start = isoOf(cy, cm, startDay);
        }

        return starts.reverse().map((start): MonthSummary => {
          const month = byStart.get(start);
          const [sy, sm] = start.split("-").map(Number) as [number, number];
          const [ey, em] = sm === 12 ? [sy + 1, 1] : [sy, sm + 1];
          const end = new Date(Date.UTC(ey, em - 1, startDay - 1));
          return {
            from: start,
            to:
              month?.monthEnd ??
              isoOf(
                end.getUTCFullYear(),
                end.getUTCMonth() + 1,
                end.getUTCDate(),
              ),
            incomeMinor: month?.income ?? 0,
            allocatedMinor: month?.allocated ?? 0,
            spentMinor: month?.spent ?? 0,
          };
        });
      });

      return OverviewService.of({ get, months });
    }),
  );
}
