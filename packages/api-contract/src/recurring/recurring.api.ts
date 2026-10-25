import { Schema } from "effect";
import { HttpApiEndpoint, HttpApiGroup, OpenApi } from "effect/http-api";
import { EnvelopePlan, PeriodId, PeriodNotFound } from "../budgets/index.ts";
import { CategoryNotFound } from "../categories/index.ts";
import { Currency } from "../currency/index.ts";
import { SpaceContext } from "../spaces/space-context.ts";
import { RecurringRuleNotFound } from "./recurring.errors.ts";
import {
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
        description: "Newest first.",
      }),
    ),
    HttpApiEndpoint.post("create", "/recurring-rules", {
      payload: SaveRecurringRule,
      success: RecurringRuleJson,
      error: CategoryNotFound,
    }).annotateMerge(
      OpenApi.annotations({ summary: "Create a recurring rule" }),
    ),
    HttpApiEndpoint.put("update", "/recurring-rules/:id", {
      params: { id: RecurringRuleId },
      payload: SaveRecurringRule,
      success: RecurringRuleJson,
      error: [RecurringRuleNotFound, CategoryNotFound],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Edit a recurring rule",
        description: "Setting `active` to false pauses the rule.",
      }),
    ),
    HttpApiEndpoint.delete("delete", "/recurring-rules/:id", {
      params: { id: RecurringRuleId },
      error: RecurringRuleNotFound,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete a recurring rule",
        description: "Expenses it already generated are kept.",
      }),
    ),
    HttpApiEndpoint.get("suggestedPlan", "/recurring-rules/suggested-plan", {
      query: { currency: Schema.optional(Currency) },
      success: Schema.Array(EnvelopePlan),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Suggested envelope amounts",
        description:
          "Sum of the active rules in one currency per category, to prefill a new period's plan.",
      }),
    ),
    HttpApiEndpoint.post("apply", "/periods/:periodId/recurring/apply", {
      params: { periodId: PeriodId },
      success: ApplyResult,
      error: PeriodNotFound,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Apply recurring rules to a period",
        description:
          "Adds one expense for every active rule not applied in this period yet, creating a missing envelope with the rule's amount as its plan. Safe to call repeatedly.",
      }),
    ),
  )
  .middleware(SpaceContext)
  .annotateMerge(OpenApi.annotations({ title: "Recurring" })) {}
