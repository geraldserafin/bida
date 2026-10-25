import { HttpApi, OpenApi } from "effect/http-api";
import { AuthApi } from "./auth/index.ts";
import { AllocationsApi, EnvelopesApi } from "./envelopes/index.ts";
import { ExpensesApi } from "./expenses/index.ts";
import { IncomesApi } from "./incomes/index.ts";
import { OverviewApi } from "./overview/index.ts";
import { RecurringApi } from "./recurring/index.ts";
import { InvitationsApi, MembersApi } from "./sharing/index.ts";
import { SystemApi } from "./system/index.ts";
import { TransferApi } from "./transfer/index.ts";

export class Api extends HttpApi.make("bida")
  .add(SystemApi)
  .add(AuthApi)
  .add(EnvelopesApi)
  .add(AllocationsApi)
  .add(MembersApi)
  .add(InvitationsApi)
  .add(IncomesApi)
  .add(ExpensesApi)
  .add(RecurringApi)
  .add(OverviewApi)
  .add(TransferApi)
  .annotateMerge(
    OpenApi.annotations({
      title: "Money Planner API",
      description:
        "Everything except `/health` and `/auth` needs a signed-in user: send the session token as `Authorization: Bearer`, or let the browser send the session cookie. Amounts are integers in grosze (12.34 PLN is 1234).",
      version: "0.0.0",
    }),
  ) {}
