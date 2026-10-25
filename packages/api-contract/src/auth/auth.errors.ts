import { Schema } from "effect";

/** No valid session: missing, unknown, expired or ended. */
export class Unauthorized extends Schema.TaggedError<Unauthorized>()(
  "Unauthorized",
  {},
  { httpApiStatus: 401 },
) {}

/** The code or link is wrong, used, expired, or tried too many times. */
export class InvalidLogin extends Schema.TaggedError<InvalidLogin>()(
  "InvalidLogin",
  {},
  { httpApiStatus: 401 },
) {}

/** Too many sign-in e-mails asked for one address. */
export class TooManyRequests extends Schema.TaggedError<TooManyRequests>()(
  "TooManyRequests",
  {},
  { httpApiStatus: 429 },
) {}
