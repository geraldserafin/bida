import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import {
  EnvelopeId,
  EnvelopeNotFound,
  PeriodId,
  PeriodNotFound,
} from "../budgets/index.ts";
import { CategoryId } from "../categories/index.ts";
import { wire } from "../errors.ts";
import { SpaceContext } from "../spaces/space-context.ts";
import {
  CreateExpense,
  ExpenseId,
  ExpenseJson,
  PeriodProgress,
  PeriodSummary,
  UpdateExpense,
} from "./expense.model.ts";
import { ExpenseNotFound } from "./expenses.errors.ts";

export class ExpensesApi extends HttpApiGroup.make("expenses")
  .add(
    HttpApiEndpoint.post("create", "/expenses", {
      payload: CreateExpense,
      success: ExpenseJson.pipe(HttpApiSchema.status(201)),
      error: wire(EnvelopeNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Add an expense" })),
    HttpApiEndpoint.get("get", "/expenses/:id", {
      params: { id: ExpenseId },
      success: ExpenseJson,
      error: wire(ExpenseNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Get an expense" })),
    HttpApiEndpoint.put("update", "/expenses/:id", {
      params: { id: ExpenseId },
      payload: UpdateExpense,
      success: ExpenseJson,
      error: [wire(ExpenseNotFound), wire(EnvelopeNotFound)],
    }).annotateMerge(OpenApi.annotations({ summary: "Edit an expense" })),
    HttpApiEndpoint.delete("delete", "/expenses/:id", {
      params: { id: ExpenseId },
      error: wire(ExpenseNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Delete an expense" })),
    HttpApiEndpoint.get("listForPeriod", "/periods/:periodId/expenses", {
      params: { periodId: PeriodId },
      query: {
        categoryId: Schema.optional(CategoryId),
        envelopeId: Schema.optional(EnvelopeId),
        /** Inclusive lower bound of `spentAt` (ISO timestamp). */
        from: Schema.optional(Schema.DateTimeUtcFromString),
        /** Exclusive upper bound of `spentAt` (ISO timestamp). */
        to: Schema.optional(Schema.DateTimeUtcFromString),
        limit: Schema.optional(
          Schema.NumberFromString.check(
            Schema.isInt(),
            Schema.isBetween({ minimum: 1, maximum: 200 }),
          ),
        ),
        offset: Schema.optional(
          Schema.NumberFromString.check(
            Schema.isInt(),
            Schema.isGreaterThanOrEqualTo(0),
          ),
        ),
      },
      success: Schema.Array(ExpenseJson),
      error: wire(PeriodNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List the expenses of a period",
        description: "Newest first. Defaults to 50 rows, at most 200.",
      }),
    ),
    HttpApiEndpoint.get("periodSummaries", "/periods/summaries", {
      success: Schema.Array(PeriodSummary),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Planned and spent for every period",
        description: "Newest first. One call instead of one per period.",
      }),
    ),
    HttpApiEndpoint.get("progress", "/periods/:periodId/progress", {
      params: { periodId: PeriodId },
      success: PeriodProgress,
      error: wire(PeriodNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Planned versus spent",
        description: "Totals for the period and for each envelope.",
      }),
    ),
  )
  .middleware(SpaceContext)
  .annotateMerge(OpenApi.annotations({ title: "Expenses" })) {}
