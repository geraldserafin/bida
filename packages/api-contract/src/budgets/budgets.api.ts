import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { CategoryNotFound } from "../categories/index.ts";
import { wire } from "../errors.ts";
import { SpaceContext } from "../spaces/space-context.ts";
import {
  EnvelopeAlreadyExists,
  InvalidPeriodRange,
  NoPeriods,
  PeriodNotFound,
} from "./budgets.errors.ts";
import {
  CreatePeriod,
  EnvelopeJson,
  EnvelopePlan,
  PeriodDetail,
  PeriodId,
  PeriodJson,
  SetPlan,
  UpdatePeriod,
} from "./budgets.model.ts";

export class PeriodsApi extends HttpApiGroup.make("periods")
  .add(
    HttpApiEndpoint.get("list", "/", {
      success: Schema.Array(PeriodJson),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List periods",
        description: "Newest first.",
      }),
    ),
    HttpApiEndpoint.get("current", "/current", {
      success: PeriodDetail,
      error: wire(NoPeriods),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Get the current period",
        description: "The period with the latest start date.",
      }),
    ),
    HttpApiEndpoint.post("create", "/", {
      payload: CreatePeriod,
      success: PeriodDetail.pipe(HttpApiSchema.status(201)),
      error: [wire(InvalidPeriodRange), wire(CategoryNotFound)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Create a period",
        description: "Creates the period together with its initial envelopes.",
      }),
    ),
    HttpApiEndpoint.get("get", "/:id", {
      params: { id: PeriodId },
      success: PeriodDetail,
      error: wire(PeriodNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Get a period" })),
    HttpApiEndpoint.put("update", "/:id", {
      params: { id: PeriodId },
      payload: UpdatePeriod,
      success: PeriodDetail,
      error: [wire(PeriodNotFound), wire(InvalidPeriodRange)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Edit a period",
        description:
          "Changes the name and dates. Use the plan endpoint for money.",
      }),
    ),
    HttpApiEndpoint.put("setPlan", "/:id/plan", {
      params: { id: PeriodId },
      payload: SetPlan,
      success: PeriodDetail,
      error: [wire(PeriodNotFound), wire(CategoryNotFound)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Set income and envelope amounts",
        description:
          "A zero amount removes the envelope, or keeps it at zero when it already has expenses.",
      }),
    ),
    HttpApiEndpoint.post("addEnvelope", "/:id/envelopes", {
      params: { id: PeriodId },
      payload: EnvelopePlan,
      success: EnvelopeJson.pipe(HttpApiSchema.status(201)),
      error: [
        wire(PeriodNotFound),
        wire(CategoryNotFound),
        wire(EnvelopeAlreadyExists),
      ],
    }).annotateMerge(
      OpenApi.annotations({ summary: "Add an envelope to a period" }),
    ),
    HttpApiEndpoint.delete("delete", "/:id", {
      params: { id: PeriodId },
      error: wire(PeriodNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete a period",
        description: "Also deletes its envelopes.",
      }),
    ),
  )
  .prefix("/periods")
  .middleware(SpaceContext)
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Periods" })) {}
