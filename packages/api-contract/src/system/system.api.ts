import { Schema } from "effect";
import { HttpApiEndpoint, HttpApiGroup, OpenApi } from "effect/http-api";

export const Health = Schema.Struct({
  status: Schema.Literal("ok"),
  uptimeSeconds: Schema.Number,
});

export class SystemApi extends HttpApiGroup.make("system")
  .add(
    HttpApiEndpoint.get("health", "/health", {
      success: Health,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Health check",
        description: "Returns ok while the server is running.",
      }),
    ),
  )
  .annotateMerge(OpenApi.annotations({ title: "System" })) {}
