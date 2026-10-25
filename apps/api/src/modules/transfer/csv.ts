import { InvalidCsv } from "@bida/api-contract";
import { Effect } from "effect";

export interface CsvRow {
  /** 1-based line in the file, for error messages. */
  readonly line: number;
  readonly envelope: string;
  /** Empty when the expense is on the top-level envelope itself. */
  readonly subenvelope: string;
  /** The amount as written, e.g. `12.34`. Turn it into minor units with {@link parseAmount}. */
  readonly amount: string;
  /** `YYYY-MM-DD`. */
  readonly date: string;
  readonly note: string;
}

export interface CsvExportRow {
  readonly envelope: string;
  readonly subenvelope: string;
  readonly amountMinor: number;
  readonly date: string;
  readonly note: string | null;
}

export const HEADER = "Envelope,Subenvelope,Amount,Date,Note";

const field = (value: string): string =>
  /[",\n\r]/.test(value) ? `"${value.replaceAll('"', '""')}"` : value;

/** 123456 -> "1234.56" */
export const formatAmount = (minor: number): string => (minor / 100).toFixed(2);

const AMOUNT = /^\d+([.,]\d+)?$/;

/** "12.34" or "12,34" -> 1234. `undefined` unless positive. */
export const parseAmount = (text: string): number | undefined => {
  const normalized = text.trim().replace(",", ".");
  if (!AMOUNT.test(text.trim())) return undefined;
  const minor = Math.round(Number(normalized) * 100);
  return minor > 0 ? minor : undefined;
};

export const formatCsv = (rows: ReadonlyArray<CsvExportRow>): string =>
  `${[
    HEADER,
    ...rows.map((row) =>
      [
        field(row.envelope),
        field(row.subenvelope),
        formatAmount(row.amountMinor),
        row.date,
        field(row.note ?? ""),
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
        envelope = "",
        subenvelope = "",
        amount = "",
        date = "",
        note = "",
      ] = columns;
      if (envelope.trim() === "") {
        return yield* new InvalidCsv({
          line,
          reason: "the envelope is required",
        });
      }
      if (parseAmount(amount) === undefined) {
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
      rows.push({
        line,
        envelope: envelope.trim(),
        subenvelope: subenvelope.trim(),
        amount: amount.trim(),
        date: day,
        note: note.trim(),
      });
    }
    return rows;
  });
