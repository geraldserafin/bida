import { Schema } from "effect";

/**
 * Supported currencies (ISO 4217) with the number of decimal places of their
 * minor unit. Amounts are stored as integers in that minor unit, so 12.34 PLN
 * is 1234 and 500 JPY is 500. Add a code here to support a new currency.
 */
export const CURRENCY_EXPONENTS = {
  PLN: 2,
  EUR: 2,
  USD: 2,
  GBP: 2,
  CHF: 2,
  CZK: 2,
  SEK: 2,
  NOK: 2,
  DKK: 2,
  HUF: 2,
  JPY: 0,
} as const;

export const Currency = Schema.Literals(
  Object.keys(CURRENCY_EXPONENTS) as Array<keyof typeof CURRENCY_EXPONENTS>,
).annotate({ identifier: "Currency" });
export type Currency = typeof Currency.Type;

/** Used wherever no currency is chosen. */
export const DEFAULT_CURRENCY: Currency = "PLN";

/** Number of decimal places of the currency's minor unit. */
export const exponentOf = (currency: Currency): number =>
  CURRENCY_EXPONENTS[currency];
