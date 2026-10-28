import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { wire } from "../errors.ts";
import { IsoDate } from "../text.ts";
import {
  IncomeId,
  IncomeJson,
  IncomeNotFound,
  SaveIncome,
} from "./income.model.ts";

export class IncomesApi extends HttpApiGroup.make("incomes")
  .add(
    HttpApiEndpoint.get("list", "/incomes", {
      query: {
        /** Inclusive lower bound of `receivedOn`. */
        from: Schema.optional(IsoDate),
        /** Inclusive upper bound of `receivedOn`. */
        to: Schema.optional(IsoDate),
      },
      success: Schema.Array(IncomeJson),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List the user's income",
        description: "Newest first.",
      }),
    ),
    HttpApiEndpoint.post("create", "/incomes", {
      payload: SaveIncome,
      success: IncomeJson.pipe(HttpApiSchema.status(201)),
    }).annotateMerge(OpenApi.annotations({ summary: "Add income" })),
    HttpApiEndpoint.put("update", "/incomes/:id", {
      params: { id: IncomeId },
      payload: SaveIncome,
      success: IncomeJson,
      error: wire(IncomeNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Edit income" })),
    HttpApiEndpoint.delete("delete", "/incomes/:id", {
      params: { id: IncomeId },
      error: wire(IncomeNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Delete income" })),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Incomes" })) {}
