import { Schema } from "effect";
import { HttpApiEndpoint, HttpApiGroup, OpenApi } from "effect/http-api";
import { CategoryNotFound } from "../categories/index.ts";
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
} from "./budgets.model.ts";

export class BudgetsApi extends HttpApiGroup.make("budgets")
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
      error: NoPeriods,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Get the current period",
        description: "The period with the latest start date.",
      }),
    ),
    HttpApiEndpoint.post("create", "/", {
      payload: CreatePeriod,
      success: PeriodDetail,
      error: [InvalidPeriodRange, CategoryNotFound],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Create a period",
        description: "Creates the period together with its initial envelopes.",
      }),
    ),
    HttpApiEndpoint.get("get", "/:id", {
      params: { id: PeriodId },
      success: PeriodDetail,
      error: PeriodNotFound,
    }).annotateMerge(OpenApi.annotations({ summary: "Get a period" })),
    HttpApiEndpoint.put("setPlan", "/:id/plan", {
      params: { id: PeriodId },
      payload: SetPlan,
      success: PeriodDetail,
      error: [PeriodNotFound, CategoryNotFound],
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
      success: EnvelopeJson,
      error: [PeriodNotFound, CategoryNotFound, EnvelopeAlreadyExists],
    }).annotateMerge(
      OpenApi.annotations({ summary: "Add an envelope to a period" }),
    ),
    HttpApiEndpoint.delete("delete", "/:id", {
      params: { id: PeriodId },
      error: PeriodNotFound,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete a period",
        description: "Also deletes its envelopes.",
      }),
    ),
  )
  .prefix("/periods")
  .annotateMerge(OpenApi.annotations({ title: "Budgets" })) {}
