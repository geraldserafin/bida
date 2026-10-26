import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { EnvelopeNotFound } from "../envelopes/index.ts";
import { wire } from "../errors.ts";
import { RecurringRuleNotFound } from "./recurring.errors.ts";
import {
  ApplyRecurring,
  ApplyResult,
  RecurringRuleId,
  RecurringRuleJson,
  SaveRecurringRule,
} from "./recurring.model.ts";

export class RecurringApi extends HttpApiGroup.make("recurring")
  .add(
    HttpApiEndpoint.get("list", "/recurring-rules", {
      success: Schema.Array(RecurringRuleJson),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List recurring rules",
        description: "The user's own, newest first.",
      }),
    ),
    HttpApiEndpoint.post("create", "/recurring-rules", {
      payload: SaveRecurringRule,
      success: RecurringRuleJson.pipe(HttpApiSchema.status(201)),
      error: wire(EnvelopeNotFound),
    }).annotateMerge(
      OpenApi.annotations({ summary: "Create a recurring rule" }),
    ),
    HttpApiEndpoint.put("update", "/recurring-rules/:id", {
      params: { id: RecurringRuleId },
      payload: SaveRecurringRule,
      success: RecurringRuleJson,
      error: [wire(RecurringRuleNotFound), wire(EnvelopeNotFound)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Edit a recurring rule",
        description: "Setting `active` to false pauses the rule.",
      }),
    ),
    HttpApiEndpoint.delete("delete", "/recurring-rules/:id", {
      params: { id: RecurringRuleId },
      error: wire(RecurringRuleNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete a recurring rule",
        description: "Expenses it already generated are kept.",
      }),
    ),
    HttpApiEndpoint.get("pending", "/recurring-rules/pending", {
      query: ApplyRecurring,
      success: ApplyResult,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "What applying would add",
        description:
          "Counts of the recurring incomes, allocation rules and expenses that have not been applied to the stretch yet. Changes nothing.",
      }),
    ),
    HttpApiEndpoint.post("apply", "/recurring-rules/apply", {
      payload: ApplyRecurring,
      success: ApplyResult,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Apply the recurring rules to a stretch of time",
        description:
          "Adds, for every active rule not applied for this `from` yet: the recurring incomes (dated on their day of the month), then the allocation rules (the same), then the expenses (dated today when today is in the stretch, else `from`). Safe to call repeatedly. An allocation the envelope cannot take is skipped and counted.",
      }),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Recurring" })) {}
