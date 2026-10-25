import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { UserId } from "../auth/user.model.ts";
import { wire } from "../errors.ts";
import { Member, MySpace, SaveSpace, SetRole, SpaceId } from "./space.model.ts";
import { SpaceContext } from "./space-context.ts";
import {
  Forbidden,
  LastOwner,
  LimitReached,
  MemberNotFound,
  PersonalSpace,
  SpaceNotEmpty,
  SpaceNotFound,
} from "./spaces.errors.ts";

export class SpacesApi extends HttpApiGroup.make("spaces")
  .add(
    HttpApiEndpoint.get("list", "/spaces", {
      success: Schema.Array(MySpace),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List my spaces",
        description:
          "The personal space first, then the shared ones in the order the user joined them.",
      }),
    ),
    HttpApiEndpoint.post("create", "/spaces", {
      payload: SaveSpace,
      success: MySpace.pipe(HttpApiSchema.status(201)),
      error: wire(LimitReached),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Create a shared space",
        description: "The user becomes its owner.",
      }),
    ),
    HttpApiEndpoint.get("current", "/spaces/current", {
      success: MySpace,
      error: wire(SpaceNotFound),
    })
      .middleware(SpaceContext)
      .annotateMerge(
        OpenApi.annotations({
          summary: "Get the space of this request",
          description:
            "Chosen by the `X-Space-Id` header, the user's personal space when it is missing.",
        }),
      ),
    HttpApiEndpoint.put("update", "/spaces/:id", {
      params: { id: SpaceId },
      payload: SaveSpace,
      success: MySpace,
      error: [wire(SpaceNotFound), wire(Forbidden)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Edit a space",
        description:
          "Owners only. The default currency only applies to what is created afterwards.",
      }),
    ),
    HttpApiEndpoint.delete("delete", "/spaces/:id", {
      params: { id: SpaceId },
      error: [
        wire(SpaceNotFound),
        wire(Forbidden),
        wire(PersonalSpace),
        wire(SpaceNotEmpty),
      ],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete a shared space with all its data",
        description:
          "Owners only, and only when nobody else is a member: remove the others first.",
      }),
    ),
    HttpApiEndpoint.get("members", "/spaces/:id/members", {
      params: { id: SpaceId },
      success: Schema.Array(Member),
      error: wire(SpaceNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "List the members" })),
    HttpApiEndpoint.put("setRole", "/spaces/:id/members/:userId", {
      params: { id: SpaceId, userId: UserId },
      payload: SetRole,
      success: Member,
      error: [
        wire(SpaceNotFound),
        wire(Forbidden),
        wire(MemberNotFound),
        wire(LastOwner),
        wire(PersonalSpace),
      ],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Change the role of a member",
        description: "Owners only. A space keeps at least one owner.",
      }),
    ),
    HttpApiEndpoint.delete("removeMember", "/spaces/:id/members/:userId", {
      params: { id: SpaceId, userId: UserId },
      error: [
        wire(SpaceNotFound),
        wire(Forbidden),
        wire(MemberNotFound),
        wire(LastOwner),
        wire(PersonalSpace),
      ],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Remove a member",
        description:
          "Owners only. What the member added stays, marked as by a former member.",
      }),
    ),
    HttpApiEndpoint.post("leave", "/spaces/:id/leave", {
      params: { id: SpaceId },
      error: [wire(SpaceNotFound), wire(LastOwner), wire(PersonalSpace)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Leave a shared space",
        description: "The last owner has to hand over the role first.",
      }),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Spaces" })) {}
