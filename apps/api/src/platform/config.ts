import { Config } from "effect";

export const AppConfig = Config.all({
  port: Config.Port("PORT").pipe(Config.withDefault(3000)),
  // Origins of browser apps allowed to call the API, comma separated. Native
  // apps are not affected; empty (the default) allows no browser origin.
  corsOrigins: Config.String("CORS_ORIGINS").pipe(
    Config.withDefault(""),
    Config.map((list) =>
      list
        .split(",")
        .map((origin) => origin.trim())
        .filter((origin) => origin !== ""),
    ),
  ),
});
