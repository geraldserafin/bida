import {
  addDays,
  type Day,
  daysBetween,
  daysInMonth,
  makeDay,
  maxDay,
  parts,
  shiftMonth,
} from "./dates.ts";

/**
 * How a household cuts time into periods. `monthly`: a period starts on
 * `day` of every month (29-31 fall on the last day of a shorter month).
 * `weeks`: every `weeks` weeks from `anchor`. `manual`: a new period is as long
 * as the one before it, and the owner moves its end.
 */
export type Cycle =
  | { readonly kind: "monthly"; readonly day: number }
  | { readonly kind: "weeks"; readonly weeks: number; readonly anchor: Day }
  | { readonly kind: "manual" };

export interface Span {
  readonly startsOn: Day;
  /** Included. */
  readonly endsOn: Day;
}

/** When a monthly rule or cycle falls in a month: its day, or the last one. */
export const dayInMonth = (year: number, month: number, day: number): Day =>
  makeDay(year, month, Math.min(day, daysInMonth(year, month)));

/** The latest start of a period on or before `day`. */
const startOnOrBefore = (
  cycle: Exclude<Cycle, { kind: "manual" }>,
  day: Day,
): Day => {
  if (cycle.kind === "weeks") {
    const step = cycle.weeks * 7;
    const steps = Math.floor(daysBetween(cycle.anchor, day) / step);
    return addDays(cycle.anchor, steps * step);
  }
  const { year, month } = parts(day);
  const here = dayInMonth(year, month, cycle.day);
  if (here <= day) return here;
  const before = shiftMonth(year, month, -1);
  return dayInMonth(before.year, before.month, cycle.day);
};

/** The first start of a period after `day`. */
const startAfter = (
  cycle: Exclude<Cycle, { kind: "manual" }>,
  day: Day,
): Day => {
  if (cycle.kind === "weeks")
    return addDays(startOnOrBefore(cycle, day), cycle.weeks * 7);
  const { year, month } = parts(day);
  const here = dayInMonth(year, month, cycle.day);
  if (here > day) return here;
  const after = shiftMonth(year, month, 1);
  return dayInMonth(after.year, after.month, cycle.day);
};

/**
 * The period a new household starts with: the one that holds `today`. A
 * manual cycle needs its first end; it starts today.
 */
export const firstPeriod = (
  cycle: Cycle,
  today: Day,
  manualEnd?: Day,
): Span => {
  if (cycle.kind === "manual")
    return { startsOn: today, endsOn: maxDay(manualEnd ?? today, today) };
  const startsOn = startOnOrBefore(cycle, today);
  return { startsOn, endsOn: addDays(startAfter(cycle, startsOn), -1) };
};

/** The period right after `previous`: no gap, no overlap. */
export const nextPeriod = (cycle: Cycle, previous: Span): Span => {
  const startsOn = addDays(previous.endsOn, 1);
  if (cycle.kind === "manual") {
    const length = daysBetween(previous.startsOn, previous.endsOn);
    return { startsOn, endsOn: addDays(startsOn, length) };
  }
  return { startsOn, endsOn: addDays(startAfter(cycle, startsOn), -1) };
};

/**
 * The cycle once the current period has been made to end the day before
 * `nextStart`: the following periods count from the new end.
 */
export const reanchor = (cycle: Cycle, nextStart: Day): Cycle => {
  switch (cycle.kind) {
    case "monthly":
      return { kind: "monthly", day: parts(nextStart).date };
    case "weeks":
      return { kind: "weeks", weeks: cycle.weeks, anchor: nextStart };
    case "manual":
      return cycle;
  }
};

/** When a recurring rule falls due. Same shapes as a cycle, without manual. */
export type Schedule =
  | { readonly frequency: "monthly"; readonly dayOfMonth: number }
  | {
      readonly frequency: "weeks";
      readonly everyWeeks: number;
      readonly anchorOn: Day;
    };

/** The days a rule falls on from `from` to `to`, both included, in order. */
export const occurrences = (
  schedule: Schedule,
  from: Day,
  to: Day,
): ReadonlyArray<Day> => {
  if (from > to) return [];
  const days: Array<Day> = [];
  if (schedule.frequency === "weeks") {
    const step = schedule.everyWeeks * 7;
    const offset = daysBetween(schedule.anchorOn, from);
    const first = Math.max(0, Math.ceil(offset / step));
    for (let k = first; ; k++) {
      const day = addDays(schedule.anchorOn, k * step);
      if (day > to) break;
      if (day >= from) days.push(day);
    }
    return days;
  }
  let { year, month } = parts(from);
  for (;;) {
    const day = dayInMonth(year, month, schedule.dayOfMonth);
    if (day > to) break;
    if (day >= from) days.push(day);
    ({ year, month } = shiftMonth(year, month, 1));
  }
  return days;
};
