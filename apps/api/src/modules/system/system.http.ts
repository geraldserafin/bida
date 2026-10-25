import { Api } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";

export const SystemHttp = HttpApiBuilder.group(
  Api,
  "system",
  Effect.fn(function* (handlers) {
    return handlers.handle("health", () =>
      Effect.succeed({
        status: "ok" as const,
        uptimeSeconds: Math.floor(process.uptime()),
      }),
    );
  }),
);
