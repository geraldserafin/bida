import { Currency, exponentOf, InvalidCsv } from "@bida/api-contract";
import { Effect, Schema } from "effect";

export interface CsvRow {
  /** 1-based line in the file, for error messages. */
  readonly line: number;
  readonly period: string;
  readonly category: string;
  /** The amount as written, e.g. `12.34`. Turn it into minor units with {@link parseAmount}. */
  readonly amount: string;
  /** `YYYY-MM-DD`. */
  readonly date: string;
  readonly note: string;
  /** From the optional sixth column. */
  readonly currency: Currency | undefined;
}

export interface CsvExportRow {
  readonly period: string;
  readonly category: string;
  readonly amountMinor: number;
  readonly currency: Currency;
  readonly date: string;
  readonly note: string | null;
}

export const HEADER = "Period,Category,Amount,Date,Note,Currency";

const field = (value: string): string =>
  /[",\n\r]/.test(value) ? `"${value.replaceAll('"', '""')}"` : value;

/** 123456 with 2 decimals -> "1234.56" */
export const formatAmount = (minor: number, exponent = 2): string =>
  (minor / 10 ** exponent).toFixed(exponent);

const AMOUNT = /^\d+([.,]\d+)?$/;

/** "12.34" or "12,34" -> 1234 (with 2 decimals). `undefined` unless positive. */
export const parseAmount = (text: string, exponent = 2): number | undefined => {
  const normalized = text.trim().replace(",", ".");
  if (!AMOUNT.test(text.trim())) return undefined;
  const minor = Math.round(Number(normalized) * 10 ** exponent);
  return minor > 0 ? minor : undefined;
};

export const formatCsv = (rows: ReadonlyArray<CsvExportRow>): string =>
  `${[
    HEADER,
    ...rows.map((row) =>
      [
        field(row.period),
        field(row.category),
        formatAmount(row.amountMinor, exponentOf(row.currency)),
        row.date,
        field(row.note ?? ""),
        row.currency,
      ].join(","),
    ),
  ].join("\n")}\n`;

/** Splits one CSV line, honouring quoted fields and escaped quotes. */
export const parseLine = (line: string): ReadonlyArray<string> => {
  const columns: Array<string> = [];
  let current = "";
  let quoted = false;
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (quoted) {
      if (char === '"') {
        if (line[i + 1] === '"') {
          current += '"';
          i++;
        } else {
          quoted = false;
        }
      } else {
        current += char;
      }
    } else if (char === '"') {
      quoted = true;
    } else if (char === ",") {
      columns.push(current);
      current = "";
    } else {
      current += char;
    }
  }
  columns.push(current);
  return columns;
};

const validDate = (text: string): string | undefined => {
  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(text.trim());
  if (match === null) return undefined;
  const [, y, m, d] = match;
  const date = new Date(Date.UTC(Number(y), Number(m) - 1, Number(d)));
  return date.getUTCFullYear() === Number(y) &&
    date.getUTCMonth() === Number(m) - 1 &&
    date.getUTCDate() === Number(d)
    ? `${y}-${m}-${d}`
    : undefined;
};

const isCurrency = Schema.is(Currency);

/** Parses the whole file before anything is written, so errors are atomic. */
export const parseCsv = (
  text: string,
): Effect.Effect<ReadonlyArray<CsvRow>, InvalidCsv> =>
  Effect.gen(function* () {
    const lines = text
      .split(/\r\n|\r|\n/)
      .map((content, index) => ({ content, line: index + 1 }))
      .filter(({ content }) => content.trim() !== "");
    const rows: Array<CsvRow> = [];
    for (const { content, line } of lines.slice(1)) {
      // the first non-empty line is the header
      const columns = parseLine(content);
      if (columns.length < 4) {
        return yield* new InvalidCsv({
          line,
          reason: "expected at least 4 columns",
        });
      }
      const [
        period = "",
        category = "",
        amount = "",
        date = "",
        note = "",
        currency = "",
      ] = columns;
      if (period.trim() === "" || category.trim() === "") {
        return yield* new InvalidCsv({
          line,
          reason: "period and category are required",
        });
      }
      if (parseAmount(amount, 6) === undefined) {
        return yield* new InvalidCsv({
          line,
          reason: `invalid amount "${amount}"`,
        });
      }
      const day = validDate(date);
      if (day === undefined) {
        return yield* new InvalidCsv({
          line,
          reason: `invalid date "${date}"`,
        });
      }
      const code = currency.trim().toUpperCase();
      if (code !== "" && !isCurrency(code)) {
        return yield* new InvalidCsv({
          line,
          reason: `unsupported currency "${currency}"`,
        });
      }
      rows.push({
        line,
        period: period.trim(),
        category: category.trim(),
        amount: amount.trim(),
        date: day,
        note: note.trim(),
        currency: code === "" ? undefined : (code as Currency),
      });
    }
    return rows;
  });
