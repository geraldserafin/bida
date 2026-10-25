import { Schema } from "effect";
import { HttpApiEndpoint, HttpApiGroup, OpenApi } from "effect/http-api";
import { SaveSpace, SpaceId, SpaceJson } from "./space.model.ts";
import { SpaceContext } from "./space-context.ts";
import { SpaceNotFound } from "./spaces.errors.ts";

export class SpacesApi extends HttpApiGroup.make("spaces")
  .add(
    HttpApiEndpoint.get("list", "/spaces", {
      success: Schema.Array(SpaceJson),
    }).annotateMerge(OpenApi.annotations({ summary: "List spaces" })),
    HttpApiEndpoint.post("create", "/spaces", {
      payload: SaveSpace,
      success: SpaceJson,
    }).annotateMerge(OpenApi.annotations({ summary: "Create a space" })),
    HttpApiEndpoint.get("current", "/spaces/current", {
      success: SpaceJson,
      error: SpaceNotFound,
    })
      .middleware(SpaceContext)
      .annotateMerge(
        OpenApi.annotations({
          summary: "Get the space of this request",
          description:
            "Chosen by the `X-Space-Id` header, the default space when it is missing.",
        }),
      ),
    HttpApiEndpoint.put("update", "/spaces/:id", {
      params: { id: SpaceId },
      payload: SaveSpace,
      success: SpaceJson,
      error: SpaceNotFound,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Edit a space",
        description:
          "The default currency only applies to what is created afterwards.",
      }),
    ),
  )
  .annotateMerge(OpenApi.annotations({ title: "Spaces" })) {}
