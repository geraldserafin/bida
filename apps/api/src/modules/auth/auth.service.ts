import {
  type CurrentUser,
  InvalidLogin,
  TooManyRequests,
  Unauthorized,
  User,
} from "@bida/api-contract";
import { Context, Effect, Layer, Option } from "effect";
import { SqlClient } from "effect/sql";
import { AppConfig } from "../../platform/config.ts";
import { Mailer } from "../../platform/mailer.ts";
import { SpacesService } from "../spaces/spaces.module.ts";
import { AuthRepository } from "./auth.repository.ts";
import { type GoogleProfile, GoogleVerifier } from "./google.ts";
import { newCode, newSecret, sameHash, sha256 } from "./tokens.ts";

const LINK_TTL_SECONDS = 15 * 60;
const MAX_TRIES = 5;
const MAX_LINKS_PER_HOUR = 5;
/** A session lasts this long since it was last used. */
export const SESSION_TTL_SECONDS = 30 * 24 * 60 * 60;

const normalize = (email: string) => email.trim().toLowerCase();

/** What a successful sign-in gives back. */
export interface SignedIn {
  readonly user: User;
  /** The secret to put in `Authorization: Bearer` or in the cookie. */
  readonly token: string;
}

/** Business rules of signing in with an e-mailed link or code. */
export class AuthService extends Context.Service<
  AuthService,
  {
    /** E-mails a link and a code. Does not say whether the address is known. */
    requestLink(email: string): Effect.Effect<void, TooManyRequests>;
    verifyCode(
      email: string,
      code: string,
      userAgent: string | null,
    ): Effect.Effect<SignedIn, InvalidLogin>;
    verifyToken(
      token: string,
      userAgent: string | null,
    ): Effect.Effect<SignedIn, InvalidLogin>;
    /** Signs in with the ID token an app got from Google sign-in. */
    signInWithGoogle(
      idToken: string,
      userAgent: string | null,
    ): Effect.Effect<SignedIn, InvalidLogin>;
    /** Signs in with the access token a browser got from Google. */
    signInWithGoogleAccessToken(
      accessToken: string,
      userAgent: string | null,
    ): Effect.Effect<SignedIn, InvalidLogin>;
    /** The user and session behind a session token. */
    authenticate(
      token: string,
    ): Effect.Effect<CurrentUser["Service"], Unauthorized>;
    logout(sessionId: string): Effect.Effect<void>;
  }
