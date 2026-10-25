import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { PeriodId, PeriodNotFound } from "../budgets/index.ts";
import { wire } from "../errors.ts";
import { SpaceContext } from "../spaces/space-context.ts";
import { Forbidden } from "../spaces/spaces.errors.ts";
import {
  AddContribution,
  ContributionId,
  ContributionJson,
} from "./contribution.model.ts";
import { ContributionNotFound } from "./contributions.errors.ts";

export class ContributionsApi extends HttpApiGroup.make("contributions")
  .add(
    HttpApiEndpoint.get("list", "/periods/:id/contributions", {
      params: { id: PeriodId },
      success: Schema.Array(ContributionJson),
      error: wire(PeriodNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List what was paid into a period",
        description: "Newest first.",
      }),
    ),
    HttpApiEndpoint.post("add", "/periods/:id/contributions", {
      params: { id: PeriodId },
      payload: AddContribution,
      success: ContributionJson.pipe(HttpApiSchema.status(201)),
      error: wire(PeriodNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Record money paid into a period",
        description:
          "In the name of the signed-in user, or of nobody with `external`. The planned income of the period is a separate number.",
      }),
    ),
    HttpApiEndpoint.delete("delete", "/contributions/:id", {
      params: { id: ContributionId },
      error: [wire(ContributionNotFound), wire(Forbidden)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete a contribution",
        description:
          "Whoever recorded it, or an owner of the space. Money from outside has no author, so only an owner deletes it.",
      }),
    ),
  )
  .middleware(SpaceContext)
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Contributions" })) {}
