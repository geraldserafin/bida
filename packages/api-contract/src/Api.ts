import { HttpApi, OpenApi } from "effect/http-api";
import { AuthApi } from "./auth/index.ts";
import { PeriodsApi } from "./budgets/index.ts";
import { CategoriesApi } from "./categories/index.ts";
import { ExpensesApi } from "./expenses/index.ts";
import { InvitationsApi } from "./invitations/index.ts";
import { RecurringApi } from "./recurring/index.ts";
import { SpacesApi } from "./spaces/index.ts";
import { SystemApi } from "./system/index.ts";
import { TransferApi } from "./transfer/index.ts";

export class Api extends HttpApi.make("bida")
  .add(SystemApi)
  .add(AuthApi)
  .add(SpacesApi)
  .add(InvitationsApi)
  .add(CategoriesApi)
  .add(PeriodsApi)
  .add(ExpensesApi)
  .add(RecurringApi)
  .add(TransferApi)
  .annotateMerge(
    OpenApi.annotations({
      title: "Money Planner API",
      description:
        "Everything except `/health` and `/auth` needs a signed-in user: send the session token as `Authorization: Bearer`, or let the browser send the session cookie. Most endpoints work inside a space: pick it with the `X-Space-Id` header (a space the user belongs to); without the header it is the first space of the user. Amounts are integers in the minor unit of their currency (12.34 PLN is 1234).",
      version: "0.0.0",
    }),
  ) {}
