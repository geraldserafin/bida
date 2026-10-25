import { NodeServices } from "@effect/platform-node";
import { PgClient, PgMigrator } from "@effect/sql-pg";
import { Config, Layer, String as Str } from "effect";

const PgLive = PgClient.layerConfig({
  url: Config.Redacted("DATABASE_URL"),
  // TypeScript camelCase <-> SQL snake_case
  transformQueryNames: Config.succeed(Str.camelToSnake),
  transformResultNames: Config.succeed(Str.snakeToCamel),
});

const MigratorLive = PgMigrator.layer({
  loader: PgMigrator.fromFileSystem(`${import.meta.dirname}/migrations`),
}).pipe(Layer.provide(NodeServices.layer));

/**
 * `SqlClient` against a fully migrated database. The only place in the app
 * that knows which database driver is in use.
 */
export const DbLive = MigratorLive.pipe(Layer.provideMerge(PgLive));
