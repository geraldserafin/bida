import { Context, Effect, Layer } from "effect";
import { createTransport } from "nodemailer";
import { AppConfig } from "./config.ts";

export interface Mail {
  readonly to: string;
  readonly subject: string;
  readonly text: string;
}

/** Sends e-mail. A failure is a defect: nothing the caller could do about it. */
export class Mailer extends Context.Service<
  Mailer,
  { send(mail: Mail): Effect.Effect<void> }
>()("bida/platform/Mailer") {
  /** Writes the e-mail to the log. Development only: it logs the codes. */
  static readonly layerLog = Layer.succeed(
    Mailer,
    Mailer.of({
      send: (mail) =>
        Effect.logInfo(`mail to ${mail.to}: ${mail.subject}\n${mail.text}`),
    }),
  );

  static readonly layerSmtp = (url: string, from: string) =>
    Layer.sync(Mailer, () => {
      const transport = createTransport(url);
      return Mailer.of({
        send: (mail) =>
          Effect.tryPromise(() => transport.sendMail({ from, ...mail })).pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
      });
    });

  /** SMTP when `SMTP_URL` is set, the log otherwise. */
  static readonly layer = Layer.unwrap(
    AppConfig.pipe(
      Effect.map(({ smtpUrl, mailFrom }) =>
        smtpUrl === "" ? Mailer.layerLog : Mailer.layerSmtp(smtpUrl, mailFrom),
      ),
    ),
  );
}
