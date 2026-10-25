import { Config } from "effect";

/** A comma separated list; empty or missing means no entries. */
const list = (name: string) =>
  Config.String(name).pipe(
    Config.withDefault(""),
    Config.map((text) =>
      text
        .split(",")
        .map((item) => item.trim())
        .filter((item) => item !== ""),
    ),
  );

export const AppConfig = Config.all({
  port: Config.Port("PORT").pipe(Config.withDefault(3000)),
  // Origins of browser apps allowed to call the API. Native apps are not
  // affected; empty (the default) allows no browser origin.
  corsOrigins: list("CORS_ORIGINS"),
  // Where the browser app lives; the sign-in e-mail links there.
  appUrl: Config.String("APP_URL").pipe(
    Config.withDefault("http://localhost:8080"),
  ),
  // The session cookie is only sent over HTTPS; turn off for local http.
  cookieSecure: Config.Boolean("COOKIE_SECURE").pipe(Config.withDefault(true)),
  // Sending mail. Without SMTP_URL (e.g. smtps://user:pass@host:465) the
  // e-mails are only written to the log, which is for development.
  smtpUrl: Config.String("SMTP_URL").pipe(Config.withDefault("")),
  mailFrom: Config.String("MAIL_FROM").pipe(
    Config.withDefault("PLNing <no-reply@localhost>"),
  ),
  // The first person to sign in with this address takes over the data that
  // exists before accounts did (the default space).
  claimEmail: Config.String("CLAIM_EMAIL").pipe(Config.withDefault("")),
  // OAuth client ids of the Google apps allowed to sign users in (the web
  // client, and the Android and iOS ones). Empty turns Google sign-in off.
  googleClientIds: list("GOOGLE_CLIENT_IDS"),
});
