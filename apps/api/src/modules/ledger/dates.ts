/** A calendar day, `YYYY-MM-DD`. Compared as text, which sorts like the days. */
export type Day = string;

/** The time zone of a household unless it says otherwise. */
export const DEFAULT_TIME_ZONE = "Europe/Warsaw";

const DAY_MS = 86_400_000;

const toUtcMs = (day: Day) => {
  const [y, m, d] = day.split("-").map(Number) as [number, number, number];
  return Date.UTC(y, m - 1, d);
};

const fromUtcMs = (ms: number): Day => new Date(ms).toISOString().slice(0, 10);

export const addDays = (day: Day, days: number): Day =>
  fromUtcMs(toUtcMs(day) + days * DAY_MS);

/** How many days from `from` to `to`; negative when `to` is earlier. */
export const daysBetween = (from: Day, to: Day) =>
  Math.round((toUtcMs(to) - toUtcMs(from)) / DAY_MS);

export const daysInMonth = (year: number, month: number) =>
  new Date(Date.UTC(year, month, 0)).getUTCDate();

export const parts = (day: Day) => {
  const [year, month, date] = day.split("-").map(Number) as [
    number,
    number,
    number,
  ];
  return { year, month, date };
};

export const makeDay = (year: number, month: number, date: number): Day =>
  `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}-${String(date).padStart(2, "0")}`;

/** The same month a number of months later (or earlier). */
export const shiftMonth = (year: number, month: number, by: number) => {
  const index = year * 12 + (month - 1) + by;
  return { year: Math.floor(index / 12), month: (index % 12) + 1 };
};

const formatters = new Map<string, Intl.DateTimeFormat>();

/** The day an instant falls on in a time zone. */
export const localDay = (instant: Date, timeZone: string): Day => {
  let format = formatters.get(timeZone);
  if (format === undefined) {
    // en-CA writes dates as YYYY-MM-DD
    format = new Intl.DateTimeFormat("en-CA", {
      timeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
    formatters.set(timeZone, format);
  }
  return format.format(instant);
};

export const isTimeZone = (timeZone: string) => {
  try {
    new Intl.DateTimeFormat("en-CA", { timeZone });
    return true;
  } catch {
    return false;
  }
};

export const minDay = (a: Day, b: Day) => (a < b ? a : b);
export const maxDay = (a: Day, b: Day) => (a > b ? a : b);
