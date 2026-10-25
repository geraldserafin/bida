import { HttpApi, OpenApi } from "effect/http-api";
import { BudgetsApi } from "./budgets/index.ts";
import { CategoriesApi } from "./categories/index.ts";
import { SystemApi } from "./system/index.ts";

export class Api extends HttpApi.make("bida")
  .add(SystemApi)
  .add(CategoriesApi)
  .add(BudgetsApi)
  .annotateMerge(
    OpenApi.annotations({
      title: "Money Planner API",
      version: "0.0.0",
    }),
  ) {}
