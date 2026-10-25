import { User } from "@bida/api-contract";
import { Context, Effect, Layer, Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

const OpenCode = Schema.Struct({
  id: Schema.String,
  codeHash: Schema.String,
});
const SessionRow = Schema.Struct({ id: Schema.String, userId: Schema.String });

/** SQL only: users, sign-in codes and sessions. Not scoped to a space. */
export class AuthRepository extends Context.Service<
  AuthRepository,
  {
    findUserByEmail(email: string): Effect.Effect<Option.Option<User>>;
    findUserById(id: string): Effect.Effect<Option.Option<User>>;
    /** `None` when somebody signed up with the address in the meantime. */
    insertUser(
      input: typeof User.insert.Type,
    ): Effect.Effect<Option.Option<User>>;

    /** The user behind an identity at a provider, e.g. a Google account. */
    findIdentity(
      provider: string,
      subject: string,
    ): Effect.Effect<Option.Option<string>>;
    insertIdentity(
      provider: string,
      subject: string,
      userId: string,
    ): Effect.Effect<void>;

    /** How many e-mails were sent to the address since `seconds` ago. */
    countCodesSince(email: string, seconds: number): Effect.Effect<number>;
    insertCode(input: {
      readonly id: string;
      readonly email: string;
      readonly tokenHash: string;
      readonly codeHash: string;
      readonly ttlSeconds: number;
    }): Effect.Effect<void>;
    /** The newest code of the address that is neither used nor expired. */
    latestOpenCode(
      email: string,
    ): Effect.Effect<Option.Option<typeof OpenCode.Type>>;
    /** Counts a try and returns how many there were, this one included. */
    countAttempt(id: string): Effect.Effect<number>;
    /** Marks the code used; `false` when it already was or has expired. */
    consumeCode(id: string): Effect.Effect<boolean>;
    /** Marks the link used and returns its address; `None` if not valid. */
    consumeToken(tokenHash: string): Effect.Effect<Option.Option<string>>;

    insertSession(input: {
      readonly id: string;
      readonly userId: string;
      readonly tokenHash: string;
      readonly userAgent: string | null;
      readonly ttlSeconds: number;
    }): Effect.Effect<void>;
    findSession(
      tokenHash: string,
    ): Effect.Effect<Option.Option<typeof SessionRow.Type>>;
    /** Extends the session, at most once an hour. */
    touchSession(id: string, ttlSeconds: number): Effect.Effect<void>;
    deleteSession(id: string): Effect.Effect<void>;
  }
>()("bida/auth/AuthRepository") {
  static readonly layer = Layer.effect(
    AuthRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      const userColumns = sql`id, email, name, created_at`;

      const findUserByEmail = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: User,
        execute: (email) =>
          sql`SELECT ${userColumns} FROM users WHERE email = ${email}`,
      });
      const findUserById = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: User,
        execute: (id) => sql`SELECT ${userColumns} FROM users WHERE id = ${id}`,
      });
      const insertUser = SqlSchema.findOneOption({
        Request: User.insert,
        Result: User,
        execute: (request) =>
          sql`INSERT INTO users ${sql.insert(request)}
            ON CONFLICT (email) DO NOTHING RETURNING ${userColumns}`,
      });
      const latestOpenCode = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: OpenCode,
        execute: (email) =>
          sql`SELECT id, code_hash FROM login_codes
            WHERE email = ${email} AND used_at IS NULL AND expires_at > now()
            ORDER BY created_at DESC LIMIT 1`,
      });
      const findSession = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: SessionRow,
        execute: (tokenHash) =>
          sql`SELECT id, user_id FROM sessions
            WHERE token_hash = ${tokenHash} AND expires_at > now()`,
      });

      const rows = <A>(effect: Effect.Effect<A, unknown>) =>
        effect.pipe(Effect.orDie);

      return AuthRepository.of({
        findUserByEmail: (email) => findUserByEmail(email).pipe(Effect.orDie),
        findUserById: (id) => findUserById(id).pipe(Effect.orDie),
        insertUser: (input) => insertUser(input).pipe(Effect.orDie),

        findIdentity: (provider, subject) =>
          rows(
            sql<{ userId: string }>`SELECT user_id FROM identities
              WHERE provider = ${provider} AND subject = ${subject}`,
          ).pipe(
            Effect.map((result) => Option.fromNullishOr(result[0]?.userId)),
          ),
        insertIdentity: (provider, subject, userId) =>
          rows(
            sql`INSERT INTO identities (provider, subject, user_id)
              VALUES (${provider}, ${subject}, ${userId})
              ON CONFLICT DO NOTHING`,
          ).pipe(Effect.asVoid),

        countCodesSince: (email, seconds) =>
          rows(
            sql<{
              total: number;
            }>`SELECT count(*)::int AS total FROM login_codes
              WHERE email = ${email}
                AND created_at > now() - make_interval(secs => ${seconds})`,
          ).pipe(Effect.map((result) => result[0]?.total ?? 0)),
        insertCode: ({ id, email, tokenHash, codeHash, ttlSeconds }) =>
          rows(
            sql`INSERT INTO login_codes (id, email, token_hash, code_hash, expires_at)
              VALUES (${id}, ${email}, ${tokenHash}, ${codeHash},
                now() + make_interval(secs => ${ttlSeconds}))`,
          ).pipe(Effect.asVoid),
        latestOpenCode: (email) => latestOpenCode(email).pipe(Effect.orDie),
        countAttempt: (id) =>
          rows(
            sql<{
              attempts: number;
            }>`UPDATE login_codes SET attempts = attempts + 1
              WHERE id = ${id} RETURNING attempts`,
          ).pipe(
            Effect.map(
              (result) => result[0]?.attempts ?? Number.MAX_SAFE_INTEGER,
            ),
          ),
        consumeCode: (id) =>
          rows(
            sql`UPDATE login_codes SET used_at = now()
              WHERE id = ${id} AND used_at IS NULL AND expires_at > now()
              RETURNING id`,
          ).pipe(Effect.map((result) => result.length === 1)),
        consumeToken: (tokenHash) =>
          rows(
            sql<{ email: string }>`UPDATE login_codes SET used_at = now()
              WHERE token_hash = ${tokenHash} AND used_at IS NULL
                AND expires_at > now()
              RETURNING email`,
          ).pipe(
            Effect.map((result) => Option.fromNullishOr(result[0]?.email)),
          ),

        insertSession: ({ id, userId, tokenHash, userAgent, ttlSeconds }) =>
          rows(
            sql`INSERT INTO sessions (id, user_id, token_hash, user_agent, expires_at)
              VALUES (${id}, ${userId}, ${tokenHash}, ${userAgent},
                now() + make_interval(secs => ${ttlSeconds}))`,
          ).pipe(Effect.asVoid),
        findSession: (tokenHash) => findSession(tokenHash).pipe(Effect.orDie),
        touchSession: (id, ttlSeconds) =>
          rows(
            sql`UPDATE sessions
              SET last_used_at = now(),
                  expires_at = now() + make_interval(secs => ${ttlSeconds})
              WHERE id = ${id} AND last_used_at < now() - interval '1 hour'`,
          ).pipe(Effect.asVoid),
        deleteSession: (id) =>
          rows(sql`DELETE FROM sessions WHERE id = ${id}`).pipe(Effect.asVoid),
      });
    }),
  );
}
