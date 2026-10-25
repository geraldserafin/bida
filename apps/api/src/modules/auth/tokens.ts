import {
  createHash,
  randomBytes,
  randomInt,
  timingSafeEqual,
} from "node:crypto";

/** A secret for a link or a session: 256 random bits, safe in a URL. */
export const newSecret = () => randomBytes(32).toString("base64url");

/** Six digits to type in; leading zeros stay. */
export const newCode = () => String(randomInt(0, 1_000_000)).padStart(6, "0");

/** Secrets are stored only as this hash, so a leaked table cannot be used. */
export const sha256 = (text: string) =>
  createHash("sha256").update(text).digest("hex");

export const sameHash = (a: string, b: string) =>
  a.length === b.length && timingSafeEqual(Buffer.from(a), Buffer.from(b));
