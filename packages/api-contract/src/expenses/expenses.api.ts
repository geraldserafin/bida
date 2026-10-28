import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { EnvelopeId, EnvelopeNotFound, Forbidden } from "../envelopes/index.ts";
import { wire } from "../errors.ts";
import {
  CreateExpense,
  ExpenseId,
  ExpenseJson,
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
      error: [wire(ExpenseNotFound), wire(EnvelopeNotFound), wire(Forbidden)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Edit an expense",
        description:
          "Its author and the owner of the envelope can. The new envelope has to be one the user can see.",
      }),
    ),
    HttpApiEndpoint.delete("delete", "/expenses/:id", {
      params: { id: ExpenseId },
      error: [wire(ExpenseNotFound), wire(Forbidden)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete an expense",
        description: "Its author and the owner of the envelope can.",
      }),
    ),
    HttpApiEndpoint.get("list", "/expenses", {
      query: {
        /** For a top-level envelope this includes its sub-envelopes. */
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
      error: wire(EnvelopeNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List expenses",
        description:
          "Of the envelopes the user can see, newest first. Defaults to 50 rows, at most 200.",
      }),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Expenses" })) {}