>()("bida/auth/AuthService") {
  static readonly layer = Layer.effect(
    AuthService,
    Effect.gen(function* () {
      const repo = yield* AuthRepository;
      const spaces = yield* SpacesService;
      const mailer = yield* Mailer;
      const google = yield* GoogleVerifier;
      const sql = yield* SqlClient.SqlClient;
      const { appUrl, claimEmail } = yield* AppConfig;
      const claim = normalize(claimEmail);

      const requestLink = Effect.fn("AuthService.requestLink")(function* (
        rawEmail: string,
      ) {
        const email = normalize(rawEmail);
        if ((yield* repo.countCodesSince(email, 3600)) >= MAX_LINKS_PER_HOUR)
          return yield* new TooManyRequests();
        const id = crypto.randomUUID();
        const token = newSecret();
        const code = newCode();
        yield* repo.insertCode({
          id,
          email,
          tokenHash: sha256(token),
          codeHash: sha256(`${id}:${code}`),
          ttlSeconds: LINK_TTL_SECONDS,
        });
        const link = `${appUrl.replace(/\/$/, "")}/?login_token=${token}`;
        yield* mailer.send({
          to: email,
          subject: "Logowanie do PLNing",
          text: `Twój kod logowania: ${code}\n\nAlbo otwórz link:\n${link}\n\nKod i link są ważne 15 minut i działają raz. Jeśli to nie Ty, zignoruj tę wiadomość.`,
        });
      });

      /** The account of the address, created with its first space on first use. */
      const userFor = Effect.fn("AuthService.userFor")(function* (
        email: string,
        name: string | null = null,
      ) {
        const known = yield* repo.findUserByEmail(email);
        if (Option.isSome(known)) return known.value;
        const row = yield* User.insert
          .makeEffect({ email, name })
          .pipe(Effect.orDie);
        const inserted = yield* repo.insertUser(row);
        // lost a race with another sign-in of the same address
        if (Option.isNone(inserted)) {
          return yield* Effect.orDie(repo.findUserByEmail(email)).pipe(
            Effect.flatMap(
              Option.match({
                onNone: () => Effect.die("user vanished"),
                onSome: Effect.succeed,
              }),
            ),
          );
        }
        const user = inserted.value;
        const claimed =
          email === claim ? yield* spaces.claimDefault(user.id) : Option.none();
        if (Option.isNone(claimed)) {
          yield* spaces.createFor(user.id, {
            name: "Mój budżet",
            defaultCurrency: "PLN",
          });
        }
        return user;
      });

      /** Starts a session for the user, found or created by [findUser]. */
      const signIn = Effect.fn("AuthService.signIn")(function* (
        findUser: Effect.Effect<User>,
        userAgent: string | null,
      ) {
        const user = yield* sql.withTransaction(findUser).pipe(Effect.orDie);
        const token = newSecret();
        yield* repo.insertSession({
          id: crypto.randomUUID(),
          userId: user.id,
          tokenHash: sha256(token),
          userAgent: userAgent?.slice(0, 300) ?? null,
          ttlSeconds: SESSION_TTL_SECONDS,
        });
        return { user, token } satisfies SignedIn;
      });

      const verifyCode = Effect.fn("AuthService.verifyCode")(function* (
        rawEmail: string,
        code: string,
        userAgent: string | null,
      ) {
        const email = normalize(rawEmail);
        const open = yield* repo.latestOpenCode(email);
        if (Option.isNone(open)) return yield* new InvalidLogin();
        // every try counts, right or wrong, so a code cannot be guessed
        if ((yield* repo.countAttempt(open.value.id)) > MAX_TRIES)
          return yield* new InvalidLogin();
        const expected = open.value.codeHash;
        if (!sameHash(expected, sha256(`${open.value.id}:${code}`)))
          return yield* new InvalidLogin();
        if (!(yield* repo.consumeCode(open.value.id)))
          return yield* new InvalidLogin();
        return yield* signIn(userFor(email), userAgent);
      });

      const verifyToken = Effect.fn("AuthService.verifyToken")(function* (
        token: string,
        userAgent: string | null,
      ) {
        const email = yield* repo.consumeToken(sha256(token));
        if (Option.isNone(email)) return yield* new InvalidLogin();
        return yield* signIn(userFor(email.value), userAgent);
      });

      /**
       * The account of a Google identity. The first time, an account with the
       * same address (Google verified it) is the same person; failing that a
       * new one is created.
       */
      const userForGoogle = Effect.fn("AuthService.userForGoogle")(function* (
        profile: GoogleProfile,
      ) {
        const known = yield* repo.findIdentity("google", profile.subject);
        if (Option.isSome(known)) {
          const user = yield* repo.findUserById(known.value);
          if (Option.isSome(user)) return user.value;
        }
        const user = yield* userFor(normalize(profile.email), profile.name);
        yield* repo.insertIdentity("google", profile.subject, user.id);
        return user;
      });

      const signInWithGoogle = Effect.fn("AuthService.signInWithGoogle")(
        function* (idToken: string, userAgent: string | null) {
          const profile = yield* google.verify(idToken);
          return yield* signIn(userForGoogle(profile), userAgent);
        },
      );

      const authenticate = Effect.fn("AuthService.authenticate")(function* (
        token: string,
      ) {
        if (token === "" || token.length > 200)
          return yield* new Unauthorized();
        const session = yield* repo.findSession(sha256(token));
        if (Option.isNone(session)) return yield* new Unauthorized();
        const user = yield* repo.findUserById(session.value.userId);
        if (Option.isNone(user)) return yield* new Unauthorized();
        yield* repo.touchSession(session.value.id, SESSION_TTL_SECONDS);
        return { user: user.value, sessionId: session.value.id };
      });

      const signInWithGoogleAccessToken = Effect.fn(
        "AuthService.signInWithGoogleAccessToken",
      )(function* (accessToken: string, userAgent: string | null) {
        const profile = yield* google.verifyAccessToken(accessToken);
        return yield* signIn(userForGoogle(profile), userAgent);
      });

      return AuthService.of({
        requestLink,
        verifyCode,
        verifyToken,
        signInWithGoogle,
        signInWithGoogleAccessToken,
        authenticate,
        logout: repo.deleteSession,
      });
    }),
  );
}
