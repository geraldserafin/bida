import { HttpApi, OpenApi } from "effect/http-api";
import { BudgetsApi } from "./budgets/index.ts";
import { CategoriesApi } from "./categories/index.ts";
import { ExpensesApi } from "./expenses/index.ts";
import { RecurringApi } from "./recurring/index.ts";
import { SpacesApi } from "./spaces/index.ts";
import { SystemApi } from "./system/index.ts";
import { TransferApi } from "./transfer/index.ts";

export class Api extends HttpApi.make("bida")
  .add(SystemApi)
  .add(SpacesApi)
  .add(CategoriesApi)
  .add(BudgetsApi)
  .add(ExpensesApi)
  .add(RecurringApi)
  .add(TransferApi)
  .annotateMerge(
    OpenApi.annotations({
      title: "Money Planner API",
      description:
        "Everything except `/health` and the space list works inside a space. Pick it with the `X-Space-Id` header; without the header the default space is used. Amounts are integers in the minor unit of their currency (12.34 PLN is 1234).",
      version: "0.0.0",
    }),
  ) {}
