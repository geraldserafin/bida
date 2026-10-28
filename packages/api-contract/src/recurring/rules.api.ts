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
import {
  AllocationRuleId,
  AllocationRuleJson,
  AllocationRuleNotFound,
  RecurringIncomeId,
  RecurringIncomeJson,
  RecurringIncomeNotFound,
  SaveAllocationRule,
  SaveRecurringIncome,
} from "./rules.model.ts";

export class RecurringIncomesApi extends HttpApiGroup.make("recurringIncomes")
  .add(
    HttpApiEndpoint.get("list", "/recurring-incomes", {
      success: Schema.Array(RecurringIncomeJson),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List recurring incomes",
        description: "The user's own, newest first.",
      }),
    ),
    HttpApiEndpoint.post("create", "/recurring-incomes", {
      payload: SaveRecurringIncome,
      success: RecurringIncomeJson.pipe(HttpApiSchema.status(201)),
    }).annotateMerge(
      OpenApi.annotations({ summary: "Create a recurring income" }),
    ),
    HttpApiEndpoint.put("update", "/recurring-incomes/:id", {
      params: { id: RecurringIncomeId },
      payload: SaveRecurringIncome,
      success: RecurringIncomeJson,
      error: wire(RecurringIncomeNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Edit a recurring income",
        description: "Setting `active` to false pauses it.",
      }),
    ),
    HttpApiEndpoint.delete("delete", "/recurring-incomes/:id", {
      params: { id: RecurringIncomeId },
      error: wire(RecurringIncomeNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete a recurring income",
        description: "Income it already added is kept.",
      }),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Recurring incomes" })) {}

export class AllocationRulesApi extends HttpApiGroup.make("allocationRules")
  .add(
    HttpApiEndpoint.get("list", "/allocation-rules", {
      success: Schema.Array(AllocationRuleJson),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List allocation rules",
        description: "The user's own, newest first.",
      }),
    ),
    HttpApiEndpoint.post("create", "/allocation-rules", {
      payload: SaveAllocationRule,
      success: AllocationRuleJson.pipe(HttpApiSchema.status(201)),
      error: wire(EnvelopeNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Create an allocation rule",
        description:
          "Puts a sum into an envelope every month. For a sub-envelope the money comes out of what the user put into its parent.",
      }),
    ),
    HttpApiEndpoint.put("update", "/allocation-rules/:id", {
      params: { id: AllocationRuleId },
      payload: SaveAllocationRule,
      success: AllocationRuleJson,
      error: [wire(AllocationRuleNotFound), wire(EnvelopeNotFound)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Edit an allocation rule",
        description: "Setting `active` to false pauses it.",
      }),
    ),
    HttpApiEndpoint.delete("delete", "/allocation-rules/:id", {
      params: { id: AllocationRuleId },
      error: wire(AllocationRuleNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete an allocation rule",
        description: "Allocations it already made are kept.",
      }),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Allocation rules" })) {}
